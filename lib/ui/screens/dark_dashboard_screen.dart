import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kandangku/models/sensor_model.dart';
import 'package:kandangku/services/firebase_service.dart';
import 'package:kandangku/ui/theme/dark_theme.dart';

class DarkDashboardScreen extends StatefulWidget {
  const DarkDashboardScreen({super.key});

  @override
  State<DarkDashboardScreen> createState() => _DarkDashboardScreenState();
}

class _DarkDashboardScreenState extends State<DarkDashboardScreen>
    with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  late AnimationController _pulseController;
  late AnimationController _livePulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _livePulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _livePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensorData = Provider.of<SensorModel>(context);
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );

    return Scaffold(
      backgroundColor: DarkTheme.backgroundPrimary,
      appBar: _buildHeader(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metric Grid
            _buildMetricGrid(sensorData),
            const SizedBox(height: 20),

            // Vision Card (Camera Feed)
            _buildVisionCard(sensorData),
            const SizedBox(height: 24),

            // Control Section
            _buildControlSection(sensorData, firebaseService),
            const SizedBox(height: 100), // Space for bottom nav
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: DarkTheme.backgroundPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: DarkTheme.textPrimary),
        onPressed: () {},
      ),
      title: Column(
        children: [
          const Text('Kandang 01', style: DarkTheme.headerTitle),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing green dot
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DarkTheme.neonGreen.withValues(
                        alpha: 0.5 + (_pulseController.value * 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DarkTheme.neonGreen.withValues(
                            alpha: 0.3 + (_pulseController.value * 0.3),
                          ),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              const Text('Terpantau 2m lalu', style: DarkTheme.headerSubtitle),
            ],
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: DarkTheme.textPrimary,
              ),
              onPressed: () {},
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9500),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricGrid(SensorModel sensorData) {
    return Row(
      children: [
        // Temperature Card
        Expanded(
          child: _buildMetricCard(
            icon: Icons.thermostat_rounded,
            label: 'Suhu Kandang',
            value: '${sensorData.temperature.toStringAsFixed(0)}°C',
            statusText: DarkTheme.getTemperatureStatusText(
              sensorData.temperature,
            ),
            statusColor: DarkTheme.getTemperatureStatus(sensorData.temperature),
          ),
        ),
        const SizedBox(width: 12),
        // Ammonia Card
        Expanded(
          child: _buildMetricCard(
            icon: Icons.cloud_outlined,
            label: 'Kadar Amonia',
            value: '${sensorData.ammonia.toStringAsFixed(0)} ppm',
            statusText: DarkTheme.getAmmoniaStatusText(sensorData.ammonia),
            statusColor: DarkTheme.getAmmoniaStatus(sensorData.ammonia),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String statusText,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DarkTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Row with Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DarkTheme.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: DarkTheme.neonGreen, size: 24),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(statusText, style: DarkTheme.badgeText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Label
          Text(label, style: DarkTheme.sensorLabel),
          const SizedBox(height: 6),
          // Value
          Text(value, style: DarkTheme.sensorValue),
        ],
      ),
    );
  }

  Widget _buildVisionCard(SensorModel sensorData) {
    return Container(
      decoration: DarkTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Camera Feed Area (16:9)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Placeholder/Stream Image
                sensorData.imagePath.isNotEmpty
                    ? Image.network(
                        sensorData.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),

                // LIVE Badge (Top Left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: AnimatedBuilder(
                    animation: _livePulseController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: DarkTheme.statusDanger.withValues(
                            alpha: 0.85 + (_livePulseController.value * 0.15),
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: DarkTheme.statusDanger.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Vision Score (Bottom Right - Glassmorphic)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: DarkTheme.deepForestBlack.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: DarkTheme.neonGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Skor Visi: ${sensorData.visionScore} (${DarkTheme.getVisionStatusText(sensorData.visionScore)})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DarkTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pantauan Langsung',
                        style: DarkTheme.controlTitle,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: DarkTheme.neonGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: DarkTheme.neonGreen.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Deteksi AI Aktif',
                            style: DarkTheme.controlSubtitle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.fullscreen_rounded,
                  color: DarkTheme.paleGreen,
                  size: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: DarkTheme.cardBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_rounded,
              size: 48,
              color: DarkTheme.neonGreen.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Menghubungkan ke kamera...',
              style: DarkTheme.controlSubtitle.copyWith(
                color: DarkTheme.paleGreen.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlSection(SensorModel sensorData, FirebaseService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        const Text('Kontrol Lingkungan', style: DarkTheme.sectionTitle),
        const SizedBox(height: 16),

        // Auto Mode Tile
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF162b1a),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: sensorData.isAutoMode
                  ? DarkTheme.neonGreen.withValues(alpha: 0.4)
                  : DarkTheme.cardBorder,
            ),
          ),
          child: Row(
            children: [
              // Robot Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DarkTheme.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: DarkTheme.neonGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mode Otomatis', style: DarkTheme.controlTitle),
                    const SizedBox(height: 4),
                    Text(
                      sensorData.isAutoMode
                          ? 'Sistem mengendalikan alat'
                          : 'Kendali manual aktif',
                      style: DarkTheme.controlSubtitle,
                    ),
                  ],
                ),
              ),
              // Switch
              Transform.scale(
                scale: 1.1,
                child: Switch(
                  value: sensorData.isAutoMode,
                  onChanged: (val) {
                    service.updateActuatorState(isAutoMode: val);
                  },
                  activeColor: DarkTheme.neonGreen,
                  activeTrackColor: DarkTheme.neonGreen.withValues(alpha: 0.4),
                  inactiveThumbColor: DarkTheme.textDisabled,
                  inactiveTrackColor: DarkTheme.textDisabled.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Actuator Grid (Fan & Heater)
        Row(
          children: [
            // Fan Button
            Expanded(
              child: _buildActuatorButton(
                icon: Icons.mode_fan_off_rounded,
                activeIcon: Icons.wind_power_rounded,
                label: 'Kipas',
                isActive: sensorData.isFanOn,
                isDisabled: sensorData.isAutoMode,
                onTap: () {
                  if (!sensorData.isAutoMode) {
                    service.updateActuatorState(isFanOn: !sensorData.isFanOn);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            // Heater Button
            Expanded(
              child: _buildActuatorButton(
                icon: Icons.thermostat_auto_outlined,
                activeIcon: Icons.local_fire_department_rounded,
                label: 'Pemanas',
                isActive: sensorData.isHeaterOn,
                isDisabled: sensorData.isAutoMode,
                onTap: () {
                  if (!sensorData.isAutoMode) {
                    service.updateActuatorState(
                      isHeaterOn: !sensorData.isHeaterOn,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActuatorButton({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    final double opacity = isDisabled ? 0.5 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isActive && !isDisabled
                ? DarkTheme.neonGreen.withValues(alpha: 0.15)
                : DarkTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive && !isDisabled
                  ? DarkTheme.neonGreen.withValues(alpha: 0.5)
                  : DarkTheme.cardBorder,
              width: isActive && !isDisabled ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Icon(
                    isActive ? activeIcon : icon,
                    color: isActive && !isDisabled
                        ? DarkTheme.neonGreen
                        : DarkTheme.paleGreen,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: DarkTheme.controlTitle.copyWith(
                      color: isActive && !isDisabled
                          ? DarkTheme.textPrimary
                          : DarkTheme.paleGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive ? 'Menyala' : 'Mati',
                    style: DarkTheme.controlSubtitle.copyWith(
                      color: isActive && !isDisabled
                          ? DarkTheme.neonGreen
                          : DarkTheme.textDisabled,
                    ),
                  ),
                ],
              ),
              // Lock icon when disabled
              if (isDisabled)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: DarkTheme.paleGreen.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: DarkTheme.navBackground,
        border: Border(top: BorderSide(color: DarkTheme.cardBorder, width: 1)),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (index) => setState(() => _currentNavIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: DarkTheme.navActive,
          unselectedItemColor: DarkTheme.navInactive,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded),
              activeIcon: Icon(Icons.warning_rounded),
              label: 'Peringatan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              activeIcon: Icon(Icons.history_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}
