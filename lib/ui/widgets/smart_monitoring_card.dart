import 'package:flutter/material.dart';
import 'package:kandangku/ui/theme/app_theme.dart';

/// Smart monitoring card with traffic light color system
/// Changes background color based on sensor thresholds
class SmartMonitoringCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color statusColor;
  final String? statusText;
  final bool isCritical; // Enables pulsing animation

  const SmartMonitoringCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit = '',
    required this.statusColor,
    this.statusText,
    this.isCritical = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: isCritical ? 16 : 8,
            spreadRadius: isCritical ? 2 : 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon and Status Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: statusColor, size: 32),
              if (statusText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Label
          Text(label, style: AppTheme.sensorLabelStyle.copyWith(fontSize: 14)),
          const SizedBox(height: 4),

          // Value with Unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTheme.sensorValueStyle.copyWith(
                    fontSize: 40,
                    color: statusColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    unit,
                    style: AppTheme.sensorUnitStyle.copyWith(
                      fontSize: 18,
                      color: statusColor.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Pulsing wrapper for critical status cards
class PulsingCard extends StatefulWidget {
  final Widget child;

  const PulsingCard({super.key, required this.child});

  @override
  State<PulsingCard> createState() => _PulsingCardState();
}

class _PulsingCardState extends State<PulsingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: _animation.value, child: child);
      },
      child: widget.child,
    );
  }
}
