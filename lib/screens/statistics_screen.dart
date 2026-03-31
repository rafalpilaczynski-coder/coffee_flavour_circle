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
// ZAKŁADKA 3: INŻYNIERIA KOSZTÓW I ZUŻYCIA (Dashboard)
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
        if (sessions.isEmpty) {
          return const Center(child: Text('No data available.', style: TextStyle(color: Colors.grey)));
        }

        // 1. Zmienne do wyliczeń
        double totalSpent = 0.0;
        double totalDoseAll = 0.0;
        double totalVolumeAll = 0.0;
        double volumeWithCost = 0.0;
        int sessionsWithCost = 0;

        DateTime? firstDate;
        DateTime? lastDate;
        Map<String, double> monthlySpent = {};

        // 2. Iteracja po całej historii
        for (var s in sessions) {
          final dose = (s['dose'] as num?)?.toDouble() ?? 0.0;
          final volume = (s['waterVolume'] as num?)?.toDouble() ?? 0.0;
          final cost = (s['brewCost'] as num?)?.toDouble() ?? 0.0;
          
          totalDoseAll += dose;
          totalVolumeAll += volume;

          final dateStr = s['timestamp'] as String?;
          if (dateStr != null) {
            final date = DateTime.tryParse(dateStr);
            if (date != null) {
              if (firstDate == null || date.isBefore(firstDate)) firstDate = date;
              if (lastDate == null || date.isAfter(lastDate)) lastDate = date;

              if (cost > 0) {
                final monthKey = DateFormat('MMM yyyy').format(date);
                monthlySpent[monthKey] = (monthlySpent[monthKey] ?? 0.0) + cost;
              }
            }
          }

          if (cost > 0) {
            totalSpent += cost;
            volumeWithCost += volume;
            sessionsWithCost++;
          }
        }

        // 3. Kalkulacja statystyk czasowych (Span)
        int daysSpan = 1;
        if (firstDate != null && lastDate != null) {
          // Dodajemy +1, aby uwzględnić dzień bieżący (jeśli pierwszy i ostatni log są z tego samego dnia, span = 1)
          daysSpan = lastDate.difference(firstDate).inDays + 1;
          if (daysSpan < 1) daysSpan = 1; 
        }

        // 4. Kalkulacja KPI
        final cupsPerDay = sessions.length / daysSpan;
        final dosePerDay = totalDoseAll / daysSpan;
        final totalYieldLiters = totalVolumeAll / 1000;
        
        final costPerLiter = volumeWithCost > 0 ? totalSpent / (volumeWithCost / 1000) : 0.0;
        final avgCostPerCup = sessionsWithCost > 0 ? totalSpent / sessionsWithCost : 0.0;

        // Przygotowanie danych do wykresu
        final sortedKeys = monthlySpent.keys.toList()..sort((a, b) {
          final dA = DateFormat('MMM yyyy').parse(a);
          final dB = DateFormat('MMM yyyy').parse(b);
          return dA.compareTo(dB);
        });

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
                    toY: maxSpent > 0 ? maxSpent * 1.2 : 10, 
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('DASHBOARD', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey)),
              const SizedBox(height: 16),
              
              // SIATKA KPI
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildKpiCard('Total Spent', '${totalSpent.toStringAsFixed(2)} PLN', Icons.account_balance_wallet, Colors.greenAccent),
                  _buildKpiCard('Avg / Cup', '${avgCostPerCup.toStringAsFixed(2)} PLN', Icons.local_cafe, Colors.amber),
                  _buildKpiCard('Brews / Day', cupsPerDay.toStringAsFixed(1), Icons.bar_chart, Colors.lightBlueAccent),
                  _buildKpiCard('Dose / Day', '${dosePerDay.toStringAsFixed(1)}g', Icons.scale, Colors.orangeAccent),
                  _buildKpiCard('Total Yield', '${totalYieldLiters.toStringAsFixed(1)}L', Icons.water_drop, Colors.cyan),
                  _buildKpiCard('Price / Liter', '${costPerLiter.toStringAsFixed(2)} PLN', Icons.price_check, Colors.purpleAccent),
                ],
              ),
              
              const SizedBox(height: 40),
              const Text('MONTHLY SPENDING BREAKDOWN', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey)),
              const SizedBox(height: 32),
              
              // WYKRES MIESIĘCZNY (Zabezpieczony przed brakiem danych kosztowych)
              if (sortedKeys.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    'No financial data recorded yet.\nSet coffee prices in your library to see charts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
                  ),
                )
              else
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxSpent * 1.2,
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
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // Pomocniczy widget do generowania kafelków KPI
  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}