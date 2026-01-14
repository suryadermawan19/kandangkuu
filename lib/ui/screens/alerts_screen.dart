import 'package:flutter/material.dart';
import 'package:kandangku/ui/theme/dark_theme.dart';

/// Alert Severity Levels
enum AlertSeverity { critical, warning, info }

/// Alert Data Model
class AlertItem {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final AlertSeverity severity;
  final bool isUnread;

  AlertItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.severity,
    this.isUnread = true,
  });
}

/// Alerts Screen - "Peringatan" for PoultryVision (Kandangku)
/// Dark Industrial Green Theme with emphasis on critical notifications
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Severity Colors
  static const Color criticalColor = Color(0xFFFF3B30); // Neon Red
  static const Color warningColor = Color(0xFFFF9500); // Amber
  static const Color infoColor = Color(0xFF17cf36); // Neon Green

  // Mock Data - Dummy Alerts in Bahasa Indonesia
  List<AlertItem> _alerts = [
    AlertItem(
      id: '1',
      title: 'Suhu Kritis!',
      body: 'Suhu terdeteksi 34°C. Cek kipas segera.',
      timeAgo: '2 menit lalu',
      severity: AlertSeverity.critical,
      isUnread: true,
    ),
    AlertItem(
      id: '2',
      title: 'Amonia Meningkat',
      body: 'Kadar amonia mencapai 18 ppm. Tingkatkan ventilasi.',
      timeAgo: '15 menit lalu',
      severity: AlertSeverity.warning,
      isUnread: true,
    ),
    AlertItem(
      id: '3',
      title: 'Pakan Menipis',
      body: 'Stok pakan tersisa 15%. Segera isi ulang.',
      timeAgo: '30 menit lalu',
      severity: AlertSeverity.warning,
      isUnread: false,
    ),
    AlertItem(
      id: '4',
      title: 'Koneksi WiFi Stabil',
      body: 'Sistem terhubung dengan jaringan. Semua sensor aktif.',
      timeAgo: '1 jam lalu',
      severity: AlertSeverity.info,
      isUnread: false,
    ),
    AlertItem(
      id: '5',
      title: 'Mode Otomatis Aktif',
      body: 'Sistem kontrol otomatis berjalan normal.',
      timeAgo: '2 jam lalu',
      severity: AlertSeverity.info,
      isUnread: false,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      _alerts = _alerts.map((alert) {
        return AlertItem(
          id: alert.id,
          title: alert.title,
          body: alert.body,
          timeAgo: alert.timeAgo,
          severity: alert.severity,
          isUnread: false,
        );
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Semua notifikasi ditandai sudah dibaca'),
        backgroundColor: DarkTheme.darkGreenGlass,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _dismissAlert(String alertId) {
    setState(() {
      _alerts.removeWhere((alert) => alert.id == alertId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notifikasi dihapus'),
        backgroundColor: DarkTheme.darkGreenGlass,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Batal',
          textColor: DarkTheme.neonGreen,
          onPressed: () {
            // Undo would go here in production
          },
        ),
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return criticalColor;
      case AlertSeverity.warning:
        return warningColor;
      case AlertSeverity.info:
        return infoColor;
    }
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.error_rounded;
      case AlertSeverity.warning:
        return Icons.warning_rounded;
      case AlertSeverity.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _alerts.where((a) => a.isUnread).length;

    return Scaffold(
      backgroundColor: DarkTheme.backgroundPrimary,
      appBar: _buildAppBar(unreadCount),
      body: _alerts.isEmpty ? _buildEmptyState() : _buildAlertsList(),
    );
  }

  PreferredSizeWidget _buildAppBar(int unreadCount) {
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Peringatan', style: DarkTheme.headerTitle),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: criticalColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Notifikasi bahaya & sistem',
            style: DarkTheme.headerSubtitle,
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _alerts.any((a) => a.isUnread) ? _markAllAsRead : null,
          child: Text(
            'Tandai Dibaca',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _alerts.any((a) => a.isUnread)
                  ? DarkTheme.neonGreen
                  : DarkTheme.textDisabled,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DarkTheme.neonGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 64,
              color: DarkTheme.neonGreen.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Tidak Ada Peringatan', style: DarkTheme.sectionTitle),
          const SizedBox(height: 8),
          Text(
            'Semua sistem berjalan normal',
            style: DarkTheme.controlSubtitle.copyWith(
              color: DarkTheme.paleGreen.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(AlertItem alert) {
    final Color severityColor = _getSeverityColor(alert.severity);
    final IconData severityIcon = _getSeverityIcon(alert.severity);

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _dismissAlert(alert.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: criticalColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: criticalColor, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DarkTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alert.isUnread
                ? severityColor.withValues(alpha: 0.4)
                : DarkTheme.cardBorder,
            width: alert.isUnread ? 1.5 : 1,
          ),
          boxShadow: alert.isUnread
              ? [
                  BoxShadow(
                    color: severityColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Severity Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(severityIcon, color: severityColor, size: 24),
            ),
            const SizedBox(width: 14),

            // Center: Title & Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: alert.isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: DarkTheme.textPrimary,
                          ),
                        ),
                      ),
                      // Unread Dot
                      if (alert.isUnread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: severityColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: severityColor.withValues(alpha: 0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alert.body,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: DarkTheme.paleGreen,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: DarkTheme.paleGreen.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        alert.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: DarkTheme.paleGreen.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
