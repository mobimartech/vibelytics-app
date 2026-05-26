import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/services/credits_service.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/app_logger.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/feedback/credit_badge.dart';
import '../../components/navigation/standard_screen_app_bar.dart';
import '../../main_shell.dart';

/// Buy credits screen with coupon redemption
class BuyCreditsScreen extends StatefulWidget {
  const BuyCreditsScreen({super.key});

  @override
  State<BuyCreditsScreen> createState() => _BuyCreditsScreenState();
}

class _BuyCreditsScreenState extends State<BuyCreditsScreen> {
  final _couponController = TextEditingController();
  bool _isRedeeming = false;
  String? _couponError;
  String? _couponSuccess;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _redeemCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() => _couponError = 'credits.enter_code'.tr());
      return;
    }

    setState(() {
      _isRedeeming = true;
      _couponError = null;
      _couponSuccess = null;
    });

    try {
      final result = await CreditsService.instance.redeemCoupon(code);

      if (!mounted) return;

      if (result.isSuccess) {
        VHaptics.success();
        await MainShell.refreshCredits(force: true);
        if (!mounted) return;
        setState(() {
          _couponSuccess = 'credits.credits_added'.tr(args: ['${result.creditsGranted}']);
          _couponController.clear();
          _isRedeeming = false;
        });
      } else {
        setState(() {
          _couponError = result.errorKey?.tr() ?? 'credits.invalid_coupon'.tr();
          _isRedeeming = false;
        });
      }
    } catch (e) {
      AppLogger.e('Redeem coupon error', error: e);
      if (mounted) {
        setState(() {
          _couponError = 'credits.redeem_failed'.tr();
          _isRedeeming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'credits.buy_title'.tr(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: VSpace.screenH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VSpace.v4,

              // Current balance
              Container(
                padding: VSpace.card,
                decoration: BoxDecoration(
                  color: VColors.accentPrimary.withValues(alpha: 0.1),
                  borderRadius: VRadii.lgRadius,
                ),
                child: Row(
                  children: [
                    Icon(
                      VIcons.wallet,
                      color: VColors.accentPrimary,
                      size: 24,
                    ),
                    VSpace.h3,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'credits.current_balance'.tr(),
                          style: VType.caption.copyWith(
                            color: VColors.textSec(context),
                          ),
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: MainShell.creditNotifier,
                          builder: (_, credits, _) => Text(
                            'credits.balance'.tr(args: ['$credits']),
                            style: VType.h3.copyWith(
                              color: creditTierColor(credits),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              VSpace.v8,

              // Coupon section
              Text(
                'credits.have_coupon'.tr(),
                style: VType.screenSectionTitle.copyWith(
                  color: VColors.text(context),
                ),
              ),
              VSpace.v2,
              Text(
                'credits.coupon_description'.tr(),
                style: VType.bodySm.copyWith(color: VColors.textSec(context)),
              ),

              VSpace.v4,

              // Coupon input
              TextField(
                controller: _couponController,
                textCapitalization: TextCapitalization.characters,
                style: VType.body.copyWith(color: VColors.text(context)),
                decoration: InputDecoration(
                  hintText: 'credits.enter_coupon_hint'.tr(),
                  hintStyle: VType.body.copyWith(color: VColors.textTer(context)),
                  filled: true,
                  fillColor: VColors.bgSec(context),
                  border: OutlineInputBorder(
                    borderRadius: VRadii.lgRadius,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: VRadii.lgRadius,
                    borderSide: BorderSide(color: VColors.accentPrimary),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: Icon(
                    VIcons.gift,
                    color: VColors.textTer(context),
                  ),
                ),
                onChanged: (_) {
                  if (_couponError != null || _couponSuccess != null) {
                    setState(() {
                      _couponError = null;
                      _couponSuccess = null;
                    });
                  }
                },
              ),

              // Error / success message
              if (_couponError != null) ...[
                VSpace.v2,
                Text(
                  _couponError!,
                  style: VType.bodySm.copyWith(color: VColors.error),
                ),
              ],
              if (_couponSuccess != null) ...[
                VSpace.v2,
                Text(
                  _couponSuccess!,
                  style: VType.bodySm.copyWith(color: VColors.success),
                ),
              ],

              VSpace.v4,

              PrimaryButton(
                label: _isRedeeming
                    ? 'common.loading'.tr()
                    : 'credits.apply_coupon'.tr(),
                onPressed: _isRedeeming ? null : _redeemCoupon,
              ),

              VSpace.v6,

              // Info text
              Container(
                padding: VSpace.card,
                decoration: BoxDecoration(
                  color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                  borderRadius: VRadii.lgRadius,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(VIcons.info, size: 18, color: VColors.textTer(context)),
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

              VSpace.v6,

              // Earn free credits hint
              Container(
                padding: VSpace.card,
                decoration: BoxDecoration(
                  color: VColors.accentSecondary.withValues(alpha: 0.08),
                  borderRadius: VRadii.lgRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'credits.earn_free_title'.tr(),
                      style: VType.label.copyWith(color: VColors.text(context)),
                    ),
                    VSpace.v2,
                    Row(
                      children: [
                        Icon(VIcons.star, size: 16, color: VColors.accentSecondary),
                        VSpace.h2,
                        Expanded(
                          child: Text(
                            'credits.per_action'.tr(),
                            style: VType.bodySm.copyWith(color: VColors.textSec(context)),
                          ),
                        ),
                      ],
                    ),
                    VSpace.v1,
                    Row(
                      children: [
                        Icon(VIcons.userPlus, size: 16, color: VColors.accentSecondary),
                        VSpace.h2,
                        Expanded(
                          child: Text(
                            'credits.per_signup'.tr(),
                            style: VType.bodySm.copyWith(color: VColors.textSec(context)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              VSpace.v8,
            ],
          ),
        ),
      ),
    );
  }
}
