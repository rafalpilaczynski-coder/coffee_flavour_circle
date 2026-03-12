// lib/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/tasting_provider.dart';
//import '../core/constants.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _selectedYAxis = 'enjoyment'; // Domyślna metryka

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brew Ratio Analysis', style: TextStyle(fontSize: 18)),
        centerTitle: true,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (sessions) {
          // 1. Filtracja i przygotowanie danych wejściowych
          final validSessions = sessions.where((s) {
            final dose = (s['dose'] as num?)?.toDouble() ?? 0;
            final water = (s['waterVolume'] as num?)?.toDouble() ?? 0;
            return dose > 0 && water > 0;
          }).toList();

          if (validSessions.isEmpty) {
            return const Center(child: Text('Not enough data to calculate statistics.', style: TextStyle(color: Colors.grey)));
          }

          // 2. Mapowanie punktów (ScatterSpots)
          List<ScatterSpot> scatterSpots = [];
          double minRatio = 100.0;
          double maxRatio = 0.0;

          for (var s in validSessions) {
            final dose = (s['dose'] as num).toDouble();
            final water = (s['waterVolume'] as num).toDouble();
            final ratio = water / dose;
            
            if (ratio < minRatio) minRatio = ratio;
            if (ratio > maxRatio) maxRatio = ratio;

            // Bezpieczny odczyt wartości na osi Y (skala 1.0 - 5.0)
            final yValue = (s[_selectedYAxis] as num?)?.toDouble() ?? 3.0;

            scatterSpots.add(ScatterSpot(
              ratio,
              yValue,
              dotPainter: FlDotCirclePainter(
                radius: 6,
                // Półprzezroczystość pozwala dojrzeć zagęszczenie (klastrowanie) danych
                color: _getColorForMetric(_selectedYAxis).withValues(alpha: 0.5),
                strokeWidth: 1,
                strokeColor: _getColorForMetric(_selectedYAxis),
              ),
            ));
          }

          // Zabezpieczenie osi X przed błędami renderingu przy małej ilości danych
          final minX = (minRatio - 1).clamp(0.0, 30.0);
          final maxX = (maxRatio + 1).clamp(0.0, 30.0);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Panel kontrolny inżyniera
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
                                DropdownMenuItem(value: 'enjoyment', child: Text('Overall Enjoyment (1-5)', style: TextStyle(fontSize: 14))),
                                DropdownMenuItem(value: 'sweetness', child: Text('Sweetness (1-5)', style: TextStyle(fontSize: 14))),
                                DropdownMenuItem(value: 'acidity', child: Text('Acidity (1-5)', style: TextStyle(fontSize: 14))),
                                DropdownMenuItem(value: 'bitterness', child: Text('Bitterness (1-5)', style: TextStyle(fontSize: 14))),
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
                const Text('Find your extraction sweet spot (optimal clustering).', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                const SizedBox(height: 32),
                
                // GŁÓWNY WYKRES ROZRZUTU
                Expanded(
                  child: ScatterChart(
                    ScatterChartData(
                      scatterSpots: scatterSpots,
                      minX: minX,
                      maxX: maxX,
                      minY: 0.5,
                      maxY: 5.5, // Oś obejmująca naszą precyzyjną skalę 1-5
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
                      // Tooltip pokazujący się po naciśnięciu punktu
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
      ),
    );
  }

  Color _getColorForMetric(String metric) {
    switch (metric) {
      case 'enjoyment': return Colors.amber;
      case 'sweetness': return Colors.pinkAccent;
      case 'acidity': return Colors.lightGreenAccent;
      case 'bitterness': return Colors.deepOrange;
      default: return Colors.amber;
    }
  }
}