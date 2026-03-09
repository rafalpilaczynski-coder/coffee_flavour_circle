// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Dodaj intl do pubspec.yaml dla formatowania dat
import '../providers/tasting_provider.dart';
import '../core/constants.dart';
import '../shared/taste_radar_chart.dart';

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

class HistoryItemCard extends ConsumerWidget { // ZMIANA 1: Z Stateless na ConsumerWidget
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
  Widget build(BuildContext context, WidgetRef ref) { // ZMIANA 2: Wstrzyknięcie WidgetRef
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

    return Card(
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround, // Lepsze rozłożenie dla 3 elementów
                  children: [
                    _buildMiniInfo(Icons.water_drop, '${session['waterVolume']}ml'),
                    _buildMiniInfo(Icons.scale, '${session['dose']}g'),
                    _buildMiniInfo(Icons.thermostat, '${session['temperature']}°C'),
                    // Młynek usunięty z tego rzędu - przeniesiony niżej
                  ],
                ),
                const SizedBox(height: 16),
                
                // ZMIANA 3: Dedykowany baner dla młynka i mikrometrów
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
                        // Wyświetlamy mikrometry tylko, jeśli młynek jest w bazie i wpisano wartość > 0
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

  Widget _buildRatingBadge(double enjoyment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 14),
          const SizedBox(width: 4),
          Text(enjoyment.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
        ],
      ),
    );
  }
}