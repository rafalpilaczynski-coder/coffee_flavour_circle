// lib/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/tasting_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Zmiana na 3 zakładki
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Brew Analytics', style: TextStyle(fontSize: 18)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.grey,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            tabs: [
              Tab(icon: Icon(Icons.bar_chart), text: 'By Method'),
              Tab(icon: Icon(Icons.scatter_plot), text: 'Brew Ratio'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Economics'),
            ],
          ),
        ),
        body: const TabBarView(
          physics: BouncingScrollPhysics(),
          children: [
            _BrewMethodTab(), 
            _BrewRatioTab(), 
            _EconomicsTab(), // NOWA ZAKŁADKA
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ZAKŁADKA 1: ANALIZA METODY PARZENIA (Bar Chart)
// ============================================================================
class _BrewMethodTab extends ConsumerStatefulWidget {
  const _BrewMethodTab();

  @override
  ConsumerState<_BrewMethodTab> createState() => _BrewMethodTabState();
}

class _BrewMethodTabState extends ConsumerState<_BrewMethodTab> {
  String _selectedYAxis = 'enjoyment';

  Color _getColorForMetric(String metric) {
    switch (metric) {
      case 'enjoyment': return Colors.amber;
      case 'sweetness': return Colors.pinkAccent;
      case 'acidity': return Colors.lightGreenAccent;
      case 'bitterness': return Colors.deepOrange;
      default: return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Center(child: Text('Not enough data.', style: TextStyle(color: Colors.grey)));
        }

        Map<String, List<double>> methodScores = {};
        for (var s in sessions) {
          final method = s['method']?.toString().trim();
          if (method == null || method.isEmpty) continue;
          final score = (s[_selectedYAxis] as num?)?.toDouble() ?? 3.0;
          
          if (!methodScores.containsKey(method)) {
            methodScores[method] = [];
          }
          methodScores[method]!.add(score);
        }

        if (methodScores.isEmpty) {
          return const Center(child: Text('No brewing methods recorded.', style: TextStyle(color: Colors.grey)));
        }

        List<MapEntry<String, double>> avgScores = methodScores.entries.map((e) {
          double avg = e.value.reduce((a, b) => a + b) / e.value.length;
          return MapEntry(e.key, avg);
        }).toList();

        avgScores.sort((a, b) => b.value.compareTo(a.value));

        List<BarChartGroupData> barGroups = [];
        for (int i = 0; i < avgScores.length; i++) {
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: avgScores[i].value,
                  color: _getColorForMetric(_selectedYAxis),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 5.0,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: const Color(0xFF1E1A18),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.science, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      const Text('Metric:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedYAxis,
                            dropdownColor: const Color(0xFF2C2520),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'enjoyment', child: Text('Overall Enjoyment', style: TextStyle(fontSize: 14))),
                              DropdownMenuItem(value: 'sweetness', child: Text('Average Sweetness', style: TextStyle(fontSize: 14))),
                              DropdownMenuItem(value: 'acidity', child: Text('Average Acidity', style: TextStyle(fontSize: 14))),
                              DropdownMenuItem(value: 'bitterness', child: Text('Average Bitterness', style: TextStyle(fontSize: 14))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedYAxis = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Average Score by Brew Method', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.amber)),
              const SizedBox(height: 8),
              const Text('Data sorted descending by average value.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
              const SizedBox(height: 32),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 5.0,
                    minY: 0.0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => const Color(0xFF1E1A18),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final entry = avgScores[group.x.toInt()];
                          final count = methodScores[entry.key]!.length;
                          return BarTooltipItem(
                            '${entry.key}\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            children: [
                              TextSpan(text: 'Avg: ${entry.value.toStringAsFixed(2)}\n', style: TextStyle(color: _getColorForMetric(_selectedYAxis), fontSize: 13, fontWeight: FontWeight.bold)),
                              TextSpan(text: '(n = $count)', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.normal)),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return Text(value.toInt().toString(), style: const TextStyle(color: Colors.white70, fontSize: 11));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < avgScores.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(avgScores[index].key, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(color: Colors.white24, width: 2),
                        left: BorderSide(color: Colors.white24, width: 2),
                        top: BorderSide.none,
                        right: BorderSide.none,
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [5, 5]),
                    ),
                    barGroups: barGroups,
                  ),
                  duration: const Duration(milliseconds: 600), 
                  curve: Curves.easeOutQuart,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// ZAKŁADKA 2: ANALIZA BREW RATIO (Scatter Chart)
// ============================================================================
class _BrewRatioTab extends ConsumerStatefulWidget {
  const _BrewRatioTab();

  @override
  ConsumerState<_BrewRatioTab> createState() => _BrewRatioTabState();
}

class _BrewRatioTabState extends ConsumerState<_BrewRatioTab> {
  String _selectedYAxis = 'enjoyment';

  Color _getColorForMetric(String metric) {
    switch (metric) {
      case 'enjoyment': return Colors.amber;
      case 'sweetness': return Colors.pinkAccent;
      case 'acidity': return Colors.lightGreenAccent;
      case 'bitterness': return Colors.deepOrange;
      default: return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (sessions) {
        final validSessions = sessions.where((s) {
          final dose = (s['dose'] as num?)?.toDouble() ?? 0;
          final water = (s['waterVolume'] as num?)?.toDouble() ?? 0;
          return dose > 0 && water > 0;
        }).toList();

        if (validSessions.isEmpty) {
          return const Center(child: Text('Not enough data.', style: TextStyle(color: Colors.grey)));
        }

        List<ScatterSpot> scatterSpots = [];
        double minRatio = 100.0;
        double maxRatio = 0.0;

        for (var s in validSessions) {
          final dose = (s['dose'] as num).toDouble();
          final water = (s['waterVolume'] as num).toDouble();
          final ratio = water / dose;
          
          if (ratio < minRatio) minRatio = ratio;
          if (ratio > maxRatio) maxRatio = ratio;

          final yValue = (s[_selectedYAxis] as num?)?.toDouble() ?? 3.0;

          scatterSpots.add(ScatterSpot(
            ratio,
            yValue,
            dotPainter: FlDotCirclePainter(
              radius: 6,
              color: _getColorForMetric(_selectedYAxis).withValues(alpha: 0.5),
              strokeWidth: 1,
              strokeColor: _getColorForMetric(_selectedYAxis),
            ),
          ));
        }

        final minX = (minRatio - 1).clamp(0.0, 30.0);
        final maxX = (maxRatio + 1).clamp(0.0, 30.0);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: const Color(0xFF1E1A18),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.science, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      const Text('Y-Axis Metric:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedYAxis,
                            dropdownColor: const Color(0xFF2C2520),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'enjoyment', child: Text('Overall Enjoyment', style: TextStyle(fontSize: 14))),
                              DropdownMenuItem(value: 'sweetness', child: Text('Sweetness', style: TextStyle(fontSize: 14))),
                              DropdownMenuItem(value: 'acidity', child: Text('Acidity', style: TextStyle(fontSize: 14))),
                              DropdownMenuItem(value: 'bitterness', child: Text('Bitterness', style: TextStyle(fontSize: 14))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedYAxis = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Brew Ratio vs. Attribute', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.amber)),
              const SizedBox(height: 8),
              const Text('Find your extraction sweet spot.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
              const SizedBox(height: 32),
              Expanded(
                child: ScatterChart(
                  ScatterChartData(
                    scatterSpots: scatterSpots,
                    minX: minX,
                    maxX: maxX,
                    minY: 0.5,
                    maxY: 5.5,
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(color: Colors.white24, width: 2),
                        left: BorderSide(color: Colors.white24, width: 2),
                        top: BorderSide.none,
                        right: BorderSide.none,
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [5, 5]),
                      getDrawingVerticalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [5, 5]),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text('Brew Ratio (1:X)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text('Score', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value < 1 || value > 5) return const SizedBox.shrink();
                            return Text(value.toInt().toString(), style: const TextStyle(color: Colors.white70, fontSize: 11));
                          },
                        ),
                      ),
                    ),
                    scatterTouchData: ScatterTouchData(
                      enabled: true,
                      touchTooltipData: ScatterTouchTooltipData(
                        getTooltipItems: (touchedSpot) {
                          return ScatterTooltipItem(
                            'Ratio 1:${touchedSpot.x.toStringAsFixed(1)}\nScore: ${touchedSpot.y.toStringAsFixed(1)}',
                            textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                  duration: const Duration(milliseconds: 600), 
                  curve: Curves.easeOutQuart,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// ZAKŁADKA 3: INŻYNIERIA KOSZTÓW (Ekonomia Parzenia)
// ============================================================================
class _EconomicsTab extends ConsumerWidget {
  const _EconomicsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (sessions) {
        // Filtrujemy tylko te parzenia, które posiadają zdefiniowany koszt > 0
        final costSessions = sessions.where((s) => ((s['brewCost'] as num?)?.toDouble() ?? 0.0) > 0).toList();

        if (costSessions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No financial data yet.\n\nMake sure to add prices to your Coffee Bags in the Library. Future brews will automatically calculate the price per cup.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
            ),
          );
        }

        double totalSpent = 0.0;
        Map<String, double> monthlySpent = {};

        for (var s in costSessions) {
          final cost = (s['brewCost'] as num).toDouble();
          totalSpent += cost;

          final dateStr = s['timestamp'] as String?;
          if (dateStr != null) {
            final date = DateTime.tryParse(dateStr);
            if (date != null) {
              final monthKey = DateFormat('MMM yyyy').format(date); // np. Mar 2026
              monthlySpent[monthKey] = (monthlySpent[monthKey] ?? 0.0) + cost;
            }
          }
        }

        final avgCost = totalSpent / costSessions.length;

        // Sortowanie kluczy chronologicznie
        final sortedKeys = monthlySpent.keys.toList()..sort((a, b) {
          final dA = DateFormat('MMM yyyy').parse(a);
          final dB = DateFormat('MMM yyyy').parse(b);
          return dA.compareTo(dB);
        });

        // Dane do wykresu słupkowego
        List<BarChartGroupData> barGroups = [];
        double maxSpent = 0.0;
        for (int i = 0; i < sortedKeys.length; i++) {
          final spent = monthlySpent[sortedKeys[i]]!;
          if (spent > maxSpent) maxSpent = spent;
          
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: spent,
                  color: Colors.greenAccent.shade400,
                  width: 32,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxSpent * 1.2, // Tło trochę powyżej maksymalnego słupka
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // GŁÓWNA KARTA PODSUMOWUJĄCA
              Card(
                color: const Color(0xFF1E1A18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.greenAccent, size: 32),
                      const SizedBox(height: 12),
                      const Text('Total Value Consumed', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${totalSpent.toStringAsFixed(2)} PLN',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(color: Colors.white10, height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text('Avg Cost / Cup', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text('${avgCost.toStringAsFixed(2)} PLN', style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(width: 1, height: 30, color: Colors.white10),
                          Column(
                            children: [
                              const Text('Tracked Brews', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text('${costSessions.length}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              const Text('Monthly Spending Breakdown', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.amber)),
              const SizedBox(height: 32),
              
              // WYKRES MIESIĘCZNY
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxSpent * 1.2, // Lekki margines na górze
                    minY: 0.0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => const Color(0xFF1E1A18),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final month = sortedKeys[group.x.toInt()];
                          return BarTooltipItem(
                            '$month\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            children: [
                              TextSpan(text: '${rod.toY.toStringAsFixed(2)} PLN', style: TextStyle(color: Colors.greenAccent.shade400, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value > maxSpent) return const SizedBox.shrink();
                            return Text('${value.toInt()}', style: const TextStyle(color: Colors.white70, fontSize: 11));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < sortedKeys.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(sortedKeys[index], style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(color: Colors.white24, width: 2),
                        left: BorderSide(color: Colors.white24, width: 2),
                        top: BorderSide.none,
                        right: BorderSide.none,
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [5, 5]),
                    ),
                    barGroups: barGroups,
                  ),
                  duration: const Duration(milliseconds: 600), 
                  curve: Curves.easeOutQuart,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}