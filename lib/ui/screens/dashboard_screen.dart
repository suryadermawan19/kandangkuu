import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kandangku/models/sensor_model.dart';
import 'package:kandangku/services/firebase_service.dart';
import 'package:kandangku/ui/widgets/clean_sensor_card.dart';
import 'package:kandangku/ui/widgets/vision_card.dart';
import 'package:kandangku/ui/widgets/analytics_chart.dart';
import 'package:kandangku/ui/widgets/safe_control_panel.dart';
import 'package:kandangku/ui/theme/app_theme.dart';

/// Legacy Dashboard Screen (Light Theme)
/// Now with stale data protection matching DarkDashboardScreen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // History data
  List<Map<String, dynamic>> _historyData = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final service = Provider.of<FirebaseService>(context, listen: false);
    final data = await service.getTelemetryHistory();
    if (mounted) {
      setState(() {
        _historyData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access sensor data from Provider (Stream)
    final sensorData = Provider.of<SensorModel>(context);
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.agriculture, color: AppTheme.statusGreen, size: 28),
            const SizedBox(width: 12),
            Text(
              'Kandangku',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: AppTheme.textPrimary,
              ),
            ),
            // Connection status indicator
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sensorData.isOnline
                    ? AppTheme.statusGreen
                    : AppTheme.statusRed,
                boxShadow: [
                  BoxShadow(
                    color:
                        (sensorData.isOnline
                                ? AppTheme.statusGreen
                                : AppTheme.statusRed)
                            .withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHistory,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stale Data Warning Banner (Task #4)
            if (sensorData.isStale) _buildStaleWarningBanner(sensorData),

            // Vision Section
            VisionCard(
              imageUrl: sensorData.imagePath.isNotEmpty
                  ? sensorData.imagePath
                  : null,
              visionScore: sensorData.visionScore,
            ),
            const SizedBox(height: 24),

            // Sensor Grid with stale dimming
            Opacity(
              opacity: sensorData.isStale ? 0.6 : 1.0,
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.95,
                children: [
                  CleanSensorCard(
                    icon: Icons.thermostat,
                    label: 'Suhu',
                    value: sensorData.temperature.toStringAsFixed(1),
                    unit: '°C',
                    statusColor: AppTheme.getTemperatureStatusColor(
                      sensorData.temperature,
                    ),
                    statusText: sensorData.temperature > 30
                        ? 'TINGGI'
                        : (sensorData.temperature < 24 ? 'RENDAH' : 'NORMAL'),
                    isCritical:
                        sensorData.temperature > 32 ||
                        sensorData.temperature < 22,
                  ),
                  CleanSensorCard(
                    icon: Icons.water_drop,
                    label: 'Kelembapan',
                    value: sensorData.humidity.toStringAsFixed(1),
                    unit: '%',
                    statusColor: AppTheme.getHumidityStatusColor(
                      sensorData.humidity,
                    ),
                    statusText:
                        (sensorData.humidity > 70 || sensorData.humidity < 45)
                        ? 'CHECK'
                        : 'OK',
                  ),
                  CleanSensorCard(
                    icon: Icons.air,
                    label: 'Amonia',
                    value: sensorData.ammonia.toStringAsFixed(1),
                    unit: 'ppm',
                    statusColor: AppTheme.getAmmoniaStatusColor(
                      sensorData.ammonia,
                    ),
                    statusText: sensorData.ammonia > 20
                        ? 'BAHAYA'
                        : (sensorData.ammonia > 15 ? 'AWAS' : 'AMAN'),
                    isCritical: sensorData.ammonia > 20,
                  ),
                  CleanSensorCard(
                    icon: Icons.scale,
                    label: 'Berat Pakan',
                    value: sensorData.feedWeight.toStringAsFixed(1),
                    unit: 'g',
                    statusColor: AppTheme.getFeedWeightStatusColor(
                      sensorData.feedWeight,
                    ),
                    statusText: sensorData.feedWeight < 10
                        ? 'ISI ULANG'
                        : (sensorData.feedWeight < 20 ? 'RENDAH' : 'NORMAL'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Water Level (Full Width)
            Opacity(
              opacity: sensorData.isStale ? 0.6 : 1.0,
              child: CleanSensorCard(
                icon: Icons.local_drink,
                label: 'Level Air',
                value: sensorData.waterLevel,
                statusColor: AppTheme.getWaterLevelStatusColor(
                  sensorData.waterLevel,
                ),
                statusText: sensorData.waterLevel.toUpperCase(),
                isCritical: sensorData.waterLevel.toLowerCase() == 'kosong',
              ),
            ),
            const SizedBox(height: 24),

            // Safe Control Panel - DISABLED when stale (Task #4)
            _buildControlPanel(sensorData, firebaseService),

            const SizedBox(height: 24),

            // Analytics Chart
            AnalyticsChart(historyData: _historyData),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  /// Stale data warning banner - shows when device is offline
  Widget _buildStaleWarningBanner(SensorModel sensorData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.statusRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.statusRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: AppTheme.statusRed, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Koneksi Terputus',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.statusRed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Data terakhir: ${sensorData.timeSinceUpdate}',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Control panel with stale data protection
  Widget _buildControlPanel(
    SensorModel sensorData,
    FirebaseService firebaseService,
  ) {
    // Show warning if trying to control while offline
    void showOfflineWarning() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Kontrol dinonaktifkan - Perangkat offline'),
              ),
            ],
          ),
          backgroundColor: AppTheme.statusRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Opacity(
          opacity: sensorData.isStale ? 0.5 : 1.0,
          child: SafeControlPanel(
            isAutoMode: sensorData.isAutoMode,
            isFanOn: sensorData.isFanOn,
            isHeaterOn: sensorData.isHeaterOn,
            onAutoModeChanged: sensorData.isStale
                ? (_) => showOfflineWarning()
                : (val) => firebaseService.updateActuatorState(isAutoMode: val),
            onFanChanged: sensorData.isStale
                ? (_) => showOfflineWarning()
                : (val) => firebaseService.updateActuatorState(isFanOn: val),
            onHeaterChanged: sensorData.isStale
                ? (_) => showOfflineWarning()
                : (val) => firebaseService.updateActuatorState(isHeaterOn: val),
          ),
        ),
        // Overlay lock icon when stale
        if (sensorData.isStale)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.statusRed.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }
}
