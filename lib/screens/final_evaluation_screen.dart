import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/tasting_provider.dart';

class FinalEvaluationScreen extends ConsumerWidget {
  const FinalEvaluationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tastingData = ref.watch(tastingProvider);
    final notifier = ref.read(tastingProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Final Evaluation'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTasteSlider("Sweetness", tastingData.sweetness, (val) => notifier.updateSweetness(val)),
            _buildTasteSlider("Acidity", tastingData.acidity, (val) => notifier.updateAcidity(val)),
            _buildTasteSlider("Bitterness", tastingData.bitterness, (val) => notifier.updateBitterness(val)),
            
            const SizedBox(height: 30),
            const Divider(),
            const Text("Overall Enjoyment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("(1: Not for me, 5: Absolutely amazing!)", style: TextStyle(color: Colors.grey)),
            
            Slider(
              value: tastingData.enjoyment,
              min: 1, max: 5, divisions: 4,
              label: tastingData.enjoyment.round().toString(),
              onChanged: (val) => notifier.updateEnjoyment(val),
            ),
            
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  await notifier.saveSession();
                  ref.invalidate(historyProvider);
              
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sesja została pomyślnie zapisana!'), backgroundColor: Colors.green)
                    );
                    context.go('/');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SAVE SESSION', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ), 
          ],
        ),
      ),
    );
  }

  Widget _buildTasteSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Text("$label: ${value.toStringAsFixed(1)}"),
        Slider(value: value, min: 0, max: 10, divisions: 100, onChanged: onChanged),
      ],
    );
  }
}