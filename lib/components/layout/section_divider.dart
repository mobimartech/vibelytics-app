import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';

/// Section divider with optional label
class SectionDivider extends StatelessWidget {
  const SectionDivider({
    super.key,
    this.label,
    this.showLine = true,
  });

  final String? label;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Divider(
        height: 1,
        color: VColors.border(context),
      );
    }

    return Row(
      children: [
        if (showLine)
          Expanded(
            child: Divider(
              color: VColors.border(context),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label!,
            style: VType.caption.copyWith(
              color: VColors.textTer(context),
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (showLine)
          Expanded(
            child: Divider(
              color: VColors.border(context),
            ),
          ),
      ],
    );
  }
}

/// Section header with title and optional action
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: VSpace.screenH,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: VType.h3.copyWith(color: VColors.text(context)),
          ),
          if (action != null)
            action!
          else if (actionLabel != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionLabel!,
                style: VType.label.copyWith(color: VColors.textLink),
              ),
            ),
        ],
      ),
    );
  }
}
