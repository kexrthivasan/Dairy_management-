import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MorningEveningPieChart extends StatelessWidget {
  final double morning;
  final double evening;

  const MorningEveningPieChart({
    super.key,
    required this.morning,
    required this.evening,
  });

  @override
  Widget build(BuildContext context) {
    if (morning == 0 && evening == 0) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Morning vs Evening Share",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.orangeAccent,
                      value: morning,
                      title:
                          '${((morning / (morning + evening)) * 100).toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.indigoAccent,
                      value: evening,
                      title:
                          '${((evening / (morning + evening)) * 100).toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.orangeAccent),
                    SizedBox(width: 4),
                    Text("Morning"),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.nightlight_round, color: Colors.indigoAccent),
                    SizedBox(width: 4),
                    Text("Evening"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
