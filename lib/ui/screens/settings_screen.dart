import 'package:flutter/material.dart';
import 'package:kandangku/ui/theme/dark_theme.dart';

/// Settings Screen - "Pengaturan" for PoultryVision (Kandangku)
/// Dark Industrial Green Theme - Bahasa Indonesia
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Threshold Settings
  double _maxTemperature = 30.0;
  double _maxAmmonia = 20.0;

  // Notification Settings
  bool _alarmSoundEnabled = true;
  bool _dailyReportEnabled = false;

  // Device Status (Mock)
  final String _wifiName = 'Wifikossritanjung';
  final bool _isDeviceConnected = true;

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
            // Profile Section
            _buildProfileCard(),
            const SizedBox(height: 24),

            // Threshold Settings Section
            _buildSectionTitle('Ambang Batas Alarm'),
            const SizedBox(height: 12),
            _buildThresholdSettings(),
            const SizedBox(height: 24),

            // Device Configuration Section
            _buildSectionTitle('Perangkat IoT'),
            const SizedBox(height: 12),
            _buildDeviceSettings(),
            const SizedBox(height: 24),

            // Notification Settings Section
            _buildSectionTitle('Notifikasi'),
            const SizedBox(height: 12),
            _buildNotificationSettings(),
            const SizedBox(height: 32),

            // Footer
            _buildFooter(),
            const SizedBox(height: 40),
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
      title: const Text('Pengaturan', style: DarkTheme.headerTitle),
      centerTitle: true,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title, style: DarkTheme.sectionTitle),
    );
  }

  // ============ PROFILE SECTION ============
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DarkTheme.cardDecoration,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DarkTheme.neonGreen,
                  DarkTheme.neonGreen.withValues(alpha: 0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: DarkTheme.neonGreen.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'PB',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: DarkTheme.deepForestBlack,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name & Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Pak Budi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: DarkTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pemilik Kandang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: DarkTheme.paleGreen,
                  ),
                ),
              ],
            ),
          ),

          // Edit Button
          Container(
            decoration: BoxDecoration(
              color: DarkTheme.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: DarkTheme.neonGreen,
                size: 22,
              ),
              onPressed: () {
                // Edit profile action
                _showSnackbar('Fitur edit profil akan segera hadir');
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============ THRESHOLD SETTINGS ============
  Widget _buildThresholdSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DarkTheme.cardDecoration,
      child: Column(
        children: [
          // Temperature Threshold
          _buildThresholdItem(
            icon: Icons.thermostat_rounded,
            title: 'Suhu Maksimum',
            description: 'Alarm berbunyi jika suhu melebihi batas ini',
            value: _maxTemperature,
            unit: '°C',
            min: 25.0,
            max: 40.0,
            divisions: 30,
            onChanged: (val) => setState(() => _maxTemperature = val),
          ),

          const SizedBox(height: 20),
          Divider(color: DarkTheme.cardBorder, height: 1),
          const SizedBox(height: 20),

          // Ammonia Threshold
          _buildThresholdItem(
            icon: Icons.cloud_outlined,
            title: 'Amonia Maksimum',
            description: 'Alarm berbunyi jika kadar amonia melebihi batas ini',
            value: _maxAmmonia,
            unit: ' ppm',
            min: 10.0,
            max: 50.0,
            divisions: 40,
            onChanged: (val) => setState(() => _maxAmmonia = val),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdItem({
    required IconData icon,
    required String title,
    required String description,
    required double value,
    required String unit,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DarkTheme.neonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: DarkTheme.neonGreen, size: 22),
            ),
            const SizedBox(width: 14),
            // Title & Value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: DarkTheme.controlTitle),
                  const SizedBox(height: 2),
                  Text(description, style: DarkTheme.controlSubtitle),
                ],
              ),
            ),
            // Current Value Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: DarkTheme.neonGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${value.toStringAsFixed(unit == '°C' ? 1 : 0)}$unit',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DarkTheme.deepForestBlack,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: DarkTheme.neonGreen,
            inactiveTrackColor: DarkTheme.neonGreen.withValues(alpha: 0.2),
            thumbColor: DarkTheme.neonGreen,
            overlayColor: DarkTheme.neonGreen.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 6,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        // Min/Max Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${min.toStringAsFixed(0)}$unit',
                style: const TextStyle(
                  fontSize: 12,
                  color: DarkTheme.paleGreen,
                ),
              ),
              Text(
                '${max.toStringAsFixed(0)}$unit',
                style: const TextStyle(
                  fontSize: 12,
                  color: DarkTheme.paleGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============ DEVICE SETTINGS ============
  Widget _buildDeviceSettings() {
    return Container(
      decoration: DarkTheme.cardDecoration,
      child: Column(
        children: [
          // WiFi Status
          _buildDeviceTile(
            icon: Icons.wifi_rounded,
            iconColor: _isDeviceConnected
                ? DarkTheme.neonGreen
                : DarkTheme.statusDanger,
            title: 'Koneksi Alat',
            subtitle: _isDeviceConnected
                ? 'Terhubung: $_wifiName'
                : 'Tidak terhubung',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isDeviceConnected
                    ? DarkTheme.neonGreen
                    : DarkTheme.statusDanger,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isDeviceConnected ? 'Online' : 'Offline',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: DarkTheme.deepForestBlack,
                ),
              ),
            ),
          ),

          Divider(
            color: DarkTheme.cardBorder,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),

          // Restart Device
          _buildDeviceTile(
            icon: Icons.refresh_rounded,
            iconColor: DarkTheme.statusWarning,
            title: 'Restart Alat',
            subtitle: 'Mulai ulang perangkat ESP32 jarak jauh',
            trailing: OutlinedButton(
              onPressed: () => _showRestartConfirmation(),
              style: OutlinedButton.styleFrom(
                foregroundColor: DarkTheme.statusWarning,
                side: const BorderSide(color: DarkTheme.statusWarning),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Restart',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          Divider(
            color: DarkTheme.cardBorder,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),

          // Device Info
          _buildDeviceTile(
            icon: Icons.memory_rounded,
            iconColor: DarkTheme.paleGreen,
            title: 'Info Perangkat',
            subtitle: 'ESP32-CAM v2.1 • Sensor DHT22 • MQ-135',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: DarkTheme.paleGreen,
            ),
            onTap: () => _showSnackbar('Detail perangkat akan segera hadir'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: DarkTheme.controlTitle),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: DarkTheme.controlSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }

  // ============ NOTIFICATION SETTINGS ============
  Widget _buildNotificationSettings() {
    return Container(
      decoration: DarkTheme.cardDecoration,
      child: Column(
        children: [
          // Alarm Sound Toggle
          _buildNotificationTile(
            icon: Icons.volume_up_rounded,
            iconColor: DarkTheme.statusWarning,
            title: 'Suara Alarm Bahaya',
            subtitle: 'Bunyi peringatan saat kondisi berbahaya',
            value: _alarmSoundEnabled,
            onChanged: (val) => setState(() => _alarmSoundEnabled = val),
          ),

          Divider(
            color: DarkTheme.cardBorder,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),

          // Daily Report Toggle
          _buildNotificationTile(
            icon: Icons.assessment_rounded,
            iconColor: DarkTheme.paleGreen,
            title: 'Laporan Harian',
            subtitle: 'Ringkasan kondisi kandang setiap hari',
            value: _dailyReportEnabled,
            onChanged: (val) => setState(() => _dailyReportEnabled = val),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DarkTheme.controlTitle),
                const SizedBox(height: 2),
                Text(subtitle, style: DarkTheme.controlSubtitle),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Switch
          Transform.scale(
            scale: 1.1,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: DarkTheme.neonGreen,
              activeTrackColor: DarkTheme.neonGreen.withValues(alpha: 0.4),
              inactiveThumbColor: DarkTheme.textDisabled,
              inactiveTrackColor: DarkTheme.textDisabled.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  // ============ FOOTER ============
  Widget _buildFooter() {
    return Column(
      children: [
        // App Version
        Center(
          child: Text(
            'Versi 1.0.0',
            style: TextStyle(
              fontSize: 13,
              color: DarkTheme.paleGreen.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Logout Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showLogoutConfirmation(),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text(
              'Keluar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: DarkTheme.statusDanger,
              side: const BorderSide(color: DarkTheme.statusDanger, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============ DIALOGS & SNACKBARS ============
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DarkTheme.cardBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showRestartConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DarkTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Restart Perangkat?',
          style: TextStyle(color: DarkTheme.textPrimary),
        ),
        content: const Text(
          'Perangkat ESP32 akan dimulai ulang. Proses ini membutuhkan waktu sekitar 30 detik.',
          style: TextStyle(color: DarkTheme.paleGreen),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: DarkTheme.paleGreen),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackbar('Mengirim perintah restart...');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DarkTheme.statusWarning,
              foregroundColor: DarkTheme.deepForestBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DarkTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar dari Aplikasi?',
          style: TextStyle(color: DarkTheme.textPrimary),
        ),
        content: const Text(
          'Anda akan keluar dari akun ini. Login kembali untuk mengakses dashboard.',
          style: TextStyle(color: DarkTheme.paleGreen),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: DarkTheme.paleGreen),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackbar('Berhasil keluar');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DarkTheme.statusDanger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
