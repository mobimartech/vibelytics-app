import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/credits_service.dart';
import '../../core/services/deep_link_service.dart';
import '../../core/utils/app_logger.dart';
import 'referral_entry_screen.dart';

/// Authentication gate screen with social login options
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final AuthService _authService = AuthService.instance;
  bool _isLoading = false;
  String? _loadingProvider;
  bool _showCouponField = false;
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _handleAppleLogin() async {
    if (_isLoading) return;

    AppLogger.i('AuthGate: Apple login button pressed');

    setState(() {
      _isLoading = true;
      _loadingProvider = 'apple';
    });

    try {
      final result = await _authService.signInWithApple();

      if (!mounted) return;

      if (result.isSuccess) {
        _trackDeepLinkReferral();
        _navigateToReferral();
      } else if (result.isCancelled) {
        AppLogger.i('AuthGate: Apple login cancelled by user');
      } else if (result.isError) {
        _showError(result.errorKey ?? 'auth.unknown_error');
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'AuthGate: Uncaught exception during Apple login',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        _showError('auth.unknown_error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;

    AppLogger.i('AuthGate: Google login button pressed');

    setState(() {
      _isLoading = true;
      _loadingProvider = 'google';
    });

    try {
      AppLogger.d('AuthGate: Calling signInWithGoogle...');
      final result = await _authService.signInWithGoogle();
      AppLogger.d(
        'AuthGate: signInWithGoogle returned - success: ${result.isSuccess}, cancelled: ${result.isCancelled}, error: ${result.isError}',
      );

      if (!mounted) {
        AppLogger.w('AuthGate: Widget not mounted after sign-in');
        return;
      }

      if (result.isSuccess) {
        AppLogger.i('AuthGate: Login successful');
        // Track referral if user arrived via deep link
        _trackDeepLinkReferral();
        _navigateToReferral();
      } else if (result.isCancelled) {
        AppLogger.i('AuthGate: Login cancelled by user');
      } else if (result.isError) {
        AppLogger.e('AuthGate: Login error - ${result.errorKey}');
        _showError(result.errorKey ?? 'auth.unknown_error');
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'AuthGate: Uncaught exception during Google login',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showError('auth.unknown_error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
      }
    }
  }

  Future<void> _trackDeepLinkReferral() async {
    final code = await DeepLinkService.instance.consumePendingReferral();
    if (code != null) {
      DeepLinkService.instance.trackReferralSignup(code);
    }
  }

  void _navigateToReferral() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ReferralEntryScreen()),
    );
  }

  void _showError(String errorKey) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorKey.tr()),
        backgroundColor: VColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: VSpace.screenH,
          child: Column(
            children: [
              VSpace.v12,

              // Logo
              Text(
                'app_name'.tr(),
                style: VType.h1.copyWith(color: VColors.text(context)),
              ),

              VSpace.v8,

              // Welcome text
              Text(
                'auth.welcome_title'.tr(),
                style: VType.display.copyWith(color: VColors.text(context)),
              ),
              VSpace.v2,
              Text(
                'auth.welcome_subtitle'.tr(),
                style: VType.bodyLg.copyWith(color: VColors.textSec(context)),
              ),

              VSpace.v8,

              // Social login buttons
              // if (AuthService.isGoogleSignInAvailable)
              _SocialButton(
                label: 'auth.login_google'.tr(),
                image: "assets/images/google.png",
                icon: Icons.g_mobiledata,
                // Google brand: always white background + dark text,
                // regardless of app theme.
                backgroundColor: VColors.google,
                textColor: VColors.grey900,
                borderColor: VColors.grey300,
                isLoading: _loadingProvider == 'google',
                onTap: _isLoading ? null : _handleGoogleLogin,
              ),

              VSpace.v4,

              if (AuthService.isAppleSignInAvailable)
                _SocialButton(
                  label: 'auth.login_apple'.tr(),
                  icon: Icons.apple,
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  isLoading: _loadingProvider == 'apple',
                  onTap: _isLoading ? null : _handleAppleLogin,
                ),
              VSpace.v4,

              // Coupon entry toggle
              TextButton.icon(
                onPressed: () {
                  setState(() => _showCouponField = !_showCouponField);
                },
                icon: Icon(
                  Icons.card_giftcard,
                  size: 18,
                  color: VColors.accentPrimary,
                ),
                label: Text(
                  'auth.have_coupon'.tr(),
                  style: VType.bodySm.copyWith(color: VColors.accentPrimary),
                ),
              ),

              // Expandable coupon field
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _showCouponField
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          children: [
                            TextField(
                              controller: _couponController,
                              textCapitalization: TextCapitalization.characters,
                              style: VType.body.copyWith(
                                color: VColors.text(context),
                              ),
                              decoration: InputDecoration(
                                hintText: 'credits.enter_coupon_hint'.tr(),
                                hintStyle: VType.body.copyWith(
                                  color: VColors.textTer(context),
                                ),
                                filled: true,
                                fillColor: VColors.bgSec(context),
                                border: OutlineInputBorder(
                                  borderRadius: VRadii.mdRadius,
                                  borderSide: BorderSide(
                                    color: VColors.border(context),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: VRadii.mdRadius,
                                  borderSide: BorderSide(
                                    color: VColors.border(context),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: VRadii.mdRadius,
                                  borderSide: BorderSide(
                                    color: VColors.accentPrimary,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (value) {
                                CreditsService.instance.setPendingCouponCode(
                                  value,
                                );
                              },
                            ),
                            VSpace.v1,
                            Text(
                              'auth.coupon_apply_after_login'.tr(),
                              style: VType.caption.copyWith(
                                color: VColors.textTer(context),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const Spacer(),

              // Terms text with tappable links
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: VType.caption.copyWith(
                    color: VColors.textTer(context),
                  ),
                  children: [
                    TextSpan(text: 'auth.terms_preamble'.tr()),
                    TextSpan(
                      text: 'auth.terms_link'.tr(),
                      style: VType.caption.copyWith(
                        color: VColors.accentPrimary,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(
                          Uri.parse('https://vibelytics.org/terms.html'),
                          mode: LaunchMode.externalApplication,
                        ),
                    ),
                    TextSpan(text: 'auth.terms_and'.tr()),
                    TextSpan(
                      text: 'auth.privacy_link'.tr(),
                      style: VType.caption.copyWith(
                        color: VColors.accentPrimary,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(
                          Uri.parse('https://vibelytics.org/privacy.html'),
                          mode: LaunchMode.externalApplication,
                        ),
                    ),
                  ],
                ),
              ),
              VSpace.v6,
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.image,
    this.isLoading = false,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final String? image;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null && !isLoading ? 0.5 : 1.0,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: VRadii.lgRadius,
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              else
                image != null
                    ? Image.asset(image!, height: 27)
                    : Icon(icon, color: textColor, size: 24),
              VSpace.h3,
              Text(label, style: VType.label.copyWith(color: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phone number input bottom sheet for OTP authentication
class _PhoneInputSheet extends StatefulWidget {
  const _PhoneInputSheet({required this.provider, required this.onSubmit});

  final String provider;
  final void Function(String phoneNumber) onSubmit;

  @override
  State<_PhoneInputSheet> createState() => _PhoneInputSheetState();
}

class _PhoneInputSheetState extends State<_PhoneInputSheet> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _countryCode = '+1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber => '$_countryCode${_phoneController.text.trim()}';

  bool get _isValidPhone => _phoneController.text.trim().length >= 8;

  void _submit() {
    if (_isValidPhone) {
      widget.onSubmit(_fullPhoneNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;
    final providerName = widget.provider == 'whatsapp'
        ? 'WhatsApp'
        : 'Telegram';

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: VColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          VSpace.v4,

          // Title
          Text(
            'auth.enter_phone'.tr(args: [providerName]),
            style: VType.h3.copyWith(color: VColors.text(context)),
          ),
          VSpace.v2,
          Text(
            'auth.phone_subtitle'.tr(args: [providerName]),
            style: VType.body.copyWith(color: VColors.textSec(context)),
          ),
          VSpace.v4,

          // Phone input
          Row(
            children: [
              // Country code selector
              GestureDetector(
                onTap: () => _showCountryCodePicker(),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: VColors.adaptive(
                      context,
                      light: VColors.bgSecondary,
                      dark: VColors.bgSecondaryDark,
                    ),
                    borderRadius: VRadii.mdRadius,
                    border: Border.all(color: VColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _countryCode,
                        style: VType.bodyLg.copyWith(
                          color: VColors.text(context),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: VColors.textSec(context),
                      ),
                    ],
                  ),
                ),
              ),
              VSpace.h2,
              // Phone number field
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.phone,
                  style: VType.bodyLg.copyWith(color: VColors.text(context)),
                  decoration: InputDecoration(
                    hintText: 'auth.phone_placeholder'.tr(),
                    hintStyle: VType.bodyLg.copyWith(
                      color: VColors.textTer(context),
                    ),
                    filled: true,
                    fillColor: VColors.bgSec(context),
                    border: OutlineInputBorder(
                      borderRadius: VRadii.mdRadius,
                      borderSide: BorderSide(color: VColors.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: VRadii.mdRadius,
                      borderSide: BorderSide(color: VColors.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: VRadii.mdRadius,
                      borderSide: BorderSide(color: VColors.accentPrimary),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
          VSpace.v4,

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isValidPhone ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: VColors.accentPrimary,
                disabledBackgroundColor: VColors.bgSec(context),
                shape: RoundedRectangleBorder(borderRadius: VRadii.lgRadius),
              ),
              child: Text(
                'common.continue'.tr(),
                style: VType.label.copyWith(
                  color: _isValidPhone
                      ? Colors.white
                      : VColors.textTer(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CountryCodePicker(
        selectedCode: _countryCode,
        onSelect: (code) {
          setState(() => _countryCode = code);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Country code picker
class _CountryCodePicker extends StatelessWidget {
  const _CountryCodePicker({
    required this.selectedCode,
    required this.onSelect,
  });

  final String selectedCode;
  final void Function(String code) onSelect;

  static const _countryCodes = [
    ('+1', 'United States'),
    ('+44', 'United Kingdom'),
    ('+971', 'UAE'),
    ('+966', 'Saudi Arabia'),
    ('+20', 'Egypt'),
    ('+91', 'India'),
    ('+92', 'Pakistan'),
    ('+880', 'Bangladesh'),
    ('+62', 'Indonesia'),
    ('+60', 'Malaysia'),
    ('+63', 'Philippines'),
    ('+84', 'Vietnam'),
    ('+234', 'Nigeria'),
    ('+27', 'South Africa'),
    ('+49', 'Germany'),
    ('+33', 'France'),
    ('+39', 'Italy'),
    ('+34', 'Spain'),
    ('+55', 'Brazil'),
    ('+52', 'Mexico'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'auth.select_country'.tr(),
            style: VType.h3.copyWith(color: VColors.text(context)),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _countryCodes.length,
            itemBuilder: (context, index) {
              final (code, name) = _countryCodes[index];
              final isSelected = code == selectedCode;

              return ListTile(
                leading: Text(
                  code,
                  style: VType.bodyLg.copyWith(
                    color: isSelected
                        ? VColors.accentPrimary
                        : VColors.text(context),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                title: Text(
                  name,
                  style: VType.body.copyWith(color: VColors.textSec(context)),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: VColors.accentPrimary)
                    : null,
                onTap: () => onSelect(code),
              );
            },
          ),
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ],
    );
  }
}
