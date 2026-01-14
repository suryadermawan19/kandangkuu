import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kandangku/models/sensor_model.dart';
import 'package:kandangku/services/firebase_service.dart';
import 'package:kandangku/ui/widgets/clean_sensor_card.dart';
import 'package:kandangku/ui/widgets/vision_card.dart';
import 'package:kandangku/ui/widgets/analytics_chart.dart';
import 'package:kandangku/ui/widgets/safe_control_panel.dart';
import 'package:kandangku/ui/theme/app_theme.dart';

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
              'PoultryVision',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: AppTheme.textPrimary,
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
            // Vision Section
            VisionCard(
              imageUrl: sensorData.imagePath.isNotEmpty
                  ? sensorData.imagePath
                  : null,
              visionScore: sensorData.visionScore,
            ),
            const SizedBox(height: 24),

            // Sensor Grid
            GridView.count(
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
                  unit: 'kg',
                  statusColor: AppTheme.getFeedWeightStatusColor(
                    sensorData.feedWeight,
                  ),
                  statusText: sensorData.feedWeight < 10
                      ? 'ISI ULANG'
                      : (sensorData.feedWeight < 20 ? 'RENDAH' : 'NORMAL'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Water Level (Full Width)
            CleanSensorCard(
              icon: Icons.local_drink,
              label: 'Level Air',
              value: sensorData.waterLevel,
              statusColor: AppTheme.getWaterLevelStatusColor(
                sensorData.waterLevel,
              ),
              statusText: sensorData.waterLevel.toUpperCase(),
              isCritical: sensorData.waterLevel.toLowerCase() == 'kosong',
            ),
            const SizedBox(height: 24),

            // Safe Control Panel
            SafeControlPanel(
              isAutoMode: sensorData.isAutoMode,
              isFanOn: sensorData.isFanOn,
              isHeaterOn: sensorData.isHeaterOn,
              onAutoModeChanged: (val) =>
                  firebaseService.updateActuatorState(isAutoMode: val),
              onFanChanged: (val) =>
                  firebaseService.updateActuatorState(isFanOn: val),
              onHeaterChanged: (val) =>
                  firebaseService.updateActuatorState(isHeaterOn: val),
            ),

            const SizedBox(height: 24),

            // Analytics Chart
            AnalyticsChart(historyData: _historyData),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
