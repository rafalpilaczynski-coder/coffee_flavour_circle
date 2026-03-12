// lib/screens/final_evaluation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/tasting_provider.dart';
import '../core/constants.dart';
import '../shared/primary_button.dart';
import '../core/brewing_logic.dart';
import 'package:flutter/services.dart';

class FinalEvaluationScreen extends ConsumerStatefulWidget {
  const FinalEvaluationScreen({super.key});

  @override
  ConsumerState<FinalEvaluationScreen> createState() => _FinalEvaluationScreenState();
}

class _FinalEvaluationScreenState extends ConsumerState<FinalEvaluationScreen> {
  late TextEditingController _notesController;
  late TextEditingController _drawdownController; // INŻYNIERIA UX: Dodano kontroler czasu

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(tastingProvider);
    _notesController = TextEditingController(text: initialState.notes);
    _drawdownController = TextEditingController(text: initialState.drawdownTime);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _drawdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tastingData = ref.watch(tastingProvider);
    final notifier = ref.read(tastingProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Final Evaluation'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SMAKI PODSTAWOWE (Skala 1-5)
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
              child: Text(
                'BASIC TASTES', 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: appTextSecondary, letterSpacing: 1.5)
              ),
            ),
            
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: appSurface,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: [
                    RelativeTasteSlider(
                      label: "Sweetness",
                      value: tastingData.sweetness,
                      onChanged: (val) => notifier.updateSweetness(val),
                      leftLabel: 'low sweetness',
                      centerLabel: 'moderate sweetness',
                      rightLabel: 'high sweetness',
                      activeColor: Colors.pinkAccent,
                    ),
                    const SizedBox(height: 32),
                    RelativeTasteSlider(
                      label: "Acidity",
                      value: tastingData.acidity,
                      onChanged: (val) => notifier.updateAcidity(val),
                      leftLabel: 'low acidity',
                      centerLabel: 'moderate acidity',
                      rightLabel: 'high acidity',
                      activeColor: Colors.lightGreenAccent,
                    ),
                    const SizedBox(height: 32),
                    RelativeTasteSlider(
                      label: "Bitterness",
                      value: tastingData.bitterness,
                      onChanged: (val) => notifier.updateBitterness(val),
                      leftLabel: 'low bitterness',
                      centerLabel: 'moderate bitterness',
                      rightLabel: 'high bitterness',
                      activeColor: Colors.brown[300]!,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // 2. OVERALL ENJOYMENT (Skala 1.0 - 5.0, skok 0.25)
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
              child: Text(
                'OVERALL ENJOYMENT', 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: appTextSecondary, letterSpacing: 1.5)
              ),
            ),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: appSurface,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      tastingData.enjoyment.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.amber,
                        inactiveTrackColor: Colors.black26,
                        thumbColor: Colors.amber,
                        overlayColor: Colors.amber.withValues(alpha: 0.2),
                        trackHeight: 8.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14.0, elevation: 4),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 28.0),
                        trackShape: const RoundedRectSliderTrackShape(),
                      ),
                      child: Slider(
                        value: tastingData.enjoyment,
                        min: 1.0,
                        max: 5.0,
                        divisions: 16, // Co 0.25
                        onChanged: (val) => notifier.updateEnjoyment(val),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 3. WYNIKI PROCESU (Drawdown Time) - Zastępuje SCA Defects
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
              child: Text(
                'EXTRACTION METRICS', 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: appTextSecondary, letterSpacing: 1.5)
              ),
            ),

            TextField(
              controller: _drawdownController,
              keyboardType: TextInputType.number,
              inputFormatters: [TimeTextInputFormatter()], // Dodanie formatowania czasu
              onChanged: (val) => notifier.updateDrawdownTime(val),
              decoration: InputDecoration(
                labelText: 'Total Drawdown Time (Czas całkowity)',
                hintText: 'e.g. 02:45',
                hintStyle: const TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
                prefixIcon: const Icon(Icons.timer_outlined, color: Colors.grey),
                filled: true,
                fillColor: appSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.amber.shade700),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 4. Wolne Notatki
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
              child: Text(
                'BREWING NOTES', 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: appTextSecondary, letterSpacing: 1.5)
              ),
            ),

            TextField(
              controller: _notesController,
              maxLines: 4,
              onChanged: (val) => notifier.updateNotes(val),
              decoration: InputDecoration(
                hintText: 'e.g. Drawdown was 15s too fast. Next time try 2 clicks finer...',
                hintStyle: const TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
                filled: true,
                fillColor: appSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.green.shade700),
                ),
              ),
            ),

            const SizedBox(height: 40),
            
            // ZAPISZ SESJĘ
            PrimaryActionButton(
              label: 'SAVE SESSION',
              color: Colors.green.shade700,
              onPressed: () async {
                final currentState = ref.read(tastingProvider);
                
                final advice = BrewingAssistant.getAdvice(
                  sweetness: currentState.sweetness,
                  acidity: currentState.acidity,
                  bitterness: currentState.bitterness,
                  enjoyment: currentState.enjoyment,
                );

                await notifier.saveSession();
                ref.invalidate(historyProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      backgroundColor: const Color(0xFF1E1A18),
                      duration: const Duration(seconds: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.green.shade700, width: 1.5),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
                              const SizedBox(width: 8),
                              const Text('Session saved!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.psychology_outlined, color: Colors.amber, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Next brew: $advice',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                  context.push('/');
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// DEDYKOWANY KOMPONENT: RelativeTasteSlider
// ==========================================
class RelativeTasteSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String leftLabel;
  final String centerLabel;
  final String rightLabel;
  final Color activeColor;

  const RelativeTasteSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.leftLabel,
    required this.centerLabel,
    required this.rightLabel,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    // Skala od 1 do 5
    final safeValue = value.clamp(1.0, 5.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                safeValue.toInt().toString(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: activeColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6.0,
            activeTrackColor: activeColor,
            inactiveTrackColor: Colors.black26,
            thumbColor: activeColor,
            overlayColor: activeColor.withValues(alpha: 0.2),
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3),
            activeTickMarkColor: Colors.white54,
            inactiveTickMarkColor: Colors.white24,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0, elevation: 4),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
          ),
          child: Slider(
            value: safeValue,
            min: 1.0,
            max: 5.0,
            divisions: 4, // 1, 2, 3, 4, 5
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(leftLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(centerLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(rightLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}
class TimeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Usuwa wszystko co nie jest cyfrą
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 4) return oldValue; // Max 4 cyfry (MMSS)
    
    String newString = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2) newString += ':'; // Automatyczne wstawianie dwukropka
      newString += text[i];
    }
    
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}