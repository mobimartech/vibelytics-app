import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';

/// App bottom sheet with handle and frosted background
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showHandle = true,
    this.showCloseButton = false,
    this.onClose,
    this.padding,
  });

  final Widget child;
  final String? title;
  final bool showHandle;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VColors.card(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          if (showHandle)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: VColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          // Header
          if (title != null || showCloseButton)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: VType.h3.copyWith(color: VColors.text(context)),
                    )
                  else
                    const Spacer(),
                  if (showCloseButton)
                    GestureDetector(
                      onTap: onClose ?? () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: VColors.textSec(context),
                      ),
                    ),
                ],
              ),
            ),
          // Content
          Flexible(
            child: Padding(
              padding: padding ?? VSpace.screenH,
              child: child,
            ),
          ),
          // Bottom safe area
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 20),
        ],
      ),
    );
  }

  /// Show as modal bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool showHandle = true,
    bool showCloseButton = false,
    bool isDismissible = true,
    bool enableDrag = true,
    EdgeInsets? padding,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      builder: (context) => AppBottomSheet(
        title: title,
        showHandle: showHandle,
        showCloseButton: showCloseButton,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Confirmation bottom sheet
class ConfirmationSheet extends StatelessWidget {
  const ConfirmationSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel,
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final bool isDestructive;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: VType.h3.copyWith(color: VColors.text(context)),
        ),
        VSpace.v2,
        Text(
          message,
          style: VType.body.copyWith(color: VColors.textSec(context)),
        ),
        VSpace.v6,
        // Confirm button
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDestructive ? VColors.error : VColors.accentPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: VRadii.lgRadius,
            ),
          ),
          child: Text(confirmLabel),
        ),
        VSpace.v2,
        // Cancel button
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            cancelLabel ?? 'Cancel',
            style: VType.label.copyWith(color: VColors.textSec(context)),
          ),
        ),
      ],
    );
  }

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    String? cancelLabel,
    bool isDestructive = false,
  }) {
    return AppBottomSheet.show<bool>(
      context: context,
      showHandle: true,
      child: ConfirmationSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
  }
}

/// Action sheet with list of options
class ActionSheet extends StatelessWidget {
  const ActionSheet({
    super.key,
    required this.actions,
    this.title,
    this.cancelLabel,
  });

  final List<ActionSheetItem> actions;
  final String? title;
  final String? cancelLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: VType.h3.copyWith(color: VColors.text(context)),
            textAlign: TextAlign.center,
          ),
          VSpace.v4,
        ],
        ...actions.map((action) => _ActionItem(action: action)),
        VSpace.v2,
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            cancelLabel ?? 'Cancel',
            style: VType.label.copyWith(color: VColors.textSec(context)),
          ),
        ),
      ],
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required List<ActionSheetItem> actions,
    String? title,
    String? cancelLabel,
  }) {
    return AppBottomSheet.show<T>(
      context: context,
      showHandle: true,
      child: ActionSheet(
        actions: actions,
        title: title,
        cancelLabel: cancelLabel,
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.action});

  final ActionSheetItem action;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(action.value);
        action.onTap?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            if (action.icon != null) ...[
              Icon(
                action.icon,
                size: 24,
                color: action.isDestructive
                    ? VColors.error
                    : VColors.textSec(context),
              ),
              VSpace.h3,
            ],
            Expanded(
              child: Text(
                action.label,
                style: VType.body.copyWith(
                  color: action.isDestructive
                      ? VColors.error
                      : VColors.text(context),
                ),
              ),
            ),
            if (action.trailing != null) action.trailing!,
          ],
        ),
      ),
    );
  }
}

class ActionSheetItem<T> {
  const ActionSheetItem({
    required this.label,
    this.icon,
    this.value,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  final String label;
  final IconData? icon;
  final T? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;
}
