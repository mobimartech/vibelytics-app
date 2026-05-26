import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/radii.dart';

/// Search bar with icon and clear button
class VSearchBar extends StatefulWidget {
  const VSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.placeholder,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? placeholder;
  final bool autofocus;

  @override
  State<VSearchBar> createState() => _VSearchBarState();
}

class _VSearchBarState extends State<VSearchBar> {
  late TextEditingController _controller;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _showClear = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (_showClear != hasText) {
      setState(() => _showClear = hasText);
    }
    widget.onChanged?.call(_controller.text);
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
        borderRadius: VRadii.mdRadius,
      ),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        onSubmitted: widget.onSubmitted,
        style: VType.body.copyWith(color: VColors.text(context)),
        cursorColor: VColors.accentPrimary,
        decoration: InputDecoration(
          hintText: widget.placeholder ?? 'common.search'.tr(),
          hintStyle: VType.body.copyWith(color: VColors.textTer(context)),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: VColors.textTer(context),
          ),
          suffixIcon: _showClear
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: VColors.textTer(context),
                  ),
                  onPressed: _clear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
