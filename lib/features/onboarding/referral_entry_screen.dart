import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/utils/haptics.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/credits_service.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/buttons/ghost_button.dart';
import '../../main_shell.dart';

/// Referral code entry screen
class ReferralEntryScreen extends StatefulWidget {
  const ReferralEntryScreen({super.key});

  @override
  State<ReferralEntryScreen> createState() => _ReferralEntryScreenState();
}

class _ReferralEntryScreenState extends State<ReferralEntryScreen> {
  final AuthService _authService = AuthService.instance;
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  int _creditsEarned = 0;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _applyCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.applyReferralCode(code);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      VHaptics.success();
      setState(() {
        _isSuccess = true;
        _creditsEarned = result.creditsEarned;
      });

      // Navigate after showing success
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        _navigateToMain();
      }
    } else {
      VHaptics.error();
      setState(() {
        _errorMessage = result.errorKey;
      });
    }
  }

  Future<void> _navigateToMain() async {
    final couponResult = await CreditsService.instance.applyPendingCoupon();

    if (mounted && couponResult != null) {
      if (couponResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'credits.credits_added'
                  .tr(args: ['${couponResult.creditsGranted}']),
            ),
            backgroundColor: VColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((couponResult.errorKey ?? 'credits.redeem_failed').tr()),
            backgroundColor: VColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: VColors.text(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          VGhostButton(
            label: 'common.skip'.tr(),
            onPressed: _navigateToMain,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: VSpace.screenH,
          child: Column(
            children: [
              VSpace.v6,

              // Illustration placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: VColors.teal50,
                  borderRadius: VRadii.xlRadius,
                ),
                child: Center(
                  child: Icon(
                    Icons.card_giftcard,
                    size: 56,
                    color: VColors.accentSecondary,
                  ),
                ),
              ),

              VSpace.v6,

              // Title
              Text(
                'onboarding.referral_title'.tr(),
                style: VType.h2.copyWith(color: VColors.text(context)),
                textAlign: TextAlign.center,
              ),
              VSpace.v2,

              // Subtitle
              Text(
                'onboarding.referral_subtitle'.tr(),
                style: VType.body.copyWith(color: VColors.textSec(context)),
                textAlign: TextAlign.center,
              ),

              VSpace.v6,

              // Code input or success state
              if (_isSuccess)
                _SuccessIndicator(creditsEarned: _creditsEarned)
              else
                Column(
                  children: [
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      style: VType.bodyLg.copyWith(color: VColors.text(context)),
                      decoration: InputDecoration(
                        hintText: 'onboarding.referral_placeholder'.tr(),
                        hintStyle: VType.bodyLg.copyWith(color: VColors.textTer(context)),
                        prefixIcon: Icon(
                          Icons.card_giftcard,
                          color: VColors.textTer(context),
                        ),
                        filled: true,
                        fillColor: VColors.bgSec(context),
                        border: OutlineInputBorder(
                          borderRadius: VRadii.lgRadius,
                          borderSide: BorderSide(
                            color: _errorMessage != null
                                ? VColors.error
                                : VColors.borderSubtle,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: VRadii.lgRadius,
                          borderSide: BorderSide(
                            color: _errorMessage != null
                                ? VColors.error
                                : VColors.borderSubtle,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: VRadii.lgRadius,
                          borderSide: BorderSide(
                            color: _errorMessage != null
                                ? VColors.error
                                : VColors.accentPrimary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() => _errorMessage = null),
                    ),
                    if (_errorMessage != null) ...[
                      VSpace.v2,
                      Text(
                        _errorMessage!.tr(),
                        style: VType.bodySm.copyWith(color: VColors.error),
                      ),
                    ],
                  ],
                ),

              VSpace.v4,

              // Apply button
              if (!_isSuccess)
                VPrimaryButton(
                  label: 'onboarding.referral_apply'.tr(),
                  onPressed: _applyCode,
                  isLoading: _isLoading,
                  isEnabled: _codeController.text.isNotEmpty,
                ),

              VSpace.v4,

              // Skip link
              if (!_isSuccess)
                VGhostButton(
                  label: 'onboarding.referral_skip'.tr(),
                  onPressed: _navigateToMain,
                ),

              const Spacer(),

              // Bonus text
              Text(
                'onboarding.referral_bonus'.tr(),
                style: VType.bodySm.copyWith(color: VColors.accentSecondary),
                textAlign: TextAlign.center,
              ),
              VSpace.v6,
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessIndicator extends StatelessWidget {
  const _SuccessIndicator({required this.creditsEarned});

  final int creditsEarned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: VColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: VColors.success,
              size: 32,
            ),
          ),
          VSpace.v4,
          Text(
            '+$creditsEarned ${'credits.balance'.tr(args: [creditsEarned.toString()])}',
            style: VType.h3.copyWith(color: VColors.success),
          ),
        ],
      ),
    );
  }
}
