import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../core/services/credits_service.dart';
import '../../main_shell.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/layout/bottom_action_bar_surface.dart';
import '../../components/navigation/standard_screen_app_bar.dart';

/// Coupon entry screen for redeeming promo codes
class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  final _couponController = TextEditingController();
  bool _isValidating = false;
  String? _errorMessage;
  bool _isSuccess = false;
  int _creditsEarned = 0;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'credits.enter_code'.tr());
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _isSuccess = false;
    });

    // First validate the coupon
    final validation = await CreditsService.instance.validateCoupon(code);

    if (!mounted) return;

    if (validation == null || !validation.canUse) {
      VHaptics.error();
      setState(() {
        _isValidating = false;
        _errorMessage = 'credits.invalid_coupon'.tr();
      });
      return;
    }

    // Coupon is valid, redeem it
    final result = await CreditsService.instance.redeemCoupon(code);

    if (!mounted) return;

    if (result.isSuccess) {
      VHaptics.success();
      MainShell.refreshCredits(force: true);
      setState(() {
        _isValidating = false;
        _isSuccess = true;
        _creditsEarned = result.creditsGranted;
      });
    } else {
      VHaptics.error();
      setState(() {
        _isValidating = false;
        _errorMessage = (result.errorKey ?? 'credits.redeem_failed').tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'credits.redeem_coupon'.tr(),
      ),
      bottomNavigationBar: BottomActionBarSurface(
        child: PrimaryButton(
          label: _isSuccess
              ? 'common.done'.tr()
              : 'credits.apply_coupon'.tr(),
          onPressed:
              _isSuccess ? () => Navigator.of(context).pop(true) : _applyCoupon,
          isLoading: !_isSuccess && _isValidating,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: VSpace.screenH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: VSpace.screenTopGap),

              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: VColors.accentPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    VIcons.gift,
                    size: 40,
                    color: VColors.accentPrimary,
                  ),
                ),
              ),

              VSpace.v6,

              // Title
              Center(
                child: Text(
                  'credits.have_coupon'.tr(),
                  style: VType.screenSectionTitle.copyWith(
                    color: VColors.text(context),
                  ),
                ),
              ),
              VSpace.v2,
              Center(
                child: Text(
                  'credits.coupon_description'.tr(),
                  style: VType.body.copyWith(color: VColors.textSec(context)),
                  textAlign: TextAlign.center,
                ),
              ),

              VSpace.v8,

              // Coupon input
              Text(
                'credits.coupon_code'.tr(),
                style: VType.label.copyWith(color: VColors.text(context)),
              ),
              VSpace.v2,
              TextField(
                controller: _couponController,
                textCapitalization: TextCapitalization.characters,
                enabled: !_isSuccess,
                style: VType.body.copyWith(color: VColors.text(context)),
                decoration: InputDecoration(
                  hintText: 'credits.enter_coupon_hint'.tr(),
                  hintStyle: VType.body.copyWith(color: VColors.textTer(context)),
                  filled: true,
                  fillColor: VColors.bgSec(context),
                  border: OutlineInputBorder(
                    borderRadius: VRadii.mdRadius,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                VSpace.v2,
                Row(
                  children: [
                    Icon(VIcons.error, size: 16, color: VColors.error),
                    VSpace.h1,
                    Text(
                      _errorMessage!,
                      style: VType.bodySm.copyWith(color: VColors.error),
                    ),
                  ],
                ),
              ],

              if (_isSuccess) ...[
                VSpace.v4,
                _SuccessCard(creditsEarned: _creditsEarned),
              ],

              SizedBox(height: VSpace.screenSectionGap),

              // Info text
              Container(
                padding: VSpace.card,
                decoration: BoxDecoration(
                  color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                  borderRadius: VRadii.lgRadius,
                ),
                child: Row(
                  children: [
                    Icon(
                      VIcons.info,
                      size: 20,
                      color: VColors.textSec(context),
                    ),
                    VSpace.h3,
                    Expanded(
                      child: Text(
                        'credits.coupon_info'.tr(),
                        style: VType.bodySm.copyWith(color: VColors.textSec(context)),
                      ),
                    ),
                  ],
                ),
              ),

              VSpace.v4,
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.creditsEarned});

  final int creditsEarned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VColors.success.withValues(alpha: 0.1),
        borderRadius: VRadii.lgRadius,
        border: Border.all(
          color: VColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            VIcons.checkCircle,
            size: 48,
            color: VColors.success,
          ),
          VSpace.v3,
          Text(
            'credits.coupon_success'.tr(),
            style: VType.h3.copyWith(color: VColors.success),
          ),
          VSpace.v1,
          Text(
            'credits.credits_added'.tr(args: ['$creditsEarned']),
            style: VType.body.copyWith(color: VColors.textSec(context)),
          ),
        ],
      ),
    );
  }
}
