import 'dart:ui';
import 'package:flutter/material.dart';

/// Lightweight ambient background: blurred colour orbs painted behind the
/// content. Each orb is blurred individually (ImageFiltered) instead of
/// blurring the entire screen — far cheaper on the GPU.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // ── Solid base ────────────────────────────────────────────────────────
        ColoredBox(
          color: isDark ? const Color(0xFF0D0D11) : const Color(0xFFF7F7FA),
          child: const SizedBox.expand(),
        ),

        // ── Ambient orbs (individually blurred — much cheaper than a
        //    full-screen BackdropFilter at sigmaX/Y 70) ─────────────────────
        Positioned(
          top: -80,
          right: -80,
          child: _Orb(
            size: 320,
            color: isDark
                ? const Color(0x228B5CF6) // violet
                : const Color(0x118B5CF6),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -120,
          child: _Orb(
            size: 380,
            color: isDark
                ? const Color(0x1F3B82F6) // blue
                : const Color(0x0E3B82F6),
          ),
        ),
        Positioned(
          top: 300,
          right: -100,
          child: _Orb(
            size: 250,
            color: isDark
                ? const Color(0x14EC4899) // pink
                : const Color(0x08EC4899),
          ),
        ),

        // ── Content ───────────────────────────────────────────────────────────
        child,
      ],
    );
  }
}

/// A single blurred colour circle. Uses [ImageFiltered] which creates a
/// localised blur layer instead of compositing the full screen.
class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60, tileMode: TileMode.decal),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
