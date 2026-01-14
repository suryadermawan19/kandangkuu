import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kandangku/ui/theme/dark_theme.dart';

/// History Screen - "Riwayat Sensor" for PoultryVision (Kandangku)
/// Dark Industrial Green Theme with fl_chart visualizations
/// Now supports 4 metric charts: Suhu, Amonia, Pakan, Air
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Selected time filter index: 0 = 24 Jam, 1 = 7 Hari, 2 = 30 Hari
  int _selectedFilterIndex = 0;

  // Selected metric index: 0 = Suhu, 1 = Amonia, 2 = Pakan, 3 = Air
  int _selectedMetricIndex = 0;

  // Filter options in Bahasa Indonesia
  final List<String> _filterOptions = ['24 Jam', '7 Hari', '30 Hari'];

  // Metric options in Bahasa Indonesia
  final List<Map<String, dynamic>> _metricOptions = [
    {'label': 'Suhu', 'icon': Icons.thermostat_rounded},
    {'label': 'Amonia', 'icon': Icons.cloud_outlined},
    {'label': 'Pakan', 'icon': Icons.grain_rounded},
    {'label': 'Air', 'icon': Icons.water_drop_rounded},
  ];

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

  // --- Dummy Data for Feed Consumption (Pakan) Line Chart ---
  List<FlSpot> get _feedData {
    switch (_selectedFilterIndex) {
      case 0: // 24 Hours - decreasing trend
        return const [
          FlSpot(0, 8.0),
          FlSpot(4, 7.2),
          FlSpot(8, 6.5),
          FlSpot(12, 5.8),
          FlSpot(16, 5.0),
          FlSpot(20, 4.2),
          FlSpot(24, 4.0),
        ];
      case 1: // 7 Days - decreasing with refill
        return const [
          FlSpot(0, 10.0),
          FlSpot(1, 8.5),
          FlSpot(2, 7.0),
          FlSpot(3, 5.5),
          FlSpot(4, 9.0), // Refill
          FlSpot(5, 7.5),
          FlSpot(6, 6.0),
        ];
      case 2: // 30 Days - pattern with refills
        return const [
          FlSpot(0, 10.0),
          FlSpot(5, 5.0),
          FlSpot(6, 10.0), // Refill
          FlSpot(12, 4.0),
          FlSpot(13, 10.0), // Refill
          FlSpot(20, 5.0),
          FlSpot(21, 10.0), // Refill
          FlSpot(30, 6.0),
        ];
      default:
        return const [];
    }
  }

  // --- Dummy Data for Water Level Status Bar Chart ---
  List<BarChartGroupData> get _waterData {
    switch (_selectedFilterIndex) {
      case 0: // 24 Hours - 6 data points (status: 3=Penuh, 2=Normal, 1=Rendah, 0=Habis)
        return [
          _makeWaterBar(0, 3), // Penuh
          _makeWaterBar(1, 3), // Penuh
          _makeWaterBar(2, 2), // Normal
          _makeWaterBar(3, 2), // Normal
          _makeWaterBar(4, 3), // Penuh (refill)
          _makeWaterBar(5, 3), // Penuh
        ];
      case 1: // 7 Days
        return [
          _makeWaterBar(0, 3),
          _makeWaterBar(1, 2),
          _makeWaterBar(2, 2),
          _makeWaterBar(3, 1), // Low
          _makeWaterBar(4, 3), // Refill
          _makeWaterBar(5, 2),
          _makeWaterBar(6, 2),
        ];
      case 2: // 30 Days (weekly summary)
        return [
          _makeWaterBar(0, 3),
          _makeWaterBar(1, 2),
          _makeWaterBar(2, 2),
          _makeWaterBar(3, 3),
        ];
      default:
        return [];
    }
  }

  BarChartGroupData _makeWaterBar(int x, double level) {
    Color barColor;
    switch (level.toInt()) {
      case 3: // Penuh
        barColor = DarkTheme.neonGreen;
        break;
      case 2: // Normal
        barColor = DarkTheme.paleGreen;
        break;
      case 1: // Rendah
        barColor = DarkTheme.statusWarning;
        break;
      default: // Habis
        barColor = DarkTheme.statusDanger;
    }

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: level,
          color: barColor,
          width: 24,
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

  double get _averageFeed {
    final data = _feedData;
    if (data.isEmpty) return 0;
    return data.map((e) => e.y).reduce((a, b) => a + b) / data.length;
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
            const SizedBox(height: 20),

            // Metric Selector
            _buildMetricSelector(),
            const SizedBox(height: 20),

            // Dynamic Chart based on selected metric
            _buildSelectedChart(),
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
          Text('Analisis tren sensor kandang', style: DarkTheme.headerSubtitle),
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

  Widget _buildMetricSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF162b1a),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(_metricOptions.length, (index) {
          final bool isSelected = _selectedMetricIndex == index;
          final metric = _metricOptions[index];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMetricIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DarkTheme.cardBackground
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(
                          color: DarkTheme.neonGreen.withValues(alpha: 0.5),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      metric['icon'] as IconData,
                      size: 22,
                      color: isSelected
                          ? DarkTheme.neonGreen
                          : DarkTheme.paleGreen,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metric['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? DarkTheme.textPrimary
                            : DarkTheme.paleGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedChart() {
    switch (_selectedMetricIndex) {
      case 0:
        return _buildTemperatureChart();
      case 1:
        return _buildAmmoniaChart();
      case 2:
        return _buildFeedChart();
      case 3:
        return _buildWaterChart();
      default:
        return _buildTemperatureChart();
    }
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

  Widget _buildFeedChart() {
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
                  color: DarkTheme.statusWarning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.grain_rounded,
                  color: DarkTheme.statusWarning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Konsumsi Pakan', style: DarkTheme.controlTitle),
                  Text('Sisa Pakan (kg)', style: DarkTheme.controlSubtitle),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Line Chart (Decreasing trend)
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 12,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
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
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()} kg',
                          style: const TextStyle(
                            fontSize: 11,
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
                      interval: _selectedFilterIndex == 0
                          ? 6
                          : (_selectedFilterIndex == 1 ? 1 : 5),
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
                          label = 'H${value.toInt()}';
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
                    spots: _feedData,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: DarkTheme.statusWarning,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: DarkTheme.statusWarning,
                          strokeWidth: 2,
                          strokeColor: DarkTheme.deepForestBlack,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          DarkTheme.statusWarning.withValues(alpha: 0.25),
                          DarkTheme.statusWarning.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                // Warning line at 2kg
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 2,
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
                        labelResolver: (_) => 'Batas Rendah',
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
                          '${spot.y.toStringAsFixed(1)} kg',
                          const TextStyle(
                            color: DarkTheme.statusWarning,
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

  Widget _buildWaterChart() {
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
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.lightBlueAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Status Air', style: DarkTheme.controlTitle),
                  Text('Level Air Minum', style: DarkTheme.controlSubtitle),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Penuh', DarkTheme.neonGreen),
              const SizedBox(width: 16),
              _buildLegendItem('Normal', DarkTheme.paleGreen),
              const SizedBox(width: 16),
              _buildLegendItem('Rendah', DarkTheme.statusWarning),
            ],
          ),
          const SizedBox(height: 16),

          // Bar Chart
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: 4,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
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
                      reservedSize: 50,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        String label = '';
                        switch (value.toInt()) {
                          case 3:
                            label = 'Penuh';
                            break;
                          case 2:
                            label = 'Normal';
                            break;
                          case 1:
                            label = 'Rendah';
                            break;
                          case 0:
                            label = 'Habis';
                            break;
                        }
                        return Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10,
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
                barGroups: _waterData,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: DarkTheme.deepForestBlack.withValues(
                      alpha: 0.9,
                    ),
                    tooltipRoundedRadius: 10,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String status = '';
                      switch (rod.toY.toInt()) {
                        case 3:
                          status = 'Penuh';
                          break;
                        case 2:
                          status = 'Normal';
                          break;
                        case 1:
                          status = 'Rendah';
                          break;
                        default:
                          status = 'Habis';
                      }
                      return BarTooltipItem(
                        status,
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: DarkTheme.paleGreen),
        ),
      ],
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
        const SizedBox(height: 12),
        Row(
          children: [
            // Average Feed Card
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.grain_rounded,
                label: 'Rata-rata Pakan',
                value: '${_averageFeed.toStringAsFixed(1)} kg',
                iconColor: DarkTheme.statusWarning,
              ),
            ),
            const SizedBox(width: 12),
            // Water Status Card
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.water_drop_rounded,
                label: 'Status Air',
                value: 'Normal',
                iconColor: Colors.lightBlueAccent,
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
