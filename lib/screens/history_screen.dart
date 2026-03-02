// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/tasting_provider.dart';
import '../core/constants.dart';

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
              
              // Ekstrakcja danych
              final dateString = session['timestamp'] as String;
              final date = DateTime.parse(dateString).toLocal();
              final formattedDate = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
              
              final coffeeName = session['coffeeName']?.toString().isNotEmpty == true 
                  ? session['coffeeName'] 
                  : 'Kawa nieznana';
              final method = session['method'] ?? 'V60';
              final score = (session['enjoyment'] as num?)?.toDouble() ?? 0.0;
              
              final primaryMain = session['primaryFlavorMain'] ?? 'Brak';
              final primarySub = session['primaryFlavorSub'] ?? '';
              final secondaryMain = session['secondaryFlavorMain'];
              final secondarySub = session['secondaryFlavorSub'] ?? '';

              final uniqueKey = Key(session['timestamp'] as String);

              // Algorytm kolorowania oceny końcowej
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

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sesja usunięta: $coffeeName', style: const TextStyle(color: Colors.white)),
                          backgroundColor: appSurface,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  // Zoptymalizowana Karta Danych (Neumorfizm i Nowe Metody Kolorów)
                  child: Container(
                    decoration: BoxDecoration(
                      color: appSurface,
                      borderRadius: BorderRadius.circular(16),
                      // Modernizacja: withValues zamiast withOpacity
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Wskaźnik liczbowy (Ocena)
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: scoreColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: scoreColor.withValues(alpha: 0.4), width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                score.toStringAsFixed(1),
                                style: TextStyle(
                                  color: scoreColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // 2. Blok Danych Strukturalnych
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nagłówek: Nazwa kawy i Data
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$coffeeName',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: appTextPrimary,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: appTextSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // Metoda Zaparzania (Tag)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: appPrimary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    method,
                                    style: const TextStyle(fontSize: 11, color: appPrimary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                
                                // Wizualne Drzewo Smaków z Kropkami Kodu Koloru
                                if (primaryMain != 'Brak') ...[
                                  const Text(
                                    'PRIMARY FLAVOR',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: appTextSecondary, letterSpacing: 1.2),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _getFlavorColor(primaryMain),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '$primaryMain ${primarySub.isNotEmpty ? "➔ $primarySub" : ""}',
                                          style: const TextStyle(fontSize: 14, color: appTextPrimary, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                
                                if (secondaryMain != null) ...[
                                  const Text(
                                    'SECONDARY FLAVOR',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: appTextSecondary, letterSpacing: 1.2),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _getFlavorColor(secondaryMain),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '$secondaryMain ${secondarySub.isNotEmpty ? "➔ $secondarySub" : ""}',
                                          style: const TextStyle(fontSize: 14, color: appTextPrimary, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
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