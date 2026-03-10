// lib/screens/brew_parameters_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/tasting_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../core/constants.dart';
import '../shared/primary_button.dart';

class BrewParametersScreen extends ConsumerStatefulWidget {
  const BrewParametersScreen({super.key});

  @override
  ConsumerState<BrewParametersScreen> createState() => _BrewParametersScreenState();
}

class _BrewParametersScreenState extends ConsumerState<BrewParametersScreen> {
  late TextEditingController _coffeeController;
  late TextEditingController _grinderSettingController;
  late TextEditingController _beanDetailsController;
  late TextEditingController _drawdownController; // Kontroler dla czasu parzenia

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(tastingProvider);
    _coffeeController = TextEditingController(text: initialState.coffeeName);
    _grinderSettingController = TextEditingController(text: initialState.grinderSetting);
    _beanDetailsController = TextEditingController(text: initialState.beanDetails);
    _drawdownController = TextEditingController(text: initialState.drawdownTime);
  }

  @override
  void dispose() {
    _coffeeController.dispose();
    _grinderSettingController.dispose();
    _beanDetailsController.dispose();
    _drawdownController.dispose();
    super.dispose();
  }

  Widget _buildAutocompleteField({
    required String label,
    required Iterable<String> options, 
    required String initialValue,
    required Function(String) onSelected,
    required Function(String) onChanged,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        return options.where((String option) => 
            option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        if (controller.text.isEmpty && initialValue.isNotEmpty) controller.text = initialValue;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
          onChanged: onChanged,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final optionsList = options.toList(); 
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: appSurface,
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 24,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: optionsList.length,
                itemBuilder: (context, index) {
                  final option = optionsList[index]; 
                  return ListTile(
                    dense: true,
                    title: Text(option, style: const TextStyle(color: appTextPrimary, fontSize: 13)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tastingData = ref.watch(tastingProvider);
    final notifier = ref.read(tastingProvider.notifier);
    final userPrefs = ref.watch(userPreferencesProvider);
    
    final asyncRoasteries = ref.watch(combinedRoasteriesProvider);
    final grindersAsync = ref.watch(grindersDatabaseProvider);

    final activeMethods = userPrefs.activeMethods.isNotEmpty ? userPrefs.activeMethods : ['V60'];
    final selectedMethod = activeMethods.contains(tastingData.method) ? tastingData.method : activeMethods.first;

    final activeGrinders = userPrefs.grinders.where((g) => g.trim().isNotEmpty).toList();
    final defaultGrinder = activeGrinders.isNotEmpty ? activeGrinders.first : '';
    
    final selectedGrinder = (tastingData.grinderName.isEmpty && defaultGrinder.isNotEmpty) 
        ? defaultGrinder 
        : tastingData.grinderName;

    if (tastingData.grinderName != selectedGrinder) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.updateGrinderName(selectedGrinder);
      });
    }

    final activeGrinderModel = grindersAsync.value?.where((g) => g.fullName == selectedGrinder).firstOrNull;
    final double activeMultiplier = activeGrinderModel?.stepMicron ?? 0.0;

    final history = ref.watch(historyProvider).value ?? [];
    String? lastSetting;
    
    ref.read(iconCacheProvider); 

    if (selectedGrinder.isNotEmpty) {
      try {
        final lastSession = history.firstWhere(
          (session) => session['grinderName'] == selectedGrinder && 
                       (session['grinderSetting']?.toString().trim().isNotEmpty ?? false)
        );
        lastSetting = lastSession['grinderSetting'].toString();
      } catch (_) {
        lastSetting = null; 
      }
    }

    final hintText = (lastSetting != null && lastSetting.isNotEmpty) 
        ? 'last: $lastSetting' 
        : 'e.g. 96';

    final dose = tastingData.dose;
    final water = tastingData.waterVolume;
    final ratio = dose > 0 ? (water / dose) : 0.0;
    final isOutlier = dose > 0 && water > 0 && (ratio < 12.0 || ratio > 20.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brew Parameters', style: TextStyle(fontSize: 18)), 
        centerTitle: true,
        toolbarHeight: 48,
      ),
      body: SafeArea(
        child: asyncRoasteries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (roasteries) {
            return SingleChildScrollView( 
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedMethod,
                                  dropdownColor: const Color(0xFF1E1A18), 
                                  iconSize: 28,
                                  decoration: const InputDecoration(labelText: 'Method', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12)),
                                  items: activeMethods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)))).toList(),
                                  onChanged: (val) { if (val != null) notifier.updateMethod(val); },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedGrinder,
                                  dropdownColor: const Color(0xFF1E1A18),
                                  iconSize: 28,
                                  decoration: const InputDecoration(labelText: 'Grinder', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12)),
                                  items: activeGrinders.map((g) => DropdownMenuItem(
                                    value: g, 
                                    child: Text(g.isEmpty ? 'None' : g, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))
                                  )).toList(),
                                  onChanged: (val) { if (val != null) notifier.updateGrinderName(val); },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildAutocompleteField(
                                  label: 'Roaster (Palarnia)', 
                                  options: roasteries, 
                                  initialValue: tastingData.coffeeName,
                                  onSelected: (val) => notifier.updateCoffeeName(val),
                                  onChanged: (val) => notifier.updateCoffeeName(val),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _grinderSettingController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Clicks/Setting',
                                    hintText: hintText,
                                    hintStyle: const TextStyle(color: Colors.white38, fontStyle: FontStyle.italic, fontSize: 11),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                    suffixIcon: activeMultiplier > 0 
                                      ? Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                tastingData.grinderSetting.isNotEmpty && int.tryParse(tastingData.grinderSetting) != null
                                                    ? '${(int.parse(tastingData.grinderSetting) * activeMultiplier).toInt()} µm'
                                                    : '0 µm',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                                              ),
                                              const Text('Gap', style: TextStyle(fontSize: 8, color: Colors.grey)),
                                            ],
                                          ),
                                        )
                                      : null,
                                  ),
                                  onChanged: (val) => notifier.updateGrinderSetting(val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _beanDetailsController,
                            decoration: const InputDecoration(
                              labelText: 'Bean & Origin (np. Ethiopia Yirgacheffe Washed)',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            ),
                            onChanged: (val) => notifier.updateBeanDetails(val),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SliderWithTextInput(
                            label: 'Temp', value: tastingData.temperature, min: 80, max: 100, divisions: 200, suffix: '°C', color: Colors.blue,
                            onChanged: (val) => notifier.updateTemperature(val),
                          ),
                          SliderWithTextInput(
                            label: 'Yield', value: tastingData.waterVolume, min: 50, max: 1000, divisions: 950, suffix: 'ml', color: Colors.lightBlueAccent,
                            onChanged: (val) => notifier.updateWaterVolume(val),
                          ),
                          SliderWithTextInput(
                            label: 'Dose', value: tastingData.dose, min: 5, max: 50, divisions: 450, suffix: 'g', color: Colors.green,
                            onChanged: (val) => notifier.updateDose(val),
                          ),
                          Text(
                            'Brew Ratio 1 : ${ratio.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isOutlier)
                    Container(
                      margin: const EdgeInsets.only(top: 8.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Non-standard ratio (1:${ratio.toStringAsFixed(1)}). Optimal: 1:12 - 1:20.',
                              style: const TextStyle(color: Colors.orange, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ==========================================
                  // ZAAWANSOWANE OPCJE PARZENIA
                  // ==========================================
                  Card(
                    margin: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                    child: ExpansionTile(
                      collapsedIconColor: Colors.amber,
                      iconColor: Colors.amber,
                      title: const Row(
                        children: [
                          Icon(Icons.science, size: 18, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('ADVANCED BREWING OPTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: tastingData.recipe.isEmpty ? 'Custom' : tastingData.recipe,
                                      dropdownColor: const Color(0xFF1E1A18),
                                      decoration: const InputDecoration(labelText: 'Recipe / Technique', isDense: true),
                                      items: ['Custom', 'James Hoffmann', 'Scott Rao', 'Tetsu Kasuya 4:6', 'Lance Hedrick', 'Osmotic Flow']
                                          .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13, color: Colors.white)))).toList(),
                                      onChanged: (val) { if (val != null) notifier.updateRecipe(val); },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: tastingData.filterType.isEmpty ? 'Paper (Bleached)' : tastingData.filterType,
                                      dropdownColor: const Color(0xFF1E1A18),
                                      decoration: const InputDecoration(labelText: 'Filter Type', isDense: true),
                                      items: ['Paper (Bleached)', 'Paper (Unbleached)', 'Metal', 'Cloth (Nel)', 'Polymer (Sibarist)']
                                          .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13, color: Colors.white)))).toList(),
                                      onChanged: (val) { if (val != null) notifier.updateFilterType(val); },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _drawdownController,
                                keyboardType: TextInputType.datetime,
                                decoration: InputDecoration(
                                  labelText: 'Total Drawdown Time',
                                  hintText: 'e.g. 02:45',
                                  hintStyle: const TextStyle(color: Colors.white24),
                                  prefixIcon: const Icon(Icons.timer_outlined, color: Colors.grey, size: 20),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (val) => notifier.updateDrawdownTime(val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  PrimaryActionButton(
                    label: 'NEXT: FRAGRANCE ANALYSIS',
                    onPressed: () => context.push('/fragrance'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// KOMPONENT HYBRYDOWY: Suwak zsynchronizowany z klawiaturą (Slider + TextField)
// ============================================================================
class SliderWithTextInput extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final Color color;
  final ValueChanged<double> onChanged;

  const SliderWithTextInput({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    required this.color,
    required this.onChanged,
  });

  @override
  State<SliderWithTextInput> createState() => _SliderWithTextInputState();
}

class _SliderWithTextInputState extends State<SliderWithTextInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
    _focusNode = FocusNode();
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _controller.text = _formatValue(widget.value);
      }
    });
  }

  @override
  void didUpdateWidget(covariant SliderWithTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = _formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatValue(double val) {
    if (val == val.toInt().toDouble()) return val.toInt().toString();
    return val.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            
            Container(
              width: 75,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: widget.color.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: widget.color, fontSize: 14),
                decoration: InputDecoration(
                  suffixText: widget.suffix,
                  suffixStyle: TextStyle(color: widget.color.withValues(alpha: 0.7), fontSize: 11),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  border: InputBorder.none,
                ),
                onSubmitted: (val) {
                  final parsed = double.tryParse(val.replaceAll(',', '.'));
                  if (parsed != null && parsed >= widget.min && parsed <= widget.max) {
                    widget.onChanged(parsed);
                  } else {
                    _controller.text = _formatValue(widget.value);
                  }
                },
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
            activeTrackColor: widget.color,
            thumbColor: widget.color,
            overlayColor: widget.color.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: widget.value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            onChanged: widget.onChanged,
          ),
        ),
      ],
    );
  }
}