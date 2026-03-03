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

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(tastingProvider);
    _coffeeController = TextEditingController(text: initialState.coffeeName);
    _grinderSettingController = TextEditingController(text: initialState.grinderSetting);
  }

  @override
  void dispose() {
    _coffeeController.dispose();
    _grinderSettingController.dispose();
    super.dispose();
  }

  Widget _buildAutocompleteField({
    required String label,
    required List<String> options,
    required String initialValue,
    required Function(String) onSelected,
    required Function(String) onChanged,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        return options.where((String option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        if (controller.text.isEmpty && initialValue.isNotEmpty) controller.text = initialValue;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            isDense: true, // Zmniejsza wysokość pola tekstowego
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
          onChanged: onChanged,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: appSurface,
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 24, // Połowa ekranu minus marginesy
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
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
    final roasteries = ref.watch(uniqueRoasteriesProvider);

    final activeMethods = userPrefs.activeMethods.isNotEmpty ? userPrefs.activeMethods : ['V60'];
    final selectedMethod = activeMethods.contains(tastingData.method) ? tastingData.method : activeMethods.first;

    final activeGrinders = userPrefs.grinders.where((g) => g.trim().isNotEmpty).toList();
    if (!activeGrinders.contains('')) activeGrinders.insert(0, '');
    final selectedGrinder = activeGrinders.contains(tastingData.grinderName) ? tastingData.grinderName : activeGrinders.first;

    final lastSetting = userPrefs.lastGrinderSettings[selectedGrinder];
    final hintText = (lastSetting != null && lastSetting.trim().isNotEmpty && selectedGrinder.isNotEmpty) 
        ? 'last setting: $lastSetting' 
        : 'e.g. 24';

    final dose = tastingData.dose;
    final water = tastingData.waterVolume;
    final ratio = dose > 0 ? (water / dose) : 0.0;
    final isOutlier = dose > 0 && water > 0 && (ratio < 12.0 || ratio > 20.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brew Parameters', style: TextStyle(fontSize: 18)), 
        centerTitle: true,
        toolbarHeight: 48, // Węższy AppBar
      ),
      // SafeArea zapewnia, że elementy nie wejdą pod systemowe paski (notch/home bar)
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Zblokowana karta parametrów wejściowych (2x2 Grid)
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
                              decoration: const InputDecoration(labelText: 'Method', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12)),
                              items: activeMethods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (val) { if (val != null) notifier.updateMethod(val); },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedGrinder,
                              decoration: const InputDecoration(labelText: 'Grinder', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12)),
                              items: activeGrinders.map((g) => DropdownMenuItem(value: g, child: Text(g.isEmpty ? 'None' : g, style: const TextStyle(fontSize: 13)))).toList(),
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
                              label: 'Coffee / Roaster',
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
                              decoration: InputDecoration(
                                labelText: 'Clicks/Setting',
                                hintText: hintText,
                                hintStyle: const TextStyle(color: Colors.white38, fontStyle: FontStyle.italic, fontSize: 11),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              ),
                              onChanged: (val) => notifier.updateGrinderSetting(val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Sekcja suwaków ściśnięta do maksimum
              Expanded(
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCompactSliderRow('Temp', '${tastingData.temperature.toStringAsFixed(1)} °C', Colors.blue, 
                          Slider(value: tastingData.temperature, min: 80, max: 100, divisions: 200, onChanged: (val) => notifier.updateTemperature(val))),
                        
                        _buildCompactSliderRow('Yield', '${tastingData.waterVolume.toInt()} ml', Colors.lightBlueAccent, 
                          Slider(value: tastingData.waterVolume, min: 50, max: 1000, divisions: 950, onChanged: (val) => notifier.updateWaterVolume(val))),
                        
                        _buildCompactSliderRow('Dose', '${tastingData.dose.toStringAsFixed(1)} g', Colors.green, 
                          Slider(value: tastingData.dose, min: 5, max: 50, divisions: 450, onChanged: (val) => notifier.updateDose(val))),

                        Text(
                          'Brew Ratio 1 : ${ratio.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
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

              const SizedBox(height: 12),
              PrimaryActionButton(
                label: 'NEXT: FRAGRANCE ANALYSIS',
                onPressed: () => context.go('/fragrance'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSliderRow(String label, String value, Color color, Widget slider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ],
        ),
        // Wykorzystanie SliderTheme do zredukowania ukrytego paddingu suwaka
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
          ),
          child: slider,
        ),
      ],
    );
  }
}