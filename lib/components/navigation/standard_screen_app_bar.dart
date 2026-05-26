import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/icons.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/typography.dart';

/// Compact push-screen app bar used on standard interactive screens.
class StandardScreenAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const StandardScreenAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.showBackButton = true,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool showBackButton;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final resolvedLeading = leading ??
        (showBackButton
            ? IconButton(
                icon: Icon(VIcons.back, color: VColors.text(context)),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null);

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: resolvedLeading,
      titleSpacing:
          resolvedLeading == null ? VSpace.screenActionInset : NavigationToolbar.kMiddleSpacing,
      title: Text(
        title,
        style: VType.screenTitle.copyWith(color: VColors.text(context)),
      ),
      actions: actions == null
          ? null
          : [
              for (final action in actions!) action,
              SizedBox(width: VSpace.screenActionInset - 8),
            ],
      bottom: bottom,
    );
  }
}
