/// Bottom navigation bar.
///
/// Minimal pill-style strip with 4 destinations. Selected item is white
/// (dark) or black (light); inactive items are dimmed. No frosted glass on
/// pure-black backgrounds — just a subtle border.
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_dimens.dart';

class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.translate_rounded, label: 'Translate'),
    _NavItem(icon: Icons.history_rounded, label: 'History'),
    _NavItem(icon: Icons.bookmark_rounded, label: 'Saved'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? DarkColors.card : LightColors.card;
    final borderColor =
        isDark ? DarkColors.border : LightColors.border;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.spaceMd,
          0,
          AppDimens.spaceMd,
          AppDimens.spaceMd,
        ),
        child: Container(
          height: AppDimens.bottomNavHeight,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(AppDimens.radius),
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: _items[i],
                    selected: i == currentIndex,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Selected = full white (dark) / full black (light)
    // Unselected = dimmed grey
    final iconColor = selected
        ? (isDark ? Colors.white : Colors.black)
        : (isDark
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.35));
    final labelColor = selected
        ? iconColor
        : (isDark
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.25));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: iconColor, size: 22),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: labelColor,
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
