// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/tasting_provider.dart';
import '../core/constants.dart';
import '../shared/taste_radar_chart.dart';
import '../core/brewing_logic.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  // Pomocnicza funkcja inżynieryjna: Mapowanie nazwy smaku na fizyczny kolor ze stałych
  Color _getFlavorColor(String flavorName) {
    try {
      final category = mainFlavorCategories.firstWhere(
        (cat) => cat['name'] == flavorName,
        orElse: () => {'color': Colors.grey},
      );
      return category['color'] as Color;
    } catch (e) {
      return Colors.grey;
    }
  }
  Widget _buildFlavorRow(String main, String sub) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getFlavorColor(main),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$main ${sub.isNotEmpty ? "➔ $sub" : ""}',
            style: const TextStyle(fontSize: 13, color: appTextPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsyncValue = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasting History'), 
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: historyAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator(color: appPrimary)),
        error: (error, stack) => Center(child: Text('Błąd odczytu: $error', style: const TextStyle(color: Colors.redAccent))),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Text(
                'Brak zapisanych sesji.\nCzas zaparzyć pierwszą kawę!',
                textAlign: TextAlign.center,
                style: TextStyle(color: appTextSecondary, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              
              // 1. Ekstrakcja i formatowanie podstawowych danych
              final dateString = session['timestamp'] as String;
              final date = DateTime.parse(dateString).toLocal();
              final formattedDate = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
              
              final coffeeName = session['coffeeName']?.toString().isNotEmpty == true 
                  ? session['coffeeName'] 
                  : 'Kawa nieznana';
              final method = session['method'] ?? 'V60';
              final score = (session['enjoyment'] as num?)?.toDouble() ?? 0.0;
              
              // 2. Ekstrakcja wektorów smaku dla Spider Charta
              final sweetness = (session['sweetness'] as num?)?.toDouble() ?? 5.0;
              final acidity = (session['acidity'] as num?)?.toDouble() ?? 5.0;
              final bitterness = (session['bitterness'] as num?)?.toDouble() ?? 5.0;

              // 3. Analiza przez Asystenta Korekty
              final suggestion = BrewingAssistant.getSuggestion(
                sweetness: sweetness,
                acidity: acidity,
                bitterness: bitterness,
                enjoyment: score,
              );
              
              // 4. Ekstrakcja profilu smakowego
              final primaryMain = session['primaryFlavorMain'] ?? 'Brak';
              final primarySub = session['primaryFlavorSub'] ?? '';
              final secondaryMain = session['secondaryFlavorMain'];
              final secondarySub = session['secondaryFlavorSub'] ?? '';

              final uniqueKey = Key(session['timestamp'] as String);

              // Kolorystyka oceny
              Color scoreColor = score >= 4.0 
                  ? Colors.green.shade500 
                  : (score >= 3.0 ? Colors.amber.shade500 : Colors.redAccent.shade400);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Dismissible(
                  key: uniqueKey,
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24.0),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.shade700,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
                  ),
                  onDismissed: (direction) async {
                    final prefs = await SharedPreferences.getInstance();
                    final savedSessions = prefs.getStringList('coffee_sessions_history') ?? [];
                    final originalIndex = savedSessions.length - 1 - index;

                    if (originalIndex >= 0 && originalIndex < savedSessions.length) {
                      savedSessions.removeAt(originalIndex);
                      await prefs.setStringList('coffee_sessions_history', savedSessions);
                    }
                    ref.invalidate(historyProvider);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: appSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // KOLUMNA LEWA: Wizualizacja (Radar + Wynik)
                              Column(
                                children: [
                                  TasteRadarChart(
                                    sweetness: sweetness,
                                    acidity: acidity,
                                    bitterness: bitterness,
                                    size: 80,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    score.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: scoreColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              
                              // KOLUMNA PRAWA: Dane tekstowe
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$coffeeName',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appTextPrimary),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(formattedDate, style: const TextStyle(fontSize: 12, color: appTextSecondary)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    
                                    // Tag metody
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: appPrimary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        method,
                                        style: const TextStyle(fontSize: 10, color: appPrimary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Profile smakowe z kolorowymi kropkami
                                    if (primaryMain != 'Brak') 
                                      _buildFlavorRow(primaryMain, primarySub),
                                    
                                    if (secondaryMain != null) 
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: _buildFlavorRow(secondaryMain, secondarySub),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // SEKCJA DOLNA: Asystent (tylko jeśli wynik < 4.0)
                          if (score < 4.0) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(color: Colors.white10, height: 1),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.auto_fix_high, size: 14, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    suggestion,
                                    style: TextStyle(
                                      fontSize: 11, 
                                      color: Colors.amber.withValues(alpha: 0.9), 
                                      fontStyle: FontStyle.italic,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}