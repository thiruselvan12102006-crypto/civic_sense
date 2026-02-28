import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DetectionChart extends StatelessWidget {
  final List detections;

  const DetectionChart({super.key, required this.detections});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> frequency = {};

    for (var item in detections) {
      frequency[item["class"]] =
          (frequency[item["class"]] ?? 0) + 1;
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          barGroups: frequency.entries
              .toList()
              .asMap()
              .entries
              .map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value.toDouble(),
                  width: 18,
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}