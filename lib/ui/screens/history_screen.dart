import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kandangku/ui/theme/dark_theme.dart';

/// History Screen - "Riwayat Sensor" for PoultryVision (Kandangku)
/// Dark Industrial Green Theme with fl_chart visualizations
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Selected time filter index: 0 = 24 Jam, 1 = 7 Hari, 2 = 30 Hari
  int _selectedFilterIndex = 0;

  // Filter options in Bahasa Indonesia
  final List<String> _filterOptions = ['24 Jam', '7 Hari', '30 Hari'];

  // --- Dummy Data for Temperature Chart (FlSpot) ---
  List<FlSpot> get _temperatureData {
    switch (_selectedFilterIndex) {
      case 0: // 24 Hours - hourly data
        return const [
          FlSpot(0, 26),
          FlSpot(2, 25),
          FlSpot(4, 24.5),
          FlSpot(6, 25),
          FlSpot(8, 27),
          FlSpot(10, 29),
          FlSpot(12, 31),
          FlSpot(14, 32),
          FlSpot(16, 30),
          FlSpot(18, 28),
          FlSpot(20, 27),
          FlSpot(22, 26.5),
          FlSpot(24, 26),
        ];
      case 1: // 7 Days - daily averages
        return const [
          FlSpot(0, 27),
          FlSpot(1, 28),
          FlSpot(2, 29),
          FlSpot(3, 28.5),
          FlSpot(4, 27),
          FlSpot(5, 28),
          FlSpot(6, 28.5),
        ];
      case 2: // 30 Days - daily averages
        return const [
          FlSpot(0, 26),
          FlSpot(5, 27),
          FlSpot(10, 28),
          FlSpot(15, 29),
          FlSpot(20, 28),
          FlSpot(25, 27),
          FlSpot(30, 28),
        ];
      default:
        return const [];
    }
  }

  // --- Dummy Data for Ammonia Bar Chart ---
  List<BarChartGroupData> get _ammoniaData {
    switch (_selectedFilterIndex) {
      case 0: // 24 Hours - 6 data points (every 4 hours)
        return [
          _makeAmmoniaBar(0, 8),
          _makeAmmoniaBar(1, 12),
          _makeAmmoniaBar(2, 18),
          _makeAmmoniaBar(3, 22),
          _makeAmmoniaBar(4, 15),
          _makeAmmoniaBar(5, 10),
        ];
      case 1: // 7 Days
        return [
          _makeAmmoniaBar(0, 10),
          _makeAmmoniaBar(1, 14),
          _makeAmmoniaBar(2, 16),
          _makeAmmoniaBar(3, 12),
          _makeAmmoniaBar(4, 18),
          _makeAmmoniaBar(5, 15),
          _makeAmmoniaBar(6, 11),
        ];
      case 2: // 30 Days (weekly averages)
        return [
          _makeAmmoniaBar(0, 12),
          _makeAmmoniaBar(1, 15),
          _makeAmmoniaBar(2, 18),
          _makeAmmoniaBar(3, 14),
        ];
      default:
        return [];
    }
  }

  BarChartGroupData _makeAmmoniaBar(int x, double y) {
    final Color barColor = y > 20
        ? DarkTheme.statusWarning
        : DarkTheme.paleGreen;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: barColor,
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  // --- Summary Stats Calculation ---
  double get _averageTemperature {
    final data = _temperatureData;
    if (data.isEmpty) return 0;
    return data.map((e) => e.y).reduce((a, b) => a + b) / data.length;
  }

  double get _peakAmmonia {
    final data = _ammoniaData;
    if (data.isEmpty) return 0;
    return data.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkTheme.backgroundPrimary,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Filter Tabs
            _buildTimeFilterTabs(),
            const SizedBox(height: 24),

            // Temperature Line Chart
            _buildTemperatureChart(),
            const SizedBox(height: 24),

            // Ammonia Bar Chart
            _buildAmmoniaChart(),
            const SizedBox(height: 24),

            // Summary Cards
            _buildSummaryCards(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: DarkTheme.backgroundPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: DarkTheme.textPrimary,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        children: const [
          Text('Riwayat Sensor', style: DarkTheme.headerTitle),
          SizedBox(height: 2),
          Text(
            'Analisis tren 24 jam terakhir',
            style: DarkTheme.headerSubtitle,
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: DarkTheme.paleGreen),
          onPressed: () {
            // Refresh data action
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildTimeFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF162b1a), // Dark green container
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_filterOptions.length, (index) {
          final bool isSelected = _selectedFilterIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? DarkTheme.neonGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: DarkTheme.neonGreen.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    _filterOptions[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? DarkTheme.deepForestBlack
                          : DarkTheme.paleGreen,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTemperatureChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DarkTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DarkTheme.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.thermostat_rounded,
                  color: DarkTheme.neonGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Grafik Suhu', style: DarkTheme.controlTitle),
                  Text('Suhu (°C)', style: DarkTheme.controlSubtitle),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Line Chart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 20,
                maxY: 40,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: DarkTheme.neonGreen.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}°',
                          style: const TextStyle(
                            fontSize: 12,
                            color: DarkTheme.paleGreen,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _selectedFilterIndex == 0 ? 6 : 1,
                      getTitlesWidget: (value, meta) {
                        String label = '';
                        if (_selectedFilterIndex == 0) {
                          label = '${value.toInt()}h';
                        } else if (_selectedFilterIndex == 1) {
                          final days = [
                            'Sen',
                            'Sel',
                            'Rab',
                            'Kam',
                            'Jum',
                            'Sab',
                            'Min',
                          ];
                          if (value.toInt() < days.length) {
                            label = days[value.toInt()];
                          }
                        } else {
                          label = 'M${(value / 7).ceil()}';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: DarkTheme.paleGreen,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _temperatureData,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: DarkTheme.neonGreen,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          DarkTheme.neonGreen.withValues(alpha: 0.3),
                          DarkTheme.neonGreen.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                // Threshold line at 30°C
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 30,
                      color: DarkTheme.statusDanger,
                      strokeWidth: 2,
                      dashArray: [8, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 5, bottom: 5),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: DarkTheme.statusDanger,
                        ),
                        labelResolver: (_) => 'Batas 30°C',
                      ),
                    ),
                  ],
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: DarkTheme.deepForestBlack.withValues(
                      alpha: 0.9,
                    ),
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)}°C',
                          const TextStyle(
                            color: DarkTheme.neonGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmmoniaChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DarkTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DarkTheme.paleGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.cloud_outlined,
                  color: DarkTheme.paleGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Grafik Amonia', style: DarkTheme.controlTitle),
                  Text('Amonia (ppm)', style: DarkTheme.controlSubtitle),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bar Chart
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: 50,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: DarkTheme.neonGreen.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: DarkTheme.paleGreen,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        String label = '';
                        if (_selectedFilterIndex == 0) {
                          final times = [
                            '00:00',
                            '04:00',
                            '08:00',
                            '12:00',
                            '16:00',
                            '20:00',
                          ];
                          if (value.toInt() < times.length) {
                            label = times[value.toInt()];
                          }
                        } else if (_selectedFilterIndex == 1) {
                          final days = [
                            'Sen',
                            'Sel',
                            'Rab',
                            'Kam',
                            'Jum',
                            'Sab',
                            'Min',
                          ];
                          if (value.toInt() < days.length) {
                            label = days[value.toInt()];
                          }
                        } else {
                          final weeks = ['M1', 'M2', 'M3', 'M4'];
                          if (value.toInt() < weeks.length) {
                            label = weeks[value.toInt()];
                          }
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: DarkTheme.paleGreen,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _ammoniaData,
                // Threshold line at 20 ppm
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 20,
                      color: DarkTheme.statusDanger,
                      strokeWidth: 2,
                      dashArray: [8, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 5, bottom: 5),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: DarkTheme.statusDanger,
                        ),
                        labelResolver: (_) => 'Batas 20 ppm',
                      ),
                    ),
                  ],
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: DarkTheme.deepForestBlack.withValues(
                      alpha: 0.9,
                    ),
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(0)} ppm',
                        TextStyle(
                          color: rod.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rangkuman', style: DarkTheme.sectionTitle),
        const SizedBox(height: 16),
        Row(
          children: [
            // Average Temperature Card
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.thermostat_rounded,
                label: 'Rata-rata Suhu',
                value: '${_averageTemperature.toStringAsFixed(1)}°C',
                iconColor: DarkTheme.neonGreen,
              ),
            ),
            const SizedBox(width: 12),
            // Peak Ammonia Card
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.show_chart_rounded,
                label: 'Puncak Amonia',
                value: '${_peakAmmonia.toStringAsFixed(0)} ppm',
                iconColor: _peakAmmonia > 20
                    ? DarkTheme.statusWarning
                    : DarkTheme.paleGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DarkTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 14),
          // Label
          Text(label, style: DarkTheme.sensorLabel),
          const SizedBox(height: 6),
          // Value
          Text(value, style: DarkTheme.sensorValue.copyWith(fontSize: 26)),
        ],
      ),
    );
  }
}
