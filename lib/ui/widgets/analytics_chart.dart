import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kandangku/ui/theme/app_theme.dart';

class AnalyticsChart extends StatelessWidget {
  final List<Map<String, dynamic>> historyData;

  const AnalyticsChart({super.key, required this.historyData});

  @override
  Widget build(BuildContext context) {
    if (historyData.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textDisabled.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Tidak Ada Data Riwayat',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textDisabled.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren Riwayat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textDisabled.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
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
                      color: Colors.orange.withValues(alpha: 0.15),
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
                      color: Colors.purple.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Suhu (°C)', Colors.orange),
              const SizedBox(width: 24),
              _buildLegend('Amonia (ppm)', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
