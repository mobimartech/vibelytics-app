import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/utils/haptics.dart';
import '../../core/services/auth_service.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/buttons/ghost_button.dart';
import 'referral_entry_screen.dart';

/// OTP verification screen for WhatsApp/Telegram authentication
class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.provider,
    required this.phoneNumber,
  });

  final String provider; // 'telegram' or 'whatsapp'
  final String phoneNumber;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final AuthService _authService = AuthService.instance;
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendSeconds = 60;
  Timer? _timer;
  bool _isLoading = false;
  bool _isRequestingOtp = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _requestOtp();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer(int seconds) {
    _resendSeconds = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otp.length == 6;

  String get _maskedPhone {
    final phone = widget.phoneNumber;
    if (phone.length > 6) {
      return '${phone.substring(0, 4)}***${phone.substring(phone.length - 3)}';
    }
    return phone;
  }

  Future<void> _requestOtp() async {
    if (_isRequestingOtp) return;

    setState(() {
      _isRequestingOtp = true;
      _hasError = false;
      _errorMessage = null;
    });

    final result = await _authService.requestOtp(
      provider: widget.provider,
      phoneNumber: widget.phoneNumber,
    );

    if (!mounted) return;

    setState(() => _isRequestingOtp = false);

    if (result.isSuccess) {
      _startResendTimer(result.expiresIn ~/ 5); // Resend timer is shorter than expiry
    } else {
      _showError(result.errorKey ?? 'auth.otp_request_failed');
    }
  }

  void _onDigitChanged(int index, String value) {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });

    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_isOtpComplete) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    if (_isLoading || !_isOtpComplete) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    final result = await _authService.verifyOtp(
      provider: widget.provider,
      phoneNumber: widget.phoneNumber,
      otpCode: _otp,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      VHaptics.success();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ReferralEntryScreen()),
      );
    } else if (result.isError) {
      VHaptics.error();
      setState(() {
        _hasError = true;
        _errorMessage = result.errorKey;
      });
      // Clear OTP fields on error
      for (final controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  void _resendCode() {
    if (_resendSeconds > 0 || _isRequestingOtp) return;
    VHaptics.light();
    _requestOtp();
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
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: VColors.text(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: VSpace.screenH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VSpace.v4,

              // Title
              Text(
                'auth.otp_title'.tr(),
                style: VType.h2.copyWith(color: VColors.text(context)),
              ),
              VSpace.v2,

              // Subtitle
              Text(
                'auth.otp_subtitle'.tr(args: [_maskedPhone]),
                style: VType.body.copyWith(color: VColors.textSec(context)),
              ),

              VSpace.v8,

              // OTP Input boxes
              if (_isRequestingOtp)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      VSpace.v4,
                      Text(
                        'auth.otp_sending'.tr(),
                        style: VType.body.copyWith(color: VColors.textSec(context)),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return _OtpBox(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      hasError: _hasError,
                      onChanged: (value) => _onDigitChanged(index, value),
                    );
                  }),
                ),

              if (_hasError && _errorMessage != null) ...[
                VSpace.v4,
                Text(
                  _errorMessage!.tr(),
                  style: VType.bodySm.copyWith(color: VColors.error),
                ),
              ],

              VSpace.v4,

              // Resend code
              Center(
                child: _resendSeconds > 0
                    ? Text(
                        'auth.otp_resend_countdown'.tr(
                          args: ['0:${_resendSeconds.toString().padLeft(2, '0')}'],
                        ),
                        style: VType.body.copyWith(color: VColors.textTer(context)),
                      )
                    : VGhostButton(
                        label: 'auth.otp_resend'.tr(),
                        onPressed: _resendCode,
                      ),
              ),

              VSpace.v8,

              // Verify button
              VPrimaryButton(
                label: 'auth.otp_verify'.tr(),
                onPressed: _isOtpComplete ? _verifyOtp : null,
                isLoading: _isLoading,
                isEnabled: _isOtpComplete && !_isRequestingOtp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;
    final isFilled = controller.text.isNotEmpty;

    return SizedBox(
      width: 48,
      height: 52,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: VType.h2.copyWith(color: VColors.text(context)),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: VColors.background(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError
                  ? VColors.error
                  : isFocused
                      ? VColors.accentPrimary
                      : isFilled
                          ? VColors.borderStrong
                          : VColors.borderSubtle,
              width: isFocused ? 2 : 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError
                  ? VColors.error
                  : isFilled
                      ? VColors.borderStrong
                      : VColors.borderSubtle,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? VColors.error : VColors.accentPrimary,
              width: 2,
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
