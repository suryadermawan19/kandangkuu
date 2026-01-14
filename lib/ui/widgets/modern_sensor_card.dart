import 'package:flutter/material.dart';
import 'package:kandangku/ui/theme/app_theme.dart';

/// Modern sensor card with Indonesian labels and smooth animations
/// Optimized for universal readability (elderly farmers + young users)
class ModernSensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color statusColor;
  final String? statusText;
  final bool isCritical; // Enables pulsing animation

  const ModernSensorCard({
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Soft-UI: Subtle background with status color tint
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: 2.5),
        // Modern glow effect
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.25),
            blurRadius: isCritical ? 20 : 12,
            spreadRadius: isCritical ? 3 : 1,
            offset: const Offset(0, 6),
          ),
          // Soft inner shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
              // Large icon with subtle background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: statusColor, size: 32),
              ),
              // Status badge
              if (statusText != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    statusText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Label (Indonesian)
          Text(
            label,
            style: AppTheme.sensorLabelStyle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Value with Unit (Extra Large for elderly readability)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: statusColor.withValues(alpha: 0.85),
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

    // Wrap with pulsing animation for critical status
    if (isCritical) {
      return _PulsingWrapper(child: cardContent);
    }
    return cardContent;
  }
}

/// Pulsing animation wrapper for critical alerts
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
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.85,
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
