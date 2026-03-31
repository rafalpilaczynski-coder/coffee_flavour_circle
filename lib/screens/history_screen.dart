// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 
import '../providers/tasting_provider.dart';
import '../core/constants.dart';
import '../shared/taste_radar_chart.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  // INŻYNIERIA DANYCH: Stan filtrów
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedMethods = {};
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isFilterActive => 
      _searchController.text.isNotEmpty || _selectedMethods.isNotEmpty || _dateRange != null;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedMethods.clear();
      _dateRange = null;
    });
  }

  void _showFilterSheet(List<String> availableMethods) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75, // Zabezpieczenie przed klawiaturą
              decoration: const BoxDecoration(
                color: Color(0xFF14110F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 16.0, 
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16.0 // Margines na klawiaturę
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nagłówek Panelu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filter History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _searchController.clear();
                              _selectedMethods.clear();
                              _dateRange = null;
                            });
                            setState(() {}); // Aktualizacja ekranu głównego
                          },
                          child: const Text('CLEAR ALL', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        )
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),

                    // 1. Filtr Tekstowy (Kawa / Palarnia)
                    const Text('COFFEE OR ROASTER', style: TextStyle(color: Color(0xFFC27D56), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search beans, origins, roasters...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E1A18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (val) {
                        setState(() {}); // Natychmiastowe odświeżenie listy pod spodem
                      },
                    ),
                    const SizedBox(height: 24),

                    // 2. Zakres Dat
                    const Text('DATE RANGE', style: TextStyle(color: Color(0xFFC27D56), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _dateRange,
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.amber,
                                  onPrimary: Colors.black,
                                  surface: Color(0xFF1E1A18),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => _dateRange = picked);
                          setState(() {});
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1A18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.grey, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _dateRange == null 
                                    ? 'Select dates...' 
                                    : '${DateFormat('MMM dd, yyyy').format(_dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)}',
                                style: TextStyle(color: _dateRange == null ? Colors.white38 : Colors.white),
                              ),
                            ),
                            if (_dateRange != null)
                              GestureDetector(
                                onTap: () {
                                  setModalState(() => _dateRange = null);
                                  setState(() {});
                                },
                                child: const Icon(Icons.close, color: Colors.grey, size: 18),
                              )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Metody Parzenia (Dynamicznie zebrane z historii)
                    const Text('BREW METHODS', style: TextStyle(color: Color(0xFFC27D56), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableMethods.map((method) {
                            final isSelected = _selectedMethods.contains(method);
                            return FilterChip(
                              label: Text(method, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12)),
                              selected: isSelected,
                              selectedColor: Colors.amber.withValues(alpha: 0.3),
                              checkmarkColor: Colors.amber,
                              backgroundColor: const Color(0xFF1E1A18),
                              side: BorderSide(color: isSelected ? Colors.amber : Colors.white10),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    _selectedMethods.add(method);
                                  } else {
                                    _selectedMethods.remove(method);
                                  }
                                });
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    // Przycisk zamykający
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC27D56)),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('APPLY FILTERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brewing History'), 
        centerTitle: true,
        actions: [
          // INŻYNIERIA UI: Ikona lejka podświetlana gdy filtr jest aktywny
          historyAsync.when(
            data: (sessions) {
              final availableMethods = sessions
                  .map((s) => s['method']?.toString() ?? '')
                  .where((m) => m.isNotEmpty)
                  .toSet()
                  .toList()..sort();
                  
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.filter_list, color: _isFilterActive ? Colors.amber : Colors.white),
                    tooltip: 'Filter History',
                    onPressed: () => _showFilterSheet(availableMethods),
                  ),
                  if (_isFilterActive)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                    )
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.white70),
            tooltip: 'Statistics & Correlations',
            onPressed: () => context.push('/statistics'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) async {
              if (value == 'export') {
                await BackupService.exportData();
              } else if (value == 'import') {
                final success = await BackupService.importData();
                if (success) {
                  ref.invalidate(historyProvider); 
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
        data: (allSessions) {
          if (allSessions.isEmpty) {
            return const Center(child: Text('No sessions recorded yet.', style: TextStyle(color: Colors.grey)));
          }

          // INŻYNIERIA DANYCH: Logika filtrowania listy
          final filteredSessions = allSessions.where((session) {
            // 1. Filtr Tekstowy (Kawa)
            if (_searchController.text.isNotEmpty) {
              final query = _searchController.text.toLowerCase();
              final roaster = (session['coffeeName'] ?? '').toString().toLowerCase();
              final bean = (session['beanDetails'] ?? '').toString().toLowerCase();
              if (!roaster.contains(query) && !bean.contains(query)) {
                return false;
              }
            }

            // 2. Filtr Metod
            if (_selectedMethods.isNotEmpty) {
              final method = (session['method'] ?? '').toString();
              if (!_selectedMethods.contains(method)) {
                return false;
              }
            }

            // 3. Filtr Daty
            if (_dateRange != null) {
              final dateStr = session['timestamp'] as String?;
              if (dateStr == null) return false;
              final date = DateTime.tryParse(dateStr);
              if (date == null) return false;

              // Używamy .add(Duration(days: 1)), aby objąć cały dzień końcowy aż do 23:59:59
              if (date.isBefore(_dateRange!.start) || date.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
                return false;
              }
            }

            return true; // Przeszło wszystkie filtry
          }).toList();

          if (filteredSessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No brews match your filters.', style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('CLEAR FILTERS', style: TextStyle(color: Colors.amber)),
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredSessions.length,
            itemBuilder: (context, index) => HistoryItemCard(session: filteredSessions[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

// Reszta kodu (HistoryItemCard) pozostaje bez zmian.
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

  Color _getMethodColor(String method) {
    final m = method.toLowerCase();
    if (m.contains('v60')) return Colors.red.shade400;
    if (m.contains('aeropress')) return Colors.blue.shade400;
    if (m.contains('chemex')) return Colors.brown.shade400;
    if (m.contains('kalita')) return Colors.teal.shade400;
    if (m.contains('espresso')) return Colors.deepPurple.shade400;
    if (m.contains('moka')) return Colors.orange.shade600;
    if (m.contains('clever')) return Colors.cyan.shade600;
    if (m.contains('switch')) return Colors.green.shade500;
    if (m.contains('orea')) return Colors.pink.shade300;
    if (m.contains('v30')) return Colors.indigo.shade400;
    return Colors.amber; 
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) { 
    final DateTime date = DateTime.tryParse(session['timestamp'] ?? '') ?? DateTime.now();
    
    final String roasterName = session['coffeeName']?.toString().isNotEmpty == true ? session['coffeeName'] : 'Unknown Roaster';
    final String beanName = session['beanDetails']?.toString().isNotEmpty == true ? session['beanDetails'] : 'Unknown Coffee';
    
    final String method = session['method']?.toString().isNotEmpty == true ? session['method'] : 'Unknown';
    final Color methodColor = _getMethodColor(method);
    
    final List<dynamic> defects = session['defects'] ?? [];
    final List<dynamic> dryNotes = session['dryNotes'] ?? [];
    final List<dynamic> wetNotes = session['wetNotes'] ?? [];

    final grindersAsync = ref.watch(grindersDatabaseProvider);
    final String grinderName = session['grinderName']?.toString().isNotEmpty == true ? session['grinderName'] : '';
    final String clicksStr = session['grinderSetting']?.toString() ?? '0';
    final int clicks = int.tryParse(clicksStr) ?? 0;
    
    final activeGrinder = grindersAsync.value?.where((g) => g.fullName == grinderName).firstOrNull;
    final double activeMultiplier = activeGrinder?.stepMicron ?? 0.0;
    final double microns = clicks * activeMultiplier;

    final String recipe = session['recipe'] ?? '';
    final String filterType = session['filterType'] ?? '';
    final String drawdownTime = session['drawdownTime'] ?? '';
    final double brewCost = (session['brewCost'] as num?)?.toDouble() ?? 0.0;

    return Dismissible(
      key: Key(session['timestamp'].toString()),
      direction: DismissDirection.endToStart, 
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
        final prefs = await SharedPreferences.getInstance();
        final historyStr = prefs.getString('tasting_history');
        if (historyStr != null) {
          final List<dynamic> decoded = jsonDecode(historyStr);
          decoded.removeWhere((item) => item['timestamp'] == session['timestamp']);
          await prefs.setString('tasting_history', jsonEncode(decoded));
          ref.invalidate(historyProvider);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: methodColor.withValues(alpha: 0.35), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          backgroundColor: const Color(0xFF1E1A18),
          collapsedBackgroundColor: const Color(0xFF1E1A18),
          title: Text(beanName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 6.0),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: methodColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: methodColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    method.toUpperCase(),
                    style: TextStyle(color: methodColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
                Text(
                  roasterName,
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('yyyy-MM-dd | HH:mm').format(date)}${brewCost > 0 ? '  •  ${brewCost.toStringAsFixed(2)} PLN' : ''}',
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
                      if (brewCost > 0)
                        _buildMiniInfo(Icons.payments_outlined, '${brewCost.toStringAsFixed(2)} PLN'),
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
                  if (session['primaryFlavorMain']?.toString().isNotEmpty == true) ...[
                    _buildFlavorRow(
                      session['primaryFlavorMain'], 
                      session['primaryFlavorSub'], 
                      session['primaryFlavorSpecific'], 
                      isPrimary: true
                    ),
                  ],
                  if (session['secondaryFlavorMain']?.toString().isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    _buildFlavorRow(
                      session['secondaryFlavorMain'], 
                      session['secondaryFlavorSub'],
                      session['secondaryFlavorSpecific'] 
                    ),
                  ],
                  if (session['tertiaryFlavorMain']?.toString().isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    _buildFlavorRow(
                      session['tertiaryFlavorMain'], 
                      session['tertiaryFlavorSub'],
                      session['tertiaryFlavorSpecific'] 
                    ),
                  ],
                  
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