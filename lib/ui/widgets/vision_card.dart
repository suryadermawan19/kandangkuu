import 'package:flutter/material.dart';
import 'package:kandangku/ui/theme/app_theme.dart';

class VisionCard extends StatelessWidget {
  final String? imageUrl;
  final int visionScore;

  const VisionCard({super.key, this.imageUrl, required this.visionScore});

  @override
  Widget build(BuildContext context) {
    // Updated behavior mapping per user requirements
    String behaviorLabel;
    String behaviorDescription;
    Color statusColor;
    IconData statusIcon;

    if (visionScore < 40) {
      behaviorLabel = 'Ayam Berkerumun (Kedinginan)';
      behaviorDescription =
          'Ayam mengelompok di sudut kandang - Tanda kedinginan! Periksa suhu dan pertimbangkan menyalakan pemanas.';
      statusColor = AppTheme.statusRed;
      statusIcon = Icons.warning_amber_rounded;
    } else if (visionScore < 70) {
      behaviorLabel = 'Ayam Tersebar (Nyaman)';
      behaviorDescription =
          'Ayam tersebar merata di kandang - Lingkungan sehat dan nyaman. Kondisi optimal untuk pertumbuhan.';
      statusColor = AppTheme.statusGreen;
      statusIcon = Icons.check_circle_outline;
    } else {
      // visionScore >= 70
      behaviorLabel = 'Ayam Sangat Menyebar (Kepanasan)';
      behaviorDescription =
          'Ayam sangat tersebar dan menghindari area tertentu - Tanda kepanasan! Periksa suhu dan pertimbangkan menyalakan kipas.';
      statusColor = AppTheme.statusRed;
      statusIcon = Icons.warning_amber_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground, // Pure white
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          // Soft shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          // Subtle status color glow
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Analisis Visi',
                          style: AppTheme.cardTitleStyle.copyWith(
                            fontSize: 18,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      behaviorLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Large Score Badge
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '$visionScore',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Skor',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Detailed Description
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    behaviorDescription,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Camera Feed (ESP32-CAM Stream)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppTheme.surfaceBackground,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              color: statusColor,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.surfaceBackground,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: AppTheme.textDisabled,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Feed kamera tidak tersedia',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.surfaceBackground,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              color: AppTheme.textDisabled,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Menunggu feed kamera...',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
