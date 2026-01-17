import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:kandangku/services/firebase_service.dart';
import 'package:kandangku/ui/theme/dark_theme.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// History Screen - "Riwayat Sensor" for PoultryVision (Kandangku)
/// Dark Industrial Green Theme with fl_chart visualizations
/// Now fetches REAL data from Firestore telemetry_history collection
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Selected time filter index: 0 = 24 Jam, 1 = 7 Hari, 2 = 30 Hari
  int _selectedFilterIndex = 0;

  // Selected metric index: 0 = Suhu, 1 = Kelembapan, 2 = Amonia, 3 = Pakan, 4 = Air
  int _selectedMetricIndex = 0;

  // Filter options in Bahasa Indonesia
  final List<String> _filterOptions = ['24 Jam', '7 Hari', '30 Hari'];

  // Hours for each filter
  final List<int> _filterHours = [24, 168, 720]; // 24h, 7 days, 30 days

  // Metric options in Bahasa Indonesia
  final List<Map<String, dynamic>> _metricOptions = [
    {'label': 'Suhu', 'icon': Icons.thermostat_rounded},
    {'label': 'Kelembapan', 'icon': Icons.opacity},
    {'label': 'Amonia', 'icon': Icons.cloud_outlined},
    {'label': 'Pakan', 'icon': Icons.grain_rounded},
    {'label': 'Air', 'icon': Icons.water_drop_rounded},
  ];

  // Real data from Firestore
  List<Map<String, dynamic>> _historyData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) _fetchHistoryData();
    });
  }

  /// Fetch history data based on selected filter
  Future<void> _fetchHistoryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firebaseService = Provider.of<FirebaseService>(
        context,
        listen: false,
      );
      final hours = _filterHours[_selectedFilterIndex];
      final data = await firebaseService.getTelemetryHistoryForRange(hours);

      if (mounted) {
        setState(() {
          _historyData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Convert history data to FlSpot for line charts
  /// Groups data by time buckets for cleaner visualization
  List<FlSpot> _getLineChartData(String field) {
    if (_historyData.isEmpty) return [];

    final spots = <FlSpot>[];
    final now = DateTime.now();

    for (var i = 0; i < _historyData.length; i++) {
      final entry = _historyData[i];
      final timestamp = entry['timestamp'] as DateTime?;
      final value = (entry[field] as num?)?.toDouble() ?? 0;

      if (timestamp != null) {
        double x;
        if (_selectedFilterIndex == 0) {
          // 24 hours: x = hours ago
          x = 24 - now.difference(timestamp).inMinutes / 60.0;
        } else if (_selectedFilterIndex == 1) {
          // 7 days: x = days (0-6)
          x = 7 - now.difference(timestamp).inHours / 24.0;
        } else {
          // 30 days: x = days (0-30)
          x = 30 - now.difference(timestamp).inHours / 24.0;
        }
        if (x >= 0) {
          spots.add(FlSpot(x, value));
        }
      }
    }

    // Sort by x value for proper line rendering
    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  /// Convert history data to BarChartGroupData for ammonia
  List<BarChartGroupData> _getAmmoniaBarData() {
    if (_historyData.isEmpty) return [];

    // Group data into buckets
    final bucketCount = _selectedFilterIndex == 0
        ? 6
        : (_selectedFilterIndex == 1 ? 7 : 4);
    final buckets = List<List<double>>.generate(bucketCount, (_) => []);

    final now = DateTime.now();
    final totalHours = _filterHours[_selectedFilterIndex];

    for (final entry in _historyData) {
      final timestamp = entry['timestamp'] as DateTime?;
      final ammonia = (entry['ammonia'] as num?)?.toDouble() ?? 0;

      if (timestamp != null) {
        final hoursAgo = now.difference(timestamp).inHours;
        final bucketIndex = ((totalHours - hoursAgo) * bucketCount / totalHours)
            .floor()
            .clamp(0, bucketCount - 1);
        buckets[bucketIndex].add(ammonia);
      }
    }

    // Calculate averages and create bars
    return List.generate(bucketCount, (i) {
      final avg = buckets[i].isEmpty
          ? 0.0
          : buckets[i].reduce((a, b) => a + b) / buckets[i].length;
      return _makeAmmoniaBar(i, avg);
    });
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

  /// Convert history data to BarChartGroupData for water level
  List<BarChartGroupData> _getWaterBarData() {
    if (_historyData.isEmpty) return [];

    // Group data into buckets
    final bucketCount = _selectedFilterIndex == 0
        ? 6
        : (_selectedFilterIndex == 1 ? 7 : 4);
    final buckets = List<List<String>>.generate(bucketCount, (_) => []);

    final now = DateTime.now();
    final totalHours = _filterHours[_selectedFilterIndex];

    for (final entry in _historyData) {
      final timestamp = entry['timestamp'] as DateTime?;
      final waterLevel = (entry['water_level'] as String?) ?? 'Unknown';

      if (timestamp != null) {
        final hoursAgo = now.difference(timestamp).inHours;
        final bucketIndex = ((totalHours - hoursAgo) * bucketCount / totalHours)
            .floor()
            .clamp(0, bucketCount - 1);
        buckets[bucketIndex].add(waterLevel);
      }
    }

    // Calculate most common level and create bars
    return List.generate(bucketCount, (i) {
      double level = 2; // Default to Normal
      if (buckets[i].isNotEmpty) {
        // Count occurrences
        final counts = <String, int>{};
        for (final wl in buckets[i]) {
          counts[wl] = (counts[wl] ?? 0) + 1;
        }
        final mostCommon = counts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        level = _waterLevelToNumber(mostCommon);
      }
      return _makeWaterBar(i, level);
    });
  }

  double _waterLevelToNumber(String level) {
    switch (level.toLowerCase()) {
      case 'full':
      case 'penuh':
        return 3;
      case 'normal':
        return 2;
      case 'low':
      case 'rendah':
        return 1;
      case 'empty':
      case 'habis':
        return 0;
      default:
        return 2;
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

  // --- Summary Stats Calculation from real data ---
  double get _averageTemperature {
    if (_historyData.isEmpty) return 0;
    final temps = _historyData
        .map((e) => (e['temperature'] as num?)?.toDouble() ?? 0)
        .where((t) => t > 0)
        .toList();
    if (temps.isEmpty) return 0;
    return temps.reduce((a, b) => a + b) / temps.length;
  }

  double get _peakAmmonia {
    if (_historyData.isEmpty) return 0;
    final ammonias = _historyData
        .map((e) => (e['ammonia'] as num?)?.toDouble() ?? 0)
        .toList();
    if (ammonias.isEmpty) return 0;
    return ammonias.reduce((a, b) => a > b ? a : b);
  }

  double get _averageFeed {
    if (_historyData.isEmpty) return 0;
    final feeds = _historyData
        .map((e) => (e['feed_weight'] as num?)?.toDouble() ?? 0)
        .where((f) => f > 0)
        .toList();
    if (feeds.isEmpty) return 0;
    return feeds.reduce((a, b) => a + b) / feeds.length;
  }

  double get _averageHumidity {
    if (_historyData.isEmpty) return 0;
    final humidities = _historyData
        .map((e) => (e['humidity'] as num?)?.toDouble() ?? 0)
        .where((h) => h > 0)
        .toList();
    if (humidities.isEmpty) return 0;
    return humidities.reduce((a, b) => a + b) / humidities.length;
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
            _buildChartContent(),
            const SizedBox(height: 24),

            // Summary Cards
            if (!_isLoading && _errorMessage == null) ...[
              _buildSummaryCards(),
              const SizedBox(height: 32),
            ],
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
        children: [
          const Text('Riwayat Sensor', style: DarkTheme.headerTitle),
          const SizedBox(height: 2),
          Text(
            _historyData.isNotEmpty
                ? '${_historyData.length} data tersedia'
                : 'Analisis tren sensor kandang',
            style: DarkTheme.headerSubtitle,
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      DarkTheme.neonGreen.withValues(alpha: 0.7),
                    ),
                  ),
                )
              : const Icon(Icons.refresh_rounded, color: DarkTheme.paleGreen),
          onPressed: _isLoading ? null : _fetchHistoryData,
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
              onTap: () {
                if (_selectedFilterIndex != index) {
                  setState(() => _selectedFilterIndex = index);
                  _fetchHistoryData(); // Fetch new data when filter changes
                }
              },
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
                        fontSize: 11,
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

  Widget _buildChartContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_historyData.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSelectedChart();
  }

  Widget _buildLoadingState() {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: DarkTheme.cardDecoration,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  DarkTheme.neonGreen.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Memuat data riwayat...',
              style: DarkTheme.controlSubtitle.copyWith(
                color: DarkTheme.paleGreen.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: DarkTheme.cardDecoration,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: DarkTheme.statusDanger.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DarkTheme.statusDanger,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              style: DarkTheme.controlSubtitle.copyWith(
                color: DarkTheme.paleGreen.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _fetchHistoryData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: TextButton.styleFrom(foregroundColor: DarkTheme.neonGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: DarkTheme.cardDecoration,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 48,
              color: DarkTheme.paleGreen.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum Ada Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DarkTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data riwayat sensor belum tersedia\nuntuk periode ${_filterOptions[_selectedFilterIndex]}',
              style: DarkTheme.controlSubtitle.copyWith(
                color: DarkTheme.paleGreen.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChart() {
    switch (_selectedMetricIndex) {
      case 0:
        return _buildTemperatureChart();
      case 1:
        return _buildHumidityChart();
      case 2:
        return _buildAmmoniaChart();
      case 3:
        return _buildFeedChart();
      case 4:
        return _buildWaterChart();
      default:
        return _buildTemperatureChart();
    }
  }

  Widget _buildTemperatureChart() {
    final data = _getLineChartData('temperature');
    return _buildLineChartCard(
      icon: Icons.thermostat_rounded,
      title: 'Grafik Suhu',
      subtitle: 'Suhu (°C)',
      data: data,
      minY: 20,
      maxY: 40,
      yInterval: 5,
      thresholdY: 30,
      thresholdLabel: 'Batas 30°C',
      tooltipSuffix: '°C',
    );
  }

  Widget _buildHumidityChart() {
    final data = _getLineChartData('humidity');
    return _buildLineChartCard(
      icon: Icons.opacity,
      title: 'Grafik Kelembapan',
      subtitle: 'Kelembapan (%)',
      data: data,
      minY: 0,
      maxY: 100,
      yInterval: 20,
      tooltipSuffix: '%',
      lineColor: const Color(0xFF64B5F6), // Blue for humidity
    );
  }

  Widget _buildFeedChart() {
    final data = _getLineChartData('feed_weight');
    return _buildLineChartCard(
      icon: Icons.grain_rounded,
      title: 'Grafik Pakan',
      subtitle: 'Sisa Pakan (g)',
      data: data,
      minY: 0,
      maxY: 1000,
      yInterval: 200,
      tooltipSuffix: ' g',
      lineColor: DarkTheme.statusWarning, // Orange for feed
    );
  }

  Widget _buildLineChartCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<FlSpot> data,
    required double minY,
    required double maxY,
    required double yInterval,
    required String tooltipSuffix,
    double? thresholdY,
    String? thresholdLabel,
    Color lineColor = DarkTheme.neonGreen,
  }) {
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
                  color: lineColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: lineColor, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: DarkTheme.controlTitle),
                  Text(subtitle, style: DarkTheme.controlSubtitle),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Line Chart
          SizedBox(
            height: 200,
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada data',
                      style: DarkTheme.controlSubtitle.copyWith(
                        color: DarkTheme.paleGreen.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: minY,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yInterval,
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
                            interval: yInterval,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
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
                              final now = DateTime.now();

                              if (_selectedFilterIndex == 0) {
                                // 24 Hours View: value 0..24 (24 is now)
                                final time = now.subtract(
                                  Duration(
                                    minutes: ((24 - value) * 60).toInt(),
                                  ),
                                );
                                label = DateFormat('HH:mm').format(time);
                              } else if (_selectedFilterIndex == 1) {
                                // 7 Days View: value 0..7 (7 is today)
                                final time = now.subtract(
                                  Duration(days: (7 - value).toInt()),
                                );
                                label = DateFormat('E', 'id_ID').format(time);
                              } else {
                                // 30 Days View: value 0..30 (30 is today)
                                final time = now.subtract(
                                  Duration(days: (30 - value).toInt()),
                                );
                                label = DateFormat('d/M').format(time);
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
                          spots: data,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: lineColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                lineColor.withValues(alpha: 0.3),
                                lineColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                      extraLinesData: thresholdY != null
                          ? ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: thresholdY,
                                  color: DarkTheme.statusDanger,
                                  strokeWidth: 2,
                                  dashArray: [8, 4],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.only(
                                      right: 5,
                                      bottom: 5,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: DarkTheme.statusDanger,
                                    ),
                                    labelResolver: (_) => thresholdLabel ?? '',
                                  ),
                                ),
                              ],
                            )
                          : null,
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
                                '${spot.y.toStringAsFixed(1)}$tooltipSuffix',
                                TextStyle(
                                  color: lineColor,
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
    final data = _getAmmoniaBarData();
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grafik Amonia', style: DarkTheme.controlTitle),
                  Text('Level Amonia (ppm)', style: DarkTheme.controlSubtitle),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bar Chart
          SizedBox(
            height: 200,
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada data',
                      style: DarkTheme.controlSubtitle.copyWith(
                        color: DarkTheme.paleGreen.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: 50,
                      barGroups: data,
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
                            reservedSize: 40,
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
                                final hours = [
                                  '00:00',
                                  '04:00',
                                  '08:00',
                                  '12:00',
                                  '16:00',
                                  '20:00',
                                ];
                                if (value.toInt() < hours.length) {
                                  label = hours[value.toInt()];
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
                              padding: const EdgeInsets.only(
                                right: 5,
                                bottom: 5,
                              ),
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
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${rod.toY.toStringAsFixed(1)} ppm',
                              const TextStyle(
                                color: DarkTheme.paleGreen,
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

  Widget _buildWaterChart() {
    final data = _getWaterBarData();
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
                  color: const Color(0xFF64B5F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Color(0xFF64B5F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grafik Level Air', style: DarkTheme.controlTitle),
                  Text('Status Air Minum', style: DarkTheme.controlSubtitle),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(DarkTheme.neonGreen, 'Penuh'),
              const SizedBox(width: 16),
              _buildLegendItem(DarkTheme.paleGreen, 'Normal'),
              const SizedBox(width: 16),
              _buildLegendItem(DarkTheme.statusWarning, 'Rendah'),
              const SizedBox(width: 16),
              _buildLegendItem(DarkTheme.statusDanger, 'Habis'),
            ],
          ),
          const SizedBox(height: 16),

          // Bar Chart
          SizedBox(
            height: 180,
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada data',
                      style: DarkTheme.controlSubtitle.copyWith(
                        color: DarkTheme.paleGreen.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: 4,
                      barGroups: data,
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
                                final hours = [
                                  '00:00',
                                  '04:00',
                                  '08:00',
                                  '12:00',
                                  '16:00',
                                  '20:00',
                                ];
                                if (value.toInt() < hours.length) {
                                  label = hours[value.toInt()];
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
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: DarkTheme.deepForestBlack.withValues(
                            alpha: 0.9,
                          ),
                          tooltipRoundedRadius: 10,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            String levelText = '';
                            switch (rod.toY.toInt()) {
                              case 3:
                                levelText = 'Penuh';
                                break;
                              case 2:
                                levelText = 'Normal';
                                break;
                              case 1:
                                levelText = 'Rendah';
                                break;
                              default:
                                levelText = 'Habis';
                            }
                            return BarTooltipItem(
                              levelText,
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

  Widget _buildLegendItem(Color color, String label) {
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
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: DarkTheme.paleGreen),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ringkasan', style: DarkTheme.sectionTitle),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.thermostat_rounded,
                label: 'Rata-rata Suhu',
                value: '${_averageTemperature.toStringAsFixed(1)}°C',
                color: DarkTheme.neonGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.opacity,
                label: 'Rata-rata Kelembapan',
                value: '${_averageHumidity.toStringAsFixed(0)}%',
                color: const Color(0xFF64B5F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.cloud_outlined,
                label: 'Puncak Amonia',
                value: '${_peakAmmonia.toStringAsFixed(0)} ppm',
                color: _peakAmmonia > 20
                    ? DarkTheme.statusWarning
                    : DarkTheme.paleGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.grain_rounded,
                label: 'Rata-rata Pakan',
                value: '${_averageFeed.toStringAsFixed(0)} g',
                color: DarkTheme.statusWarning,
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
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DarkTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: DarkTheme.controlSubtitle),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: DarkTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
