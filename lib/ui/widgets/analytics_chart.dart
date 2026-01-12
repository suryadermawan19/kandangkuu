import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsChart extends StatelessWidget {
  final List<Map<String, dynamic>> historyData;

  const AnalyticsChart({super.key, required this.historyData});

  @override
  Widget build(BuildContext context) {
    if (historyData.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No History Data', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // Process data for chart
    // Assuming historyData is ordered descending (newest first), so reverse for chart (oldest left)
    final sortedData = historyData.reversed.toList();

    List<FlSpot> tempSpots = [];
    List<FlSpot> ammoniaSpots = [];

    for (int i = 0; i < sortedData.length; i++) {
      final data = sortedData[i];
      final temp = (data['temperature'] as num?)?.toDouble() ?? 0;
      final ammonia = (data['ammonia'] as num?)?.toDouble() ?? 0;

      tempSpots.add(FlSpot(i.toDouble(), temp));
      ammoniaSpots.add(FlSpot(i.toDouble(), ammonia));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'History Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ), // Hide X labels for simplicity
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Temperature Line
                  LineChartBarData(
                    spots: tempSpots,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withValues(alpha: 0.1),
                    ),
                  ),
                  // Ammonia Line
                  LineChartBarData(
                    spots: ammoniaSpots,
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purple.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Temp (°C)', Colors.orange),
              const SizedBox(width: 20),
              _buildLegend('Ammonia (ppm)', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
