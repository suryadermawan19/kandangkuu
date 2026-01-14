import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kandangku/ui/theme/app_theme.dart';

/// Panel kontrol aman dengan status terkunci visual untuk kontrol aktuator
/// Safe control panel with visual lock states - Indonesian localized (Light Mode)
class SafeControlPanel extends StatelessWidget {
  final bool isAutoMode;
  final bool isFanOn;
  final bool isHeaterOn;
  final Function(bool) onAutoModeChanged;
  final Function(bool) onFanChanged;
  final Function(bool) onHeaterChanged;

  const SafeControlPanel({
    super.key,
    required this.isAutoMode,
    required this.isFanOn,
    required this.isHeaterOn,
    required this.onAutoModeChanged,
    required this.onFanChanged,
    required this.onHeaterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground, // White background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              (isAutoMode ? AppTheme.autoModeBlue : AppTheme.manualModeOrange)
                  .withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          // Soft shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          // Subtle mode color glow
          BoxShadow(
            color:
                (isAutoMode ? AppTheme.autoModeBlue : AppTheme.manualModeOrange)
                    .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header dengan Toggle Mode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color:
                          (isAutoMode
                                  ? AppTheme.autoModeBlue
                                  : AppTheme.manualModeOrange)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isAutoMode ? Icons.auto_mode : Icons.touch_app,
                      color: isAutoMode
                          ? AppTheme.autoModeBlue
                          : AppTheme.manualModeOrange,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode Sistem',
                        style: AppTheme.sensorLabelStyle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isAutoMode
                              ? AppTheme.autoModeBlue
                              : AppTheme.manualModeOrange,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isAutoMode
                                          ? AppTheme.autoModeBlue
                                          : AppTheme.manualModeOrange)
                                      .withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          isAutoMode ? 'OTOMATIS' : 'MANUAL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: isAutoMode,
                onChanged: (value) => _showModeChangeDialog(context, value),
                activeColor: AppTheme.autoModeBlue,
                inactiveThumbColor: AppTheme.manualModeOrange,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Divider(color: AppTheme.textDisabled.withValues(alpha: 0.3)),
          const SizedBox(height: 14),

          // Judul Kontrol dengan Indikator Terkunci
          Row(
            children: [
              Text(
                'Kontrol Aktuator',
                style: AppTheme.cardTitleStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (isAutoMode) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textDisabled.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, size: 15, color: AppTheme.textDisabled),
                      const SizedBox(width: 5),
                      Text(
                        'Terkunci',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textDisabled,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),

          // Container Kontrol dengan Overlay Terkunci
          Stack(
            children: [
              Opacity(
                opacity: isAutoMode
                    ? 0.5
                    : 1.0, // Increased opacity for better visibility
                child: Column(
                  children: [
                    _buildControlRow(
                      context,
                      'Kipas Exhaust',
                      isFanOn,
                      onFanChanged,
                      FontAwesomeIcons.fan,
                      AppTheme.autoModeBlue,
                      isAutoMode,
                    ),
                    const SizedBox(height: 14),
                    Divider(
                      color: AppTheme.textDisabled.withValues(alpha: 0.3),
                      height: 1,
                    ),
                    const SizedBox(height: 14),
                    _buildControlRow(
                      context,
                      'Pemanas',
                      isHeaterOn,
                      onHeaterChanged,
                      FontAwesomeIcons.fire,
                      AppTheme.statusRed,
                      isAutoMode,
                    ),
                  ],
                ),
              ),
              if (isAutoMode)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _showLockedDialog(context);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlRow(
    BuildContext context,
    String label,
    bool value,
    Function(bool) onChanged,
    IconData icon,
    Color color,
    bool isLocked,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: value ? color.withValues(alpha: 0.12) : AppTheme.surfaceBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value ? color.withValues(alpha: 0.5) : AppTheme.textDisabled,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: value ? color : AppTheme.textDisabled,
            size: 26,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: isLocked
              ? null
              : (val) {
                  _showConfirmationDialog(context, label, val, onChanged);
                },
          activeColor: color,
        ),
      ],
    );
  }

  void _showModeChangeDialog(BuildContext context, bool newValue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              newValue ? Icons.auto_mode : Icons.touch_app,
              color: newValue
                  ? AppTheme.autoModeBlue
                  : AppTheme.manualModeOrange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Ubah Mode Sistem?',
                style: AppTheme.cardTitleStyle.copyWith(
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          newValue
              ? 'Beralih ke mode OTOMATIS?\n\nSistem akan otomatis mengontrol kipas dan pemanas berdasarkan pembacaan sensor.'
              : 'Beralih ke mode MANUAL?\n\nAnda akan memiliki kontrol penuh atas kipas dan pemanas. Pastikan untuk memantau kondisi dengan cermat.',
          style: AppTheme.bodyTextStyle.copyWith(
            fontSize: 15,
            height: 1.5,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onAutoModeChanged(newValue);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newValue
                  ? AppTheme.autoModeBlue
                  : AppTheme.manualModeOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Konfirmasi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    String deviceName,
    bool newValue,
    Function(bool) onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Konfirmasi Aksi',
          style: AppTheme.cardTitleStyle.copyWith(
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          '${newValue ? 'Nyalakan' : 'Matikan'} $deviceName?',
          style: AppTheme.bodyTextStyle.copyWith(
            fontSize: 16,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm(newValue);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Konfirmasi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLockedDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.lock, color: AppTheme.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Kontrol terkunci dalam Mode Otomatis. Beralih ke Manual untuk mengontrol.',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceBackground,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
