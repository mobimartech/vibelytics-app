import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/spacing.dart';

/// Shared compact bottom CTA surface for standard screens.
class BottomActionBarSurface extends StatelessWidget {
  const BottomActionBarSurface({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        VSpace.bottomBarHorizontal,
        VSpace.bottomBarVertical,
        VSpace.bottomBarHorizontal,
        MediaQuery.paddingOf(context).bottom + VSpace.bottomBarVertical,
      ),
      decoration: BoxDecoration(
        color: VColors.card(context),
        border: Border(
          top: BorderSide(color: VColors.border(context)),
        ),
      ),
      child: child,
    );
  }
}
