// lib/screens/final_evaluation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/tasting_provider.dart';
import '../core/constants.dart';
import '../shared/primary_button.dart';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
              child: Text(
                'SENSORY PROFILE', 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: appTextSecondary, letterSpacing: 1.5)
              ),
            ),
            
            // Grupowanie suwaków w eleganckiej karcie (Neumorfizm / Surface)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: appSurface,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: [
                    PremiumTasteSlider(
                      label: "Sweetness",
                      value: tastingData.sweetness,
                      min: 0,
                      max: 10,
                      onChanged: (val) => notifier.updateSweetness(val),
                    ),
                    const SizedBox(height: 20),
                    PremiumTasteSlider(
                      label: "Acidity",
                      value: tastingData.acidity,
                      min: 0,
                      max: 10,
                      onChanged: (val) => notifier.updateAcidity(val),
                    ),
                    const SizedBox(height: 20),
                    PremiumTasteSlider(
                      label: "Bitterness",
                      value: tastingData.bitterness,
                      min: 0,
                      max: 10,
                      onChanged: (val) => notifier.updateBitterness(val),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
              child: Text(
                'OVERALL EXPERIENCE', 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: appTextSecondary, letterSpacing: 1.5)
              ),
            ),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: appSurface,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: PremiumTasteSlider(
                  label: "Enjoyment",
                  value: tastingData.enjoyment,
                  min: 1,
                  max: 5,
                  divisions: 40, // Skok co 0.1 w skali 1-5
                  accentColor: Colors.amber, // Wyróżnienie oceny końcowej kolorem złotym
                  onChanged: (val) => notifier.updateEnjoyment(val),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            PrimaryActionButton(
              label: 'SAVE SESSION',
              color: Colors.green.shade700, // Sygnał akcji afirmatywnej (zapis)
              onPressed: () async {
                await notifier.saveSession();
                ref.invalidate(historyProvider);
            
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Sesja została pomyślnie zapisana!', style: TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.green.shade800,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    )
                  );
                  context.go('/');
                }
              },
            ), 
          ],
        ),
      ),
    );
  }
}

// ==========================================
// DEDYKOWANY KOMPONENT: PremiumTasteSlider
// ==========================================
class PremiumTasteSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final Color? accentColor;

  const PremiumTasteSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions = 100,
    required this.onChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor ?? appPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Górny wiersz: Etykieta oraz dokładny odczyt liczbowy (rozwiązanie Thumb Occlusion)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: appTextPrimary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: activeColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                value.toStringAsFixed(1),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: activeColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Nadpisanie motywu suwaka dla tego konkretnego widgetu (grubsza linia, większy uchwyt)
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8.0,
            activeTrackColor: activeColor,
            inactiveTrackColor: Colors.black26,
            thumbColor: activeColor,
            overlayColor: activeColor.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0, elevation: 4),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
            trackShape: const RoundedRectSliderTrackShape(),
            // Wyłączamy domyślną "chmurkę" z wartością, bo mamy własny czytelny wskaźnik wyżej
            showValueIndicator: ShowValueIndicator.never, 
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}