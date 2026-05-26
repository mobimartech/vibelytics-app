import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/durations.dart';
import '../../core/utils/haptics.dart';

/// Horizontal segment tab bar for switching between views
class TabBarSegment extends StatelessWidget {
  const TabBarSegment({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.isScrollable = false,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: isScrollable ? MainAxisSize.min : MainAxisSize.max,
      children: List.generate(tabs.length, (index) {
        final isSelected = index == selectedIndex;
        return Flexible(
          fit: isScrollable ? FlexFit.loose : FlexFit.tight,
          child: _SegmentTab(
            label: tabs[index],
            isSelected: isSelected,
            onTap: () {
              VHaptics.light();
              onTabChanged(index);
            },
          ),
        );
      }),
    );

    if (isScrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
          borderRadius: VRadii.lgRadius,
        ),
        child: content,
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: VDuration.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? VColors.surfaceCard : Colors.transparent,
          borderRadius: VRadii.mdRadius,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: VType.label.copyWith(
            color: isSelected ? VColors.text(context) : VColors.textSec(context),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Underlined tab bar variant (for full-width sections)
class TabBarUnderline extends StatelessWidget {
  const TabBarUnderline({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: VColors.border(context), width: 1),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                VHaptics.light();
                onTabChanged(index);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? VColors.accentPrimary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  style: VType.label.copyWith(
                    color: isSelected ? VColors.accentPrimary : VColors.textSec(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Pill-style scrollable tabs (like tag filters)
class TabBarPills extends StatelessWidget {
  const TabBarPills({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: index < tabs.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                VHaptics.light();
                onTabChanged(index);
              },
              child: AnimatedContainer(
                duration: VDuration.fast,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? VColors.accentPrimary : Colors.transparent,
                  borderRadius: VRadii.xlRadius,
                  border: Border.all(
                    color: isSelected ? VColors.accentPrimary : VColors.borderStrong,
                    width: 1,
                  ),
                ),
                child: Text(
                  tabs[index],
                  style: VType.label.copyWith(
                    color: isSelected ? Colors.white : VColors.text(context),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
