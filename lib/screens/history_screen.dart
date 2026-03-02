import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/tasting_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Błąd odczytu: $error')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Text(
                'Brak zapisanych sesji.\nCzas zaparzyć pierwszą kawę!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              
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

              String primaryText = primaryMain != 'Brak' ? '$primaryMain ${primarySub.isNotEmpty ? "($primarySub)" : ""}' : 'Brak profilu';
              String secondaryText = secondaryMain != null ? '\nDodatkowo: $secondaryMain ${secondarySub.isNotEmpty ? "($secondarySub)" : ""}' : '';

              final uniqueKey = Key(session['timestamp'] as String);

              return Dismissible(
                key: uniqueKey,
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete_sweep, color: Colors.white, size: 30),
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
                        content: Text('Sesja $coffeeName została usunięta.'),
                        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
                      ),
                    );
                  }
                },
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: score >= 4.0 ? Colors.green : (score >= 3.0 ? Colors.blueAccent : Colors.orange),
                      radius: 24,
                      child: Text(
                        score.toStringAsFixed(1), 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ),
                    title: Text('$coffeeName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Metoda: $method | $formattedDate'),
                          const SizedBox(height: 4),
                          Text('Profil: $primaryText$secondaryText', style: const TextStyle(color: Colors.amber)),
                        ],
                      ),
                    ),
                    isThreeLine: true,
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