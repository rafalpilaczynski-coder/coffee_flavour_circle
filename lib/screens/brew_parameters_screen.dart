import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/tasting_provider.dart';
import '../core/constants.dart';
import '../shared/primary_button.dart';

class BrewParametersScreen extends ConsumerStatefulWidget {
  const BrewParametersScreen({super.key});

  @override
  ConsumerState<BrewParametersScreen> createState() => _BrewParametersScreenState();
}

class _BrewParametersScreenState extends ConsumerState<BrewParametersScreen> {
  late TextEditingController _coffeeController;
  late TextEditingController _grinderNameController;
  late TextEditingController _grinderSettingController;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(tastingProvider);
    _coffeeController = TextEditingController(text: initialState.coffeeName);
    _grinderNameController = TextEditingController(text: initialState.grinderName);
    _grinderSettingController = TextEditingController(text: initialState.grinderSetting);
  }

  @override
  void dispose() {
    _coffeeController.dispose();
    _grinderNameController.dispose();
    _grinderSettingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tastingData = ref.watch(tastingProvider);
    final notifier = ref.read(tastingProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Brew Parameters'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('COFFEE & METHOD'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: tastingData.method.isNotEmpty && brewMethods.contains(tastingData.method) 
                          ? tastingData.method 
                          : brewMethods.first,
                      decoration: const InputDecoration(labelText: 'Brew Method'),
                      items: brewMethods.map((method) {
                        return DropdownMenuItem(value: method, child: Text(method));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) notifier.updateMethod(val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _coffeeController,
                      decoration: const InputDecoration(labelText: 'Coffee Name / Roaster (Optional)'),
                      onChanged: (val) => notifier.updateCoffeeName(val),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('EQUIPMENT (OPTIONAL)'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _grinderNameController,
                      decoration: const InputDecoration(labelText: 'Grinder (e.g. Comandante, Niche)'),
                      onChanged: (val) => notifier.updateGrinderName(val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _grinderSettingController,
                      decoration: const InputDecoration(labelText: 'Grinder Setting / Clicks'),
                      onChanged: (val) => notifier.updateGrinderSetting(val),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('PHYSICAL PARAMETERS'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Water Temperature'),
                        Text('${tastingData.temperature.toStringAsFixed(1)} °C', 
                             style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    Slider(
                      value: tastingData.temperature,
                      min: 80, max: 100, divisions: 200,
                      onChanged: (val) => notifier.updateTemperature(val),
                    ),
                    
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Water Volume / Yield'),
                        Text('${tastingData.waterVolume.toInt()} ml', 
                             style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.lightBlueAccent)),
                      ],
                    ),
                    Slider(
                      value: tastingData.waterVolume,
                      min: 50, max: 1000, divisions: 950,
                      onChanged: (val) => notifier.updateWaterVolume(val),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Center(
                        child: Text(
                          'Brew Ratio 1 : ${(tastingData.waterVolume / tastingData.dose).toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
                        ),
                      ),
                    ),

                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Coffee Dose'),
                        Text('${tastingData.dose.toStringAsFixed(1)} g', 
                             style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    Slider(
                      value: tastingData.dose,
                      min: 5, max: 50, divisions: 450,
                      onChanged: (val) => notifier.updateDose(val),
                    ),
                  ],
                ),
              ),
            ),
            
            PrimaryActionButton(
              label: 'NEXT: FRAGRANCE ANALYSIS',
              onPressed: () => context.go('/fragrance'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }
}