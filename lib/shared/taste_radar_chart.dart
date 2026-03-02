// lib/shared/taste_radar_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants.dart';

class TasteRadarChart extends StatelessWidget {
  final double sweetness;
  final double acidity;
  final double bitterness;
  final double size;

  const TasteRadarChart({
    super.key,
    required this.sweetness,
    required this.acidity,
    required this.bitterness,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.circle,
          dataSets: [
            RadarDataSet(
              fillColor: appPrimary.withValues(alpha: 0.3),
              borderColor: appPrimary,
              entryRadius: 2,
              dataEntries: [
                RadarEntry(value: sweetness),
                RadarEntry(value: acidity),
                RadarEntry(value: bitterness),
              ],
              borderWidth: 2,
            ),
          ],
          // Definicja osi (0-10)
          getTitle: (index, angle) {
            switch (index) {
              case 0: return const RadarChartTitle(text: 'S', angle: 0); // Sweet
              case 1: return const RadarChartTitle(text: 'A', angle: 0); // Acid
              case 2: return const RadarChartTitle(text: 'B', angle: 0); // Bitter
              default: return const RadarChartTitle(text: '');
            }
          },
          tickCount: 2,
          ticksTextStyle: const TextStyle(color: Colors.transparent), // Ukrywamy liczby dla czystości
          gridBorderData: BorderSide(color: appTextSecondary.withValues(alpha: 0.2)),
        ),
      ),
    );
  }
}