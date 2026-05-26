import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/icons.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';

/// Large title navigation bar with collapse behavior (Apple HIG)
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.bottom,
    this.isCollapsed = false,
    this.showBackButton = false,
    this.onBackPressed,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool isCollapsed;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) {
      return _CollapsedBar(
        title: title,
        leading: leading,
        actions: actions,
        showBackButton: showBackButton,
        onBackPressed: onBackPressed,
      );
    }

    return _ExpandedBar(
      title: title,
      subtitle: subtitle,
      leading: leading,
      actions: actions,
      bottom: bottom,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
    );
  }
}

class _ExpandedBar extends StatelessWidget {
  const _ExpandedBar({
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.bottom,
    this.showBackButton = false,
    this.onBackPressed,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VColors.bgPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row with back button and actions
            if (showBackButton || actions != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    if (showBackButton)
                      IconButton(
                        icon: Icon(VIcons.back, color: VColors.text(context)),
                        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                      )
                    else if (leading != null)
                      leading!
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    ...?actions,
                  ],
                ),
              ),
            // Large title
            Padding(
              padding: EdgeInsets.fromLTRB(
                VSpace.screenMargin,
                showBackButton || actions != null ? 8 : 16,
                VSpace.screenMargin,
                bottom != null ? 8 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VType.display.copyWith(color: VColors.text(context)),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: VType.body.copyWith(color: VColors.textSec(context)),
                    ),
                  ],
                ],
              ),
            ),
            ?bottom,
          ],
        ),
      ),
    );
  }
}

class _CollapsedBar extends StatelessWidget {
  const _CollapsedBar({
    required this.title,
    this.leading,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44 + MediaQuery.paddingOf(context).top,
      decoration: BoxDecoration(
        color: VColors.card(context).withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: VColors.border(context), width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBackButton)
              IconButton(
                icon: Icon(VIcons.back, color: VColors.text(context)),
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              )
            else if (leading != null)
              leading!
            else
              const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: VType.h3.copyWith(color: VColors.text(context)),
                textAlign: TextAlign.center,
              ),
            ),
            if (actions != null)
              ...actions!
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

/// Sliver version of AppTopBar for use with CustomScrollView
class SliverAppTopBar extends StatelessWidget {
  const SliverAppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.bottom,
    this.showBackButton = false,
    this.onBackPressed,
    this.expandedHeight = 120,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(VIcons.back, color: VColors.text(context)),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(
          left: showBackButton ? 56 : VSpace.screenMargin,
          bottom: 16,
        ),
        title: Text(
          title,
          style: VType.h3.copyWith(color: VColors.text(context)),
        ),
        background: Container(
          color: VColors.bgPrimary,
          alignment: Alignment.bottomLeft,
          padding: EdgeInsets.fromLTRB(
            VSpace.screenMargin,
            0,
            VSpace.screenMargin,
            bottom != null ? 60 : 48,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: VType.display.copyWith(color: VColors.text(context)),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: VType.body.copyWith(color: VColors.textSec(context)),
                ),
              ],
            ],
          ),
        ),
      ),
      bottom: bottom,
    );
  }
}
