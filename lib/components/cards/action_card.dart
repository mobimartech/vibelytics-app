import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/shadows.dart';

/// Action card for navigation items (enhance hub, profile actions)
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.iconBackgroundColor,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final Color? iconBackgroundColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: VSpace.card,
        decoration: BoxDecoration(
          color: VColors.card(context),
          borderRadius: VRadii.xlRadius,
          boxShadow: VShadow.level1,
        ),
        child: Row(
          children: [
            // Icon
            if (icon != null) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackgroundColor ?? VColors.bgSec(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: VColors.accentPrimary,
                  size: 24,
                ),
              ),
              VSpace.h4,
            ],
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VType.h3.copyWith(color: VColors.text(context)),
                  ),
                  if (description != null) ...[
                    VSpace.v05,
                    Text(
                      description!,
                      style: VType.bodySm.copyWith(
                        color: VColors.textSec(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Trailing
            if (trailing != null)
              trailing!
            else if (showChevron)
              Icon(
                Icons.chevron_right,
                color: VColors.textTer(context),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact action row for lists
class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.label,
    this.icon,
    this.value,
    this.onTap,
    this.showDivider = false,
  });

  final String label;
  final IconData? icon;
  final String? value;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 24, color: VColors.textSec(context)),
                  VSpace.h3,
                ],
                Expanded(
                  child: Text(
                    label,
                    style: VType.body.copyWith(color: VColors.text(context)),
                  ),
                ),
                if (value != null) ...[
                  Text(
                    value!,
                    style: VType.body.copyWith(color: VColors.textSec(context)),
                  ),
                  VSpace.h2,
                ],
                Icon(
                  Icons.chevron_right,
                  color: VColors.textTer(context),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: VColors.border(context)),
      ],
    );
  }
}
