import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kandangku/models/sensor_model.dart';
import 'package:kandangku/services/firebase_service.dart';
import 'package:kandangku/ui/theme/dark_theme.dart';
import 'package:kandangku/ui/screens/history_screen.dart';
import 'package:kandangku/ui/screens/alerts_screen.dart';
import 'package:kandangku/ui/screens/settings_screen.dart';

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

  // UX Fix #2: Loading states for actuators
  bool _isFanLoading = false;
  bool _isHeaterLoading = false;
  bool _isAutoModeLoading = false;

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

    return StreamProvider<String>(
      create: (_) => firebaseService.getUserRoleStream(),
      initialData: 'viewer', // Default to safer viewer role
      child: Consumer<String>(
        builder: (context, userRole, child) {
          final isAdmin = userRole == 'admin';

          return Scaffold(
            backgroundColor: DarkTheme.backgroundPrimary,
            appBar: _buildHeader(sensorData, isAdmin),
            body: Column(
              children: [
                // UX Fix #1: Offline Banner (Cache or Stale)
                if (sensorData.isStale || sensorData.isFromCache)
                  _buildOfflineBanner(sensorData),

                // Role Banner (Viewer Mode)
                if (!isAdmin) _buildViewerBanner(),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Servo Status Banner (Active Dispensing)
                        _buildServoStatusBanner(sensorData),

                        // Metric Grid
                        _buildMetricGrid(sensorData),
                        const SizedBox(height: 20),

                        // Vision Card (Camera Feed)
                        _buildVisionCard(sensorData),
                        const SizedBox(height: 24),

                        // Logistik & Pakan Section (Manual Servo Controls)
                        _buildLogistikSection(
                          sensorData,
                          firebaseService,
                          isAdmin,
                        ),
                        const SizedBox(height: 24),

                        // Control Section
                        _buildControlSection(
                          sensorData,
                          firebaseService,
                          isAdmin,
                        ),
                        const SizedBox(height: 100), // Space for bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(),
          );
        },
      ),
    );
  }

  // ============ UX FIX #1: OFFLINE BANNER ============
  Widget _buildOfflineBanner(SensorModel sensorData) {
    // Determine the type of offline state
    final bool isAppOffline = sensorData.isFromCache;
    // If not using cache but data is stale, then device is offline
    // final bool isDeviceOffline = !isAppOffline && sensorData.isStale; // Unused, removing to fix lint

    final Color bannerColor = isAppOffline
        ? const Color(0xFFFFA000) // Amber for App Offline
        : DarkTheme.statusDanger; // Red for Device Offline

    final String title = isAppOffline
        ? 'Aplikasi Offline'
        : 'Perangkat Offline';

    final String message = isAppOffline
        ? 'Menampilkan data terakhir. Kontrol dinonaktifkan.'
        : 'Terputus sejak ${sensorData.timeSinceUpdate}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(
            color: bannerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Pulsing warning icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Icon(
                isAppOffline ? Icons.cloud_off_rounded : Icons.wifi_off_rounded,
                color: bannerColor.withValues(
                  alpha: 0.6 + (_pulseController.value * 0.4),
                ),
                size: 22,
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: bannerColor,
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: bannerColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Retry button
          TextButton.icon(
            onPressed: () {
              // Could trigger a manual refresh here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAppOffline
                        ? 'Memeriksa koneksi internet...'
                        : 'Mencoba panggil ulang perangkat...',
                  ),
                  backgroundColor: DarkTheme.cardBackground,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: TextButton.styleFrom(
              foregroundColor: bannerColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  // ============ ROLE BANNER ============
  Widget _buildViewerBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blueGrey.withValues(alpha: 0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.visibility_rounded, size: 16, color: Colors.blueGrey),
          SizedBox(width: 8),
          Text(
            'Mode Penonton (Hanya Lihat)',
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============ SERVO STATUS BANNER ============
  Widget _buildServoStatusBanner(SensorModel sensorData) {
    final isFillingFeed = sensorData.servoPakanTrigger;
    final isFillingWater = sensorData.servoAirTrigger;

    if (!isFillingFeed && !isFillingWater) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DarkTheme.neonGreen.withValues(alpha: 0.15),
            DarkTheme.neonGreen.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DarkTheme.neonGreen.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Feed dispensing indicator
          if (isFillingFeed)
            _buildServoIndicatorRow(
              icon: Icons.grain_rounded,
              text: 'Mengisi Pakan...',
            ),

          // Separator if both are active
          if (isFillingFeed && isFillingWater) const SizedBox(height: 10),

          // Water dispensing indicator
          if (isFillingWater)
            _buildServoIndicatorRow(
              icon: Icons.water_drop_rounded,
              text: 'Mengisi Air...',
            ),
        ],
      ),
    );
  }

  Widget _buildServoIndicatorRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        // Animated spinning icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DarkTheme.neonGreen.withValues(
                  alpha: 0.15 + (_pulseController.value * 0.1),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: DarkTheme.neonGreen, size: 22),
            );
          },
        ),
        const SizedBox(width: 14),
        // Status text
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DarkTheme.neonGreen,
            ),
          ),
        ),
        // Loading spinner
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              DarkTheme.neonGreen.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  // ============ LOGISTIK & PAKAN SECTION (Manual Servo Controls) ============
  Widget _buildLogistikSection(
    SensorModel sensorData,
    FirebaseService service,
    bool isAdmin,
  ) {
    final isAutoMode = sensorData.isAutoMode;
    final isFeedActive = sensorData.servoPakanTrigger;
    final isWaterActive = sensorData.servoAirTrigger;
    // Disable controls if stale OR using cached data (app offline)
    final isControlsDisabled = sensorData.isStale || sensorData.isFromCache;

    // Show low feed warning when servo is triggered or feed weight is critically low
    final bool isLowFeed = isFeedActive || sensorData.feedWeight < 100;
    final bool isLowWater = isWaterActive || sensorData.waterLevel == 'Habis';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        const Text('Logistik & Pakan', style: DarkTheme.sectionTitle),
        const SizedBox(height: 16),

        // Low feed/water warning banner
        if ((isLowFeed || isLowWater) && !isControlsDisabled)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: DarkTheme.statusDanger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: DarkTheme.statusDanger.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: DarkTheme.statusDanger,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLowFeed)
                        Text(
                          'Pakan hampir habis (${sensorData.feedWeight.toStringAsFixed(0)}g)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DarkTheme.statusDanger,
                          ),
                        ),
                      if (isLowWater)
                        Text(
                          'Air habis - perlu diisi ulang',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DarkTheme.statusDanger,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Disabled warning when in auto mode
        if (isAutoMode)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: DarkTheme.statusWarning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: DarkTheme.statusWarning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: DarkTheme.statusWarning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Matikan Mode Otomatis untuk kontrol manual',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: DarkTheme.statusWarning,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Manual Control Buttons
        Row(
          children: [
            // Isi Pakan Button
            Expanded(
              child: _buildManualServoButton(
                icon: Icons.restaurant_rounded,
                label: 'Isi Pakan',
                isActive: isFeedActive,
                isDisabled: isAutoMode || isControlsDisabled || !isAdmin,
                onTap: () => _handleManualFeed(service),
              ),
            ),
            const SizedBox(width: 12),
            // Isi Air Button
            Expanded(
              child: _buildManualServoButton(
                icon: Icons.opacity_rounded,
                label: 'Isi Air',
                isActive: isWaterActive,
                isDisabled: isAutoMode || isControlsDisabled || !isAdmin,
                onTap: () => _handleManualWater(service),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManualServoButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    final double opacity = isDisabled ? 0.5 : 1.0;
    final bool showLoading = isActive && !isDisabled;

    return GestureDetector(
      onTap: isDisabled || isActive ? null : onTap,
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
                  // Show spinner when active, otherwise show icon
                  if (showLoading)
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          DarkTheme.neonGreen,
                        ),
                      ),
                    )
                  else
                    Icon(
                      icon,
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
                    showLoading ? 'Mengisi...' : 'Tekan untuk isi',
                    style: DarkTheme.controlSubtitle.copyWith(
                      color: showLoading
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

  Future<void> _handleManualFeed(FirebaseService service) async {
    final success = await service.triggerManualFeed();
    if (success) {
      _showSuccessSnackbar('Mengisi pakan...');
    } else {
      _showErrorSnackbar('Gagal mengaktifkan servo pakan');
    }
  }

  Future<void> _handleManualWater(FirebaseService service) async {
    final success = await service.triggerManualWater();
    if (success) {
      _showSuccessSnackbar('Mengisi air...');
    } else {
      _showErrorSnackbar('Gagal mengaktifkan servo air');
    }
  }

  PreferredSizeWidget _buildHeader(SensorModel sensorData, bool isAdmin) {
    // Determine connection status color
    final bool isOnline = sensorData.isOnline;
    final Color statusColor = isOnline
        ? DarkTheme.neonGreen
        : DarkTheme.statusDanger;
    final String statusText = isOnline
        ? 'Terpantau ${sensorData.timeSinceUpdate}'
        : 'Terputus ${sensorData.timeSinceUpdate}';

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
              // Dynamic status dot
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withValues(
                        alpha: 0.5 + (_pulseController.value * 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(
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
              Text(
                statusText,
                style: DarkTheme.headerSubtitle.copyWith(
                  color: isOnline
                      ? DarkTheme.paleGreen
                      : DarkTheme.statusDanger,
                ),
              ),
            ],
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Stack(
          children: [
            if (isAdmin) // Only show settings to admin
              IconButton(
                icon: const Icon(
                  Icons.settings_rounded,
                  color: DarkTheme.textPrimary,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: DarkTheme.textPrimary,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AlertsScreen()),
                );
              },
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
    // Apply visual dimming when data is stale
    final double staleDim = sensorData.isStale ? 0.6 : 1.0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: staleDim,
      child: Column(
        children: [
          // Row 1 (Iklim): Temperature & Humidity
          Row(
            children: [
              // Temperature Card
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.thermostat_rounded,
                  label: 'Suhu',
                  value: '${sensorData.temperature.toStringAsFixed(0)}°C',
                  statusText: DarkTheme.getTemperatureStatusText(
                    sensorData.temperature,
                  ),
                  statusColor: DarkTheme.getTemperatureStatus(
                    sensorData.temperature,
                  ),
                  isStale: sensorData.isStale,
                ),
              ),
              const SizedBox(width: 12),
              // Humidity Card (NEW)
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.opacity,
                  label: 'Kelembapan',
                  value: '${sensorData.humidity.toStringAsFixed(0)}%',
                  statusText: DarkTheme.getHumidityStatusText(
                    sensorData.humidity,
                  ),
                  statusColor: DarkTheme.getHumidityStatus(sensorData.humidity),
                  isStale: sensorData.isStale,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2 (Udara & Air): Ammonia & Water Level
          Row(
            children: [
              // Ammonia Card
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.cloud_outlined,
                  label: 'Amonia',
                  value: '${sensorData.ammonia.toStringAsFixed(0)} ppm',
                  statusText: DarkTheme.getAmmoniaStatusText(
                    sensorData.ammonia,
                  ),
                  statusColor: DarkTheme.getAmmoniaStatus(sensorData.ammonia),
                  isStale: sensorData.isStale,
                ),
              ),
              const SizedBox(width: 12),
              // Water Level Card
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.water_drop_rounded,
                  label: 'Level Air',
                  value: DarkTheme.getWaterLevelDisplayText(
                    sensorData.waterLevel,
                  ),
                  statusText: DarkTheme.getWaterLevelStatusText(
                    sensorData.waterLevel,
                  ),
                  statusColor: DarkTheme.getWaterLevelStatus(
                    sensorData.waterLevel,
                  ),
                  isStale: sensorData.isStale,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3 (Pakan): Feed Weight - Centered
          Row(
            children: [
              const Spacer(),
              // Feed Weight Card
              Expanded(
                flex: 2,
                child: _buildMetricCard(
                  icon: Icons.grain_rounded,
                  label: 'Sisa Pakan',
                  value: '${sensorData.feedWeight.toStringAsFixed(1)} g',
                  statusText: DarkTheme.getFeedWeightStatusText(
                    sensorData.feedWeight,
                  ),
                  statusColor: DarkTheme.getFeedWeightStatus(
                    sensorData.feedWeight,
                  ),
                  isStale: sensorData.isStale,
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String statusText,
    required Color statusColor,
    bool isStale = false,
  }) {
    // Gray out status badge when stale
    final Color displayStatusColor = isStale
        ? DarkTheme.textDisabled
        : statusColor;
    final String displayStatusText = isStale ? 'Offline' : statusText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: isStale
          ? BoxDecoration(
              color: DarkTheme.cardBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DarkTheme.textDisabled.withValues(alpha: 0.3),
                width: 1,
              ),
            )
          : DarkTheme.cardDecoration,
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
                  color: isStale
                      ? DarkTheme.textDisabled.withValues(alpha: 0.15)
                      : DarkTheme.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isStale ? DarkTheme.textDisabled : DarkTheme.neonGreen,
                  size: 24,
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: displayStatusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(displayStatusText, style: DarkTheme.badgeText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Label
          Text(
            label,
            style: DarkTheme.sensorLabel.copyWith(
              color: isStale ? DarkTheme.textDisabled : DarkTheme.paleGreen,
            ),
          ),
          const SizedBox(height: 6),
          // Value
          Text(
            isStale ? '--' : value,
            style: DarkTheme.sensorValue.copyWith(
              color: isStale ? DarkTheme.textDisabled : DarkTheme.textPrimary,
            ),
          ),
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
                // Placeholder/Stream Image with error handling
                sensorData.imagePath.isNotEmpty
                    ? Image.network(
                        sensorData.imagePath,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildCameraLoadingState();
                        },
                        errorBuilder: (_, __, ___) => _buildCameraErrorState(),
                      )
                    : _buildPlaceholderImage(),

                // LIVE Badge (Top Left) - only show when online
                if (sensorData.isOnline)
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

                // Offline badge when stale
                if (sensorData.isStale)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: DarkTheme.textDisabled,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off, size: 12, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'OFFLINE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
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
                      sensorData.isStale
                          ? 'Skor Visi: --'
                          : 'Skor Visi: ${sensorData.visionScore} (${DarkTheme.getVisionStatusText(sensorData.visionScore)})',
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
                              color: sensorData.isOnline
                                  ? DarkTheme.neonGreen
                                  : DarkTheme.textDisabled,
                              shape: BoxShape.circle,
                              boxShadow: sensorData.isOnline
                                  ? [
                                      BoxShadow(
                                        color: DarkTheme.neonGreen.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            sensorData.isOnline
                                ? 'Deteksi AI Aktif'
                                : 'Deteksi AI Nonaktif',
                            style: DarkTheme.controlSubtitle.copyWith(
                              color: sensorData.isOnline
                                  ? DarkTheme.paleGreen
                                  : DarkTheme.textDisabled,
                            ),
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

  // UX Fix #3: Camera loading state
  Widget _buildCameraLoadingState() {
    return Container(
      color: DarkTheme.cardBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  DarkTheme.neonGreen.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Memuat kamera...',
              style: DarkTheme.controlSubtitle.copyWith(
                color: DarkTheme.paleGreen.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UX Fix #3: Camera error state
  Widget _buildCameraErrorState() {
    return Container(
      color: DarkTheme.cardBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              size: 48,
              color: DarkTheme.statusDanger.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kamera tidak tersedia',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DarkTheme.statusDanger,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Periksa koneksi perangkat',
              style: DarkTheme.controlSubtitle.copyWith(
                color: DarkTheme.paleGreen.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {}); // Trigger rebuild to retry
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: TextButton.styleFrom(foregroundColor: DarkTheme.neonGreen),
            ),
          ],
        ),
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

  Widget _buildControlSection(
    SensorModel sensorData,
    FirebaseService service,
    bool isAdmin,
  ) {
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
              // Switch with loading state
              _isAutoModeLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          DarkTheme.neonGreen,
                        ),
                      ),
                    )
                  : Transform.scale(
                      scale: 1.1,
                      child: Switch(
                        value: sensorData.isAutoMode,
                        onChanged:
                            (sensorData.isStale ||
                                sensorData.isFromCache ||
                                !isAdmin)
                            ? null
                            : (val) => _handleAutoModeToggle(val, service),
                        activeColor: DarkTheme.neonGreen,
                        activeTrackColor: DarkTheme.neonGreen.withValues(
                          alpha: 0.4,
                        ),
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

        // UX Fix #7: Offline warning banner (Cache or Stale)
        if (sensorData.isStale || sensorData.isFromCache)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: DarkTheme.statusWarning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: DarkTheme.statusWarning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  sensorData.isFromCache
                      ? Icons.cloud_off_rounded
                      : Icons.wifi_off_rounded,
                  size: 18,
                  color: DarkTheme.statusWarning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sensorData.isFromCache
                        ? 'Kontrol dinonaktifkan - Aplikasi offline'
                        : 'Kontrol dinonaktifkan - Perangkat offline',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: DarkTheme.statusWarning,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Actuator Grid (Fan & Heater)
        Row(
          children: [
            // Fan Button - UX Fix #7: Also disable when offline
            Expanded(
              child: _buildActuatorButton(
                icon: Icons.mode_fan_off_rounded,
                activeIcon: Icons.wind_power_rounded,
                label: 'Kipas',
                isActive: sensorData.isFanOn,
                isDisabled:
                    sensorData.isAutoMode ||
                    sensorData.isStale ||
                    sensorData.isFromCache,
                isLoading: _isFanLoading,
                onTap: () => _handleFanToggle(sensorData, service),
              ),
            ),
            const SizedBox(width: 12),
            // Heater Button - UX Fix #7: Also disable when offline
            Expanded(
              child: _buildActuatorButton(
                icon: Icons.thermostat_auto_outlined,
                activeIcon: Icons.local_fire_department_rounded,
                label: 'Pemanas',
                isActive: sensorData.isHeaterOn,
                isDisabled:
                    sensorData.isAutoMode ||
                    sensorData.isStale ||
                    sensorData.isFromCache,
                isLoading: _isHeaterLoading,
                onTap: () => _handleHeaterToggle(sensorData, service),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // UX Fix #2: Actuator handlers with loading states and rollback
  Future<void> _handleAutoModeToggle(
    bool value,
    FirebaseService service,
  ) async {
    setState(() => _isAutoModeLoading = true);

    final success = await service.updateActuatorState(isAutoMode: value);

    if (success) {
      _showSuccessSnackbar(
        value ? 'Mode Otomatis diaktifkan' : 'Mode Manual diaktifkan',
      );
    } else {
      _showErrorSnackbar('Gagal mengubah mode. Coba lagi.');
    }

    if (mounted) setState(() => _isAutoModeLoading = false);
  }

  Future<void> _handleFanToggle(
    SensorModel sensorData,
    FirebaseService service,
  ) async {
    if (sensorData.isAutoMode) return;

    setState(() => _isFanLoading = true);

    final newValue = !sensorData.isFanOn;
    final success = await service.updateActuatorState(isFanOn: newValue);

    if (success) {
      _showSuccessSnackbar(newValue ? 'Kipas dinyalakan' : 'Kipas dimatikan');
    } else {
      _showErrorSnackbar('Gagal mengontrol kipas. Coba lagi.');
    }

    if (mounted) setState(() => _isFanLoading = false);
  }

  Future<void> _handleHeaterToggle(
    SensorModel sensorData,
    FirebaseService service,
  ) async {
    if (sensorData.isAutoMode) return;

    setState(() => _isHeaterLoading = true);

    final newValue = !sensorData.isHeaterOn;
    final success = await service.updateActuatorState(isHeaterOn: newValue);

    if (success) {
      _showSuccessSnackbar(
        newValue ? 'Pemanas dinyalakan' : 'Pemanas dimatikan',
      );
    } else {
      _showErrorSnackbar('Gagal mengontrol pemanas. Coba lagi.');
    }

    if (mounted) setState(() => _isHeaterLoading = false);
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: DarkTheme.neonGreen,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: DarkTheme.cardBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_rounded,
              color: DarkTheme.statusDanger,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: DarkTheme.cardBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildActuatorButton({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required bool isDisabled,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    final double opacity = isDisabled ? 0.5 : 1.0;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
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
                  // Show spinner when loading, otherwise show icon
                  if (isLoading)
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          DarkTheme.neonGreen,
                        ),
                      ),
                    )
                  else
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
                    isLoading
                        ? 'Memproses...'
                        : (isActive ? 'Menyala' : 'Mati'),
                    style: DarkTheme.controlSubtitle.copyWith(
                      color: isLoading
                          ? DarkTheme.statusWarning
                          : (isActive && !isDisabled
                                ? DarkTheme.neonGreen
                                : DarkTheme.textDisabled),
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
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlertsScreen()),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            } else {
              setState(() => _currentNavIndex = index);
            }
          },
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
