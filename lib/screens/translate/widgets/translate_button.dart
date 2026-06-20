/// Large Translate button with an animated gradient shimmer.
/// The gradient rotates subtly on load, giving a premium feel.
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_dimens.dart';

class TranslateButton extends StatefulWidget {
  const TranslateButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  final VoidCallback onTap;
  final bool isLoading;

  @override
  State<TranslateButton> createState() => _TranslateButtonState();
}

class _TranslateButtonState extends State<TranslateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Gradient: violet → indigo → blue — matches ambient orbs.
    const gradient = LinearGradient(
      colors: [
        Color(0xFF7C3AED), // violet-600
        Color(0xFF4F46E5), // indigo-600
        Color(0xFF2563EB), // blue-600
        Color(0xFF7C3AED), // loop back
      ],
      stops: [0.0, 0.33, 0.67, 1.0],
    );

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Container(
          height: AppDimens.translateButtonHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient.colors,
              stops: gradient.stops,
              begin: AlignmentDirectional(
                -1.0 + _shimmer.value * 2,
                -0.3,
              ),
              end: AlignmentDirectional(
                0.0 + _shimmer.value * 2,
                0.3,
              ),
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          splashColor: Colors.white.withValues(alpha: 0.15),
          onTap: widget.isLoading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  widget.onTap();
                },
          child: AnimatedContainer(
            duration: AppDimens.duration,
            height: AppDimens.translateButtonHeight,
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: AppDimens.duration,
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.translate_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: AppDimens.spaceSm),
                        Text(
                          'Translate',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
