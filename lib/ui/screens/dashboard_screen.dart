import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kandangku/models/sensor_model.dart';
import 'package:kandangku/services/firebase_service.dart';
import 'package:kandangku/ui/widgets/monitoring_card.dart';
import 'package:kandangku/ui/widgets/vision_card.dart';
import 'package:kandangku/ui/widgets/analytics_chart.dart';

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
      backgroundColor: const Color(0xFF121212), // Dark Monitor BG
      appBar: AppBar(
        title: const Text(
          'PoultryVision',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchHistory),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 20),

            // Sensor Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                MonitoringCard(
                  icon: FontAwesomeIcons.temperatureHigh,
                  label: 'Temperature',
                  value: sensorData.temperature.toStringAsFixed(1),
                  unit: '°C',
                  color: Colors.orange,
                  status: sensorData.temperature > 30 ? 'High' : 'OK',
                ),
                MonitoringCard(
                  icon: FontAwesomeIcons.droplet,
                  label: 'Humidity',
                  value: sensorData.humidity.toStringAsFixed(1),
                  unit: '%',
                  color: Colors.blue,
                ),
                MonitoringCard(
                  icon: FontAwesomeIcons.wind,
                  label: 'Ammonia',
                  value: sensorData.ammonia.toStringAsFixed(1),
                  unit: 'ppm',
                  color: Colors.purple,
                  status: sensorData.ammonia > 20 ? 'Critical' : 'Safe',
                ),
                MonitoringCard(
                  icon: FontAwesomeIcons.weightHanging,
                  label: 'Feed Weight',
                  value: sensorData.feedWeight.toStringAsFixed(1),
                  unit: 'kg',
                  color: Colors.brown,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Water Level (Full Width)
            MonitoringCard(
              icon: FontAwesomeIcons.glassWater,
              label: 'Water Level Status',
              value: sensorData.waterLevel,
              color: Colors.cyan,
              status: sensorData.waterLevel,
            ),
            const SizedBox(height: 24),

            // Actuators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Actuator Controls',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // System Mode Switch
                Row(
                  children: [
                    Text(
                      sensorData.isAutoMode ? 'Auto Mode' : 'Manual Mode',
                      style: TextStyle(
                        color: sensorData.isAutoMode
                            ? Colors.blue
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: sensorData.isAutoMode,
                      onChanged: (val) =>
                          firebaseService.updateActuatorState(isAutoMode: val),
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Conditional Controls: Disabled if Auto Mode is ON
                  IgnorePointer(
                    ignoring: sensorData.isAutoMode,
                    child: Opacity(
                      opacity: sensorData.isAutoMode ? 0.5 : 1.0,
                      child: Column(
                        children: [
                          _buildSwitchRow(
                            'Exhaust Fan',
                            sensorData.isFanOn,
                            (val) => firebaseService.updateActuatorState(
                              isFanOn: val,
                            ),
                            FontAwesomeIcons.fan,
                            Colors.blue,
                          ),
                          const Divider(color: Colors.grey),
                          _buildSwitchRow(
                            'Heater',
                            sensorData.isHeaterOn,
                            (val) => firebaseService.updateActuatorState(
                              isHeaterOn: val,
                            ),
                            FontAwesomeIcons.fire,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Analytics
            AnalyticsChart(historyData: _historyData),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow(
    String label,
    bool value,
    Function(bool) onChanged,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const Spacer(),
        Switch(value: value, onChanged: onChanged, activeColor: color),
      ],
    );
  }
}
