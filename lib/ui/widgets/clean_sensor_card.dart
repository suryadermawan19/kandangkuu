import 'package:flutter/material.dart';
import 'package:kandangku/ui/theme/app_theme.dart';

/// Clean sensor card optimized for Light Mode with Bahasa Indonesia labels
/// Universal design for elderly farmers (high readability) + young users (modern aesthetics)
class CleanSensorCard extends StatelessWidget {
  final IconData icon;
  final String label; // Bahasa Indonesia
  final String value;
  final String unit;
  final Color statusColor;
  final String? statusText;
  final bool isCritical; // Enables subtle pulsing animation

  const CleanSensorCard({
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
    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground, // Pure white
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          // Soft shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
          // Subtle status color glow
          BoxShadow(
            color: statusColor.withValues(alpha: isCritical ? 0.15 : 0.08),
            blurRadius: isCritical ? 12 : 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
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
              // Icon with soft background accent
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: statusColor, size: 28),
              ),
              // Status badge
              if (statusText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    statusText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Label (Indonesian)
          Text(
            label,
            style: AppTheme.sensorLabelStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Value with Unit (Large for elderly readability, clean aesthetics)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    // Wrap with subtle pulsing animation for critical status
    if (isCritical) {
      return _PulsingWrapper(child: cardContent);
    }
    return cardContent;
  }
}

/// Subtle pulsing animation wrapper for critical alerts (Light Mode optimized)
class _PulsingWrapper extends StatefulWidget {
  final Widget child;

  const _PulsingWrapper({required this.child});

  @override
  State<_PulsingWrapper> createState() => _PulsingWrapperState();
}

class _PulsingWrapperState extends State<_PulsingWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.99,
      end: 1.01,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.9,
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
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}
