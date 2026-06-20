/// Large flat Translate button. Solid black (light) / white (dark). No shadow.
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_dimens.dart';

class TranslateButton extends StatelessWidget {
  const TranslateButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white : Colors.black;
    final fgColor = isDark ? Colors.black : Colors.white;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        onTap: isLoading
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onTap();
              },
        child: AnimatedContainer(
          duration: AppDimens.duration,
          height: AppDimens.translateButtonHeight,
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: AppDimens.duration,
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.translate_rounded, color: fgColor, size: 20),
                      const SizedBox(width: AppDimens.spaceSm),
                      Text(
                        'Translate',
                        style: TextStyle(
                          color: fgColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
