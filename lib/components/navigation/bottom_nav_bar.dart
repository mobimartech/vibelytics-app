import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../main_shell.dart';

/// Bottom navigation bar with 5 tabs
///
/// Center tab (Enhance) has special elevated AI gradient treatment.
class VBottomNavBar extends StatelessWidget {
  const VBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  final int currentIndex;
  final void Function(int) onTabChanged;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 72 + bottomPadding,
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: isDark ? VColors.bgSecondaryDark : VColors.bgPrimary,
        border: Border(
          top: BorderSide(
            color: isDark ? VColors.borderSubtleDark : VColors.borderSubtle,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // _NavItem(
            //   icon: VIcons.home,
            //   label: 'home.title'.tr(),
            //   isActive: currentIndex == 0,
            //   onTap: () => _handleTap(0),
            // ),
            // _NavItem(
            //   icon: VIcons.explore,
            //   label: 'explore.title'.tr(),
            //   isActive: currentIndex == 1,
            //   onTap: () => _handleTap(1),
            // ),
            _CenterNavItem(
              isActive: currentIndex == 0,
              onTap: () => _handleTap(0),
            ),
            _BadgedNavItem(
              icon: VIcons.notification,
              label: 'activity.title'.tr(),
              isActive: currentIndex == 1,
              badgeNotifier: MainShell.unreadActivityNotifier,
              onTap: () => _handleTap(1),
            ),
            _NavItem(
              icon: VIcons.profile,
              label: 'profile.title'.tr(),
              isActive: currentIndex == 2,
              onTap: () => _handleTap(2),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(int index) {
    VHaptics.light();
    onTabChanged(index);
  }
}

/// Standard navigation item
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? VColors.accentPrimary : VColors.textTer(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            VSpace.v05,
            Text(
              label,
              style: VType.caption.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isActive) ...[
              VSpace.v1,
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: VColors.accentPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Navigation item with a badge (unread count)
class _BadgedNavItem extends StatelessWidget {
  const _BadgedNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.badgeNotifier,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final ValueNotifier<int> badgeNotifier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? VColors.accentPrimary : VColors.textTer(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 24, color: color),
                ValueListenableBuilder<int>(
                  valueListenable: badgeNotifier,
                  builder: (_, count, _) {
                    if (count <= 0) return const SizedBox.shrink();
                    return Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        decoration: BoxDecoration(
                          color: VColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: VType.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            VSpace.v05,
            Text(
              label,
              style: VType.caption.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isActive) ...[
              VSpace.v1,
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: VColors.accentPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Center navigation item with AI gradient
class _CenterNavItem extends StatelessWidget {
  const _CenterNavItem({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -8),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: VColors.aiGradient,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: VColors.aiGradientMid.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(VIcons.ai, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
