import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/shadows.dart';

/// Toast notification type
enum ToastType { success, error, warning, info }

/// Toast notification data
class ToastData {
  const ToastData({
    required this.message,
    this.type = ToastType.info,
    this.action,
    this.actionLabel,
    this.duration = const Duration(seconds: 3),
  });

  final String message;
  final ToastType type;
  final VoidCallback? action;
  final String? actionLabel;
  final Duration duration;
}

/// Toast notification widget
class Toast extends StatelessWidget {
  const Toast({
    super.key,
    required this.data,
    this.onDismiss,
  });

  final ToastData data;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (data.type) {
      ToastType.success => (Icons.check_circle, VColors.success),
      ToastType.error => (Icons.error, VColors.error),
      ToastType.warning => (Icons.warning, VColors.warning),
      ToastType.info => (Icons.info, VColors.accentPrimary),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: VColors.card(context),
        borderRadius: VRadii.lgRadius,
        boxShadow: VShadow.level2,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data.message,
              style: VType.body.copyWith(color: VColors.text(context)),
            ),
          ),
          if (data.action != null && data.actionLabel != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: data.action,
              child: Text(
                data.actionLabel!,
                style: VType.label.copyWith(color: VColors.textLink),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: 18,
                color: VColors.textTer(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Toast manager mixin for StatefulWidget
mixin ToastManager<T extends StatefulWidget> on State<T> {
  OverlayEntry? _toastEntry;

  void showToast(ToastData data) {
    _dismissToast();

    _toastEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.paddingOf(context).bottom + 100,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Toast(
            data: data,
            onDismiss: _dismissToast,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_toastEntry!);

    Future.delayed(data.duration, _dismissToast);
  }

  void _dismissToast() {
    _toastEntry?.remove();
    _toastEntry = null;
  }

  @override
  void dispose() {
    _dismissToast();
    super.dispose();
  }
}
