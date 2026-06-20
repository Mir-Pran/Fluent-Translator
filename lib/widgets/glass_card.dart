import 'dart:ui';
import 'package:flutter/material.dart';

import '../core/constants/app_dimens.dart';

/// Lightweight frosted-glass card.
///
/// Uses a reduced blur sigma (10) for good 120fps performance while keeping
/// the glass look. No per-card BoxShadow (each shadow adds a compositing
/// layer); the border + translucent fill is enough.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? BorderRadius.circular(AppDimens.radius);

    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppDimens.spaceMd),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: r,
            border: border ??
                Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.6),
                  width: 1.0,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}
