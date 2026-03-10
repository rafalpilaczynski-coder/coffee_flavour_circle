// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Dodaj intl do pubspec.yaml dla formatowania dat
import '../providers/tasting_provider.dart';
import '../core/constants.dart';
import '../shared/taste_radar_chart.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brewing History'), 
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) async {
              if (value == 'export') {
                await BackupService.exportData();
              } else if (value == 'import') {
                final success = await BackupService.importData();
                if (success) {
                  // Odświeżenie stanu historii po udanym imporcie
                  ref.invalidate(historyProvider); 
                  
                  // Bezpieczne wywołanie SnackBar po operacji asynchronicznej
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Data imported successfully!', style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.green.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Export Backup'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Import Backup'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: historyAsync.when(
        data: (sessions) => sessions.isEmpty
            ? const Center(child: Text('No sessions recorded yet.', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: sessions.length,
                itemBuilder: (context, index) => HistoryItemCard(session: sessions[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class HistoryItemCard extends ConsumerWidget { 
  final Map<String, dynamic> session;
  const HistoryItemCard({super.key, required this.session});

  String? _getIconPath(String category) {
    try {
      return mainFlavorCategories.firstWhere((c) => c['name'] == category)['icon'];
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) { 
    final DateTime date = DateTime.tryParse(session['timestamp'] ?? '') ?? DateTime.now();
    final String coffeeName = session['coffeeName']?.toString().isNotEmpty == true ? session['coffeeName'] : 'Unknown Roaster';
    
    final String beanDetails = session['beanDetails'] ?? '';
    final List<dynamic> defects = session['defects'] ?? [];
    final List<dynamic> dryNotes = session['dryNotes'] ?? [];
    final List<dynamic> wetNotes = session['wetNotes'] ?? [];

    // INŻYNIERIA BAZY: Odczyt młynka i kalkulacja mikrometrów na żywo
    final grindersAsync = ref.watch(grindersDatabaseProvider);
    final String grinderName = session['grinderName']?.toString().isNotEmpty == true ? session['grinderName'] : '';
    final String clicksStr = session['grinderSetting']?.toString() ?? '0';
    final int clicks = int.tryParse(clicksStr) ?? 0;
    
    // Szukamy mnożnika w bazie
    final activeGrinder = grindersAsync.value?.where((g) => g.fullName == grinderName).firstOrNull;
    final double activeMultiplier = activeGrinder?.stepMicron ?? 0.0;
    final double microns = clicks * activeMultiplier;

    // NOWE ZMIENNE: Pobieranie zaawansowanych parametrów z zapisanej sesji
    final String recipe = session['recipe'] ?? '';
    final String filterType = session['filterType'] ?? '';
    final String drawdownTime = session['drawdownTime'] ?? '';

    // INŻYNIERIA UX: Krok A - Zawinięcie karty w Dismissible
    return Dismissible(
      key: Key(session['timestamp'].toString()),
      direction: DismissDirection.endToStart, // Swipe tylko od prawej do lewej
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        decoration: BoxDecoration(
          color: Colors.red.shade800,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_forever, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        // Okno dialogowe zabezpieczające przed przypadkowym usunięciem
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1A18),
              title: const Text("Delete entry?", style: TextStyle(color: Colors.white)),
              content: const Text("This action cannot be undone.", style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        // Bezpośrednia mutacja pamięci SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final historyStr = prefs.getString('tasting_history');
        if (historyStr != null) {
          final List<dynamic> decoded = jsonDecode(historyStr);
          decoded.removeWhere((item) => item['timestamp'] == session['timestamp']);
          await prefs.setString('tasting_history', jsonEncode(decoded));
          
          // Wymuszenie odświeżenia interfejsu
          ref.invalidate(historyProvider);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          backgroundColor: const Color(0xFF1E1A18),
          collapsedBackgroundColor: const Color(0xFF1E1A18),
          title: Text(coffeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (beanDetails.isNotEmpty) ...[
                  Text(
                    beanDetails,
                    style: const TextStyle(fontSize: 14, color: Colors.white, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  DateFormat('yyyy-MM-dd | HH:mm').format(date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          trailing: _buildRatingBadge(session['enjoyment'] ?? 0.0),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('BREW SPECS'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround, 
                    children: [
                      _buildMiniInfo(Icons.water_drop, '${session['waterVolume']}ml'),
                      _buildMiniInfo(Icons.scale, '${session['dose']}g'),
                      _buildMiniInfo(Icons.thermostat, '${session['temperature']}°C'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (grinderName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.settings_input_component, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              grinderName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$clicksStr clicks',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                          if (activeMultiplier > 0 && clicks > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(${microns.toInt()} µm)',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                  
                  // ==========================================
                  // RENDEROWANIE ZAAWANSOWANYCH PARAMETRÓW
                  // ==========================================
                  if ((recipe.isNotEmpty && recipe != 'Custom') || (filterType.isNotEmpty && filterType != 'Paper (Bleached)') || drawdownTime.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          if (recipe.isNotEmpty && recipe != 'Custom')
                            _buildAdvancedRow(Icons.science_outlined, 'Recipe', recipe),
                          if (filterType.isNotEmpty && filterType != 'Paper (Bleached)')
                            _buildAdvancedRow(Icons.filter_alt_outlined, 'Filter', filterType),
                          if (drawdownTime.isNotEmpty)
                            _buildAdvancedRow(Icons.timer_outlined, 'Drawdown', drawdownTime),
                        ],
                      ),
                    ),
                  ],
                  // ==========================================

                  const Divider(height: 32, color: Colors.white10),

                  if (dryNotes.isNotEmpty || wetNotes.isNotEmpty) ...[
                    _buildSectionHeader('FRAGRANCE / AROMA'),
                    if (dryNotes.isNotEmpty) ...[
                      _buildTagWrap('Dry: ', dryNotes, Colors.amber.withValues(alpha: 0.2)),
                      const SizedBox(height: 8),
                    ],
                    if (wetNotes.isNotEmpty) ...[
                      _buildTagWrap('Wet: ', wetNotes, Colors.blue.withValues(alpha: 0.2)),
                      const SizedBox(height: 8),
                    ],
                    const Divider(height: 32, color: Colors.white10),
                  ],

                  _buildSectionHeader('FLAVOR PROFILE'),
                  _buildFlavorRow(
                    session['primaryFlavorMain'], 
                    session['primaryFlavorSub'], 
                    session['primaryFlavorSpecific'], 
                    isPrimary: true
                  ),
                  const SizedBox(height: 8),
                  _buildFlavorRow(
                    session['secondaryFlavorMain'], 
                    session['secondaryFlavorSub'],
                    session['secondaryFlavorSpecific'] 
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Center(
                    child: TasteRadarChart(
                      sweetness: (session['sweetness'] ?? 5.0).toDouble(),
                      acidity: (session['acidity'] ?? 5.0).toDouble(),
                      bitterness: (session['bitterness'] ?? 5.0).toDouble(),
                      size: 120, 
                    ),
                  ),

                  const Divider(height: 32, color: Colors.white10),
                  
                  if (defects.isNotEmpty) ...[
                    _buildSectionHeader('SCA DEFECTS'),
                    Wrap(
                      spacing: 8,
                      children: defects.map((d) => Chip(
                        label: Text(d, style: const TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.4),
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                    const Divider(height: 32, color: Colors.white10),
                  ],

                  if (session['notes']?.toString().isNotEmpty ?? false) ...[
                    _buildSectionHeader('NOTES'),
                    Text(
                      session['notes'],
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildMiniInfo(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTagWrap(String label, List<dynamic> tags, Color color) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ...tags.map((t) => Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            child: Text(t, style: const TextStyle(fontSize: 10)),
          ),
        )),
      ],
    );
  }

  Widget _buildFlavorRow(String? main, String? sub, String? specific, {bool isPrimary = false}) {
    if (main == null || main.isEmpty) return const SizedBox.shrink();
    final iconPath = _getIconPath(main);

    return Row(
      children: [
        if (iconPath != null)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
            child: Image.asset(iconPath, width: 14, height: 14, color: Colors.black),
          ),
        const SizedBox(width: 8),
        Text(main, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        
        const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
        Text(sub?.isNotEmpty == true ? sub! : 'Overall', style: const TextStyle(fontSize: 13, color: Colors.white70)),
        
        if (specific != null && specific.isNotEmpty) ...[
          const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          Text(specific, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        ],
      ],
    );
  }

  // INŻYNIERIA UX: Krok B - Nowa metoda renderowania ocen (zależna od skali kolorów)
  Widget _buildRatingBadge(double enjoyment) {
    Color badgeColor;
    if (enjoyment >= 8.0) {
      badgeColor = Colors.green.shade500;
    } else if (enjoyment >= 6.0) {
      badgeColor = Colors.lightGreen;
    } else if (enjoyment >= 4.0) {
      badgeColor = Colors.amber;
    } else if (enjoyment >= 2.0) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Colors.red.shade400;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: badgeColor, size: 14),
          const SizedBox(width: 4),
          Text(enjoyment.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor)),
        ],
      ),
    );
  }
}