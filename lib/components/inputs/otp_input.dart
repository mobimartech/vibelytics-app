import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/radii.dart';
import '../../core/utils/haptics.dart';

/// OTP input with 6 digit boxes
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.length = 6,
  });

  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final int length;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _currentCode {
    return _controllers.map((c) => c.text).join();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final pastedCode = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (pastedCode.length >= widget.length && _focusNodes.isNotEmpty) {
        for (int i = 0; i < widget.length; i++) {
          _controllers[i].text = pastedCode[i];
        }
        _focusNodes.last.requestFocus();
        VHaptics.success();
        widget.onCompleted(pastedCode.substring(0, widget.length));
        return;
      }
    }

    widget.onChanged?.call(_currentCode);

    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
      VHaptics.light();
    }

    if (_currentCode.length == widget.length) {
      VHaptics.success();
      widget.onCompleted(_currentCode);
    }
  }

  void _onKeyPressed(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
        VHaptics.light();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        final isLast = index == widget.length - 1;
        return Padding(
          padding: EdgeInsets.only(right: isLast ? 0 : 8),
          child: SizedBox(
            width: 48,
            height: 56,
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) => _onKeyPressed(index, event),
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: VType.h2.copyWith(color: VColors.text(context)),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) => _onChanged(index, value),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: VColors.bgSec(context),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: VRadii.mdRadius,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: VRadii.mdRadius,
                    borderSide: BorderSide(
                      color: widget.hasError
                          ? VColors.error
                          : _controllers[index].text.isNotEmpty
                              ? VColors.accentPrimary.withValues(alpha: 0.3)
                              : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: VRadii.mdRadius,
                    borderSide: BorderSide(
                      color:
                          widget.hasError ? VColors.error : VColors.accentPrimary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
