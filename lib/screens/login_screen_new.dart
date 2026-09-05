import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:juslegal/core/core.dart';
import 'package:juslegal/core/router/otp_route_params.dart';
import 'package:juslegal/core/utils/phone_number_validator.dart';
import '../l10n/gen/app_localizations.dart';
import '../services/auth_handler.dart';
import '../widgets/error_boundary.dart';
import '../widgets/loading_widget.dart';

enum AuthStep { initial, emailForm, phoneForm }

const _background = Color(0xFFEAF8E6);
const _forest = Color(0xFF1B4D3E);
const _green = Color(0xFF2D6A4F);

class LoginScreenNew extends ConsumerStatefulWidget {
  const LoginScreenNew({super.key});
  @override
  ConsumerState<LoginScreenNew> createState() => _LoginScreenNewState();
}

class _LoginScreenNewState extends ConsumerState<LoginScreenNew>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _animation; // ✅ FIX: Moved to initState
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TapGestureRecognizer _terms;
  late final TapGestureRecognizer _privacy;
  late final TapGestureRecognizer _legal;
  late final RateLimiter _otpLimiter;
  AuthStep _step = AuthStep.initial;
  String? _error;
  bool _isDisposed = false; // ✅ FIX: Added disposal flag

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _terms = TapGestureRecognizer()..onTap = _openTerms;
    _privacy = TapGestureRecognizer()..onTap = _openPrivacy;
    _legal = TapGestureRecognizer()..onTap = _openLegal;
    _otpLimiter = RateLimiter(
      minInterval: const Duration(seconds: 30),
      maxCallsPerInterval: 1,
    );
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650))
      ..forward();
    
    // ✅ FIX: Cache animation
    _animation = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _isDisposed = true; // ✅ FIX: Set disposal flag
    _entrance.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _terms.dispose();
    _privacy.dispose();
    _legal.dispose();
    _otpLimiter.dispose();
    super.dispose();
  }

  Future<void> _openLink(String url, String failureMessage) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (mounted) _message(failureMessage);
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) _message(failureMessage);
    }
  }

  Future<void> _openTerms() => _openLink(
      AppConfig.termsOfServiceUrl, AppLocalizations.of(context).unableToOpenLink);

  Future<void> _openPrivacy() =>
      _openLink(AppConfig.privacyPolicyUrl, AppLocalizations.of(context).unableToOpenLink);

  void _openLegal() => context.push('/legal-terms');

  void _message(String value) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(value)));

  void _changeStep(AuthStep step) => setState(() {
        _error = null;
        _step = step;
      });

  Future<void> _google() async {
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      if (mounted) context.go('/home');
    } catch (e) {
      if (e is AuthCancelledException) return;
      _handleAuthError(e.toString());
    }
  }

  // ✅ FIX: Using PhoneNumberValidator from utils
  Future<void> _sendOtp() async {
    if (_isDisposed) return; // ✅ FIX: Check disposed flag
    
    final phone = _phoneController.text.replaceAll(RegExp(r'\s+'), '').trim();
    
    // ✅ FIX: Use PhoneNumberValidator for proper validation
    try {
      PhoneNumberValidator.normalizeOrThrow(phone);
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context).validPhoneNumberError);
      return;
    }
    
    // ✅ FIX: India-specific validation
    if (phone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      setState(() => _error = AppLocalizations.of(context).validPhoneNumberError);
      return;
    }
    
    if (!_otpLimiter.isCallAllowed()) {
      _message(AppLocalizations.of(context).tooManyOtpRequests);
      return;
    }
    setState(() => _error = null);
    try {
      await ref.read(authProvider.notifier).verifyPhone(
        '+91$phone', // ✅ FIX: Hardcoded India country code
        (id) {
          if (!mounted) return;
          _message(AppLocalizations.of(context).otpSentSuccessfully);
          context.push('/otp',
              extra: OtpRouteParams(
                verificationId: id,
                phoneNumber: phone,
              ));
        },
        (error) => _handleAuthError(error),
        (_) {
          if (!mounted) return;
          _message(AppLocalizations.of(context).phoneNumberVerifiedSuccessfully);
          context.go('/home');
        },
      );
    } catch (e) {
      _handleAuthError(e.toString());
    }
  }

  // ✅ FIX: Use AuthService validation
  Future<void> _continueEmail() async {
    final email = _emailController.text.trim();
    
    // ✅ FIX: Use regex from AuthService validation
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    );
    
    if (!emailRegex.hasMatch(email)) {
      setState(() => _error = AppLocalizations.of(context).pleaseEnterValidEmail);
      return;
    }
    setState(() => _error = null);
    if (mounted) await context.push('/email-auth');
  }

  // ✅ FIX: Proper error localization
  void _handleAuthError(String message) {
    if (!mounted || _isDisposed) return; // ✅ FIX: Check disposed flag
    
    final localizedMessage = _getLocalizedErrorMessage(message);
    setState(() => _error = localizedMessage);
    _message(localizedMessage);
  }

  // ✅ FIX: Added error message localization
  String _getLocalizedErrorMessage(String error) {
    final errorLower = error.toLowerCase();
    
    if (errorLower.contains('network')) {
      return AppLocalizations.of(context).networkError;
    }
    if (errorLower.contains('invalid-credential') ||
        errorLower.contains('wrong-password')) {
      return AppLocalizations.of(context).invalidCredentials;
    }
    if (errorLower.contains('user-not-found')) {
      return AppLocalizations.of(context).userNotFound;
    }
    if (errorLower.contains('email-already-in-use')) {
      return AppLocalizations.of(context).emailAlreadyInUse;
    }
    if (errorLower.contains('weak-password')) {
      return AppLocalizations.of(context).weakPassword;
    }
    if (errorLower.contains('too-many-requests')) {
      return AppLocalizations.of(context).tooManyRequests;
    }
    if (errorLower.contains('session-expired')) {
      return AppLocalizations.of(context).sessionExpired;
    }
    if (errorLower.contains('invalid-phone-number')) {
      return AppLocalizations.of(context).invalidPhoneNumber;
    }
    if (errorLower.contains('invalid-verification-code')) {
      return AppLocalizations.of(context).invalidOtp;
    }
    if (errorLower.contains('otp')) {
      return AppLocalizations.of(context).otpFailed;
    }
    
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    
    return ErrorBoundary(
      onError: (error, stack) {
        logger.error('LoginScreen error', error: error, stackTrace: stack);
        return const SizedBox.shrink();
      },
      child: Scaffold(
        backgroundColor: _background,
        resizeToAvoidBottomInset: true,
        body: Stack(children: [
          const Positioned.fill(child: _DottedBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: FadeTransition(
                    opacity: _animation, // ✅ FIX: Use cached animation
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, .08), end: Offset.zero)
                          .animate(_animation), // ✅ FIX: Use cached animation
                      child: Column(children: [
                        const _Header(),
                        const SizedBox(height: 32),
                        _LoginCard(
                          step: _step,
                          isLoading: auth.isLoading,
                          error: _error,
                          phoneController: _phoneController,
                          emailController: _emailController,
                          onStep: _changeStep,
                          onGoogle: _google,
                          onOtp: _sendOtp,
                          onEmail: _continueEmail,
                          onCreateAccount: () => context.push('/email-auth'),
                        ),
                        const SizedBox(height: 32),
                        _Footer(terms: _terms, privacy: _privacy, legal: _legal),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (auth.isLoading)
            Positioned.fill(
                child: ColoredBox(
                    color: Colors.white.withValues(alpha: .72),
                    child: const _LoadingMessage())),
        ]),
      ),
    );
  }
}

class _DottedBackground extends StatelessWidget {
  const _DottedBackground();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DottedPainter(), size: Size.infinite);
}

class _DottedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _green.withValues(alpha: .08);
    for (var x = 0.0; x < size.width; x += 24) {
      for (var y = 0.0; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(AppLocalizations.of(context).appName, style: _style(_forest, 24, FontWeight.w700)),
        const Tooltip(
            message: 'Help',
            child: Icon(Icons.help_outline_rounded, color: _forest)),
      ]);
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.step,
    required this.isLoading,
    required this.error,
    required this.phoneController,
    required this.emailController,
    required this.onStep,
    required this.onGoogle,
    required this.onOtp,
    required this.onEmail,
    required this.onCreateAccount,
  });
  final AuthStep step;
  final bool isLoading;
  final String? error;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final ValueChanged<AuthStep> onStep;
  final Future<void> Function() onGoogle;
  final Future<void> Function() onOtp;
  final VoidCallback onEmail;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 8))
            ]),
        child: Column(children: [
          Text(AppLocalizations.of(context).secureAccessPortal,
              style: _style(AppColors.onSurface, 28, FontWeight.w700)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).yourLegalRightsProtected,
              textAlign: TextAlign.center, style: _style(_green, 14)),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(.04, 0), end: Offset.zero)
                        .animate(animation),
                    child: child)),
            child: _stepContent(context),
          ),
          const SizedBox(height: 20),
          _CreateAccount(onTap: isLoading ? null : onCreateAccount),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context).legalDisclaimer,
              textAlign: TextAlign.center,
              style: _style(
                  _green, 11, FontWeight.w400, 1.2, null, FontStyle.italic)),
        ]),
      );

  Widget _stepContent(BuildContext context) {
    switch (step) {
      case AuthStep.initial:
        return _Options(
            key: const ValueKey(AuthStep.initial),
            isLoading: isLoading,
            onEmail: () => onStep(AuthStep.emailForm),
            onPhone: () => onStep(AuthStep.phoneForm),
            onGoogle: onGoogle);
      case AuthStep.emailForm:
        return _EmailForm(
            key: const ValueKey(AuthStep.emailForm),
            controller: emailController,
            isLoading: isLoading,
            error: error,
            onBack: () => onStep(AuthStep.initial),
            onSubmit: onEmail);
      case AuthStep.phoneForm:
        return _PhoneForm(
            key: const ValueKey(AuthStep.phoneForm),
            controller: phoneController,
            isLoading: isLoading,
            error: error,
            onBack: () => onStep(AuthStep.initial),
            onSubmit: onOtp);
    }
  }
}

class _Options extends StatelessWidget {
  const _Options(
      {super.key,
      required this.isLoading,
      required this.onEmail,
      required this.onPhone,
      required this.onGoogle});
  final bool isLoading;
  final VoidCallback onEmail;
  final VoidCallback onPhone;
  final Future<void> Function() onGoogle;
  @override
  Widget build(BuildContext context) => Column(children: [
        _PrimaryButton(
            label: AppLocalizations.of(context).continueWithEmail,
            icon: Icons.email_outlined,
            onPressed: isLoading ? null : onEmail),
        const SizedBox(height: 12),
        _SecondaryButton(
            label: AppLocalizations.of(context).signInInstantlyWithPhoneOtp,
            icon: Icons.phone_outlined,
            onPressed: isLoading ? null : onPhone),
        const SizedBox(height: 24),
        const _Separator(),
        const SizedBox(height: 24),
        Semantics( // ✅ FIX: Added accessibility
          button: true,
          label: 'Continue with Google',
          child: _SecondaryButton(
            label: AppLocalizations.of(context).continueWithGoogle,
            leading: Semantics(
                label: 'Google',
                child: Text('G', style: _style(_forest, 18, FontWeight.w700))),
            onPressed: isLoading ? null : onGoogle,
          ),
        ),
      ]);
}

// ✅ FIX: Converted to StatefulWidget for loading state
class _PhoneForm extends StatefulWidget {
  const _PhoneForm({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.error,
    required this.onBack,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final bool isLoading;
  final String? error;
  final VoidCallback onBack;
  final Future<void> Function() onSubmit;

  @override
  State<_PhoneForm> createState() => _PhoneFormState();
}

class _PhoneFormState extends State<_PhoneForm> {
  bool _isSendingOtp = false;

  @override
  Widget build(BuildContext context) => _FormShell(
      title: AppLocalizations.of(context).signInInstantlyWithPhoneOtp,
      onBack: widget.onBack,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics( // ✅ FIX: Added accessibility
          label: 'Phone number input',
          textField: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Phone Number'),
              const SizedBox(height: 8),
              Row(
                children: [
                  // ✅ FIX: India-specific prefix display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Text(
                      '+91',
                      style: _style(_forest, 16, FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      enabled: !widget.isLoading && !_isSendingOtp,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10)
                      ],
                      onSubmitted: (_) => _handleSubmit(),
                      style: _style(AppColors.onSurface, 16),
                      decoration: _input('Enter 10-digit number')
                          .copyWith(counterText: ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _Error(widget.error),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: _isSendingOtp ? AppLocalizations.of(context).sending : AppLocalizations.of(context).sendOtp,
          icon: _isSendingOtp ? null : Icons.arrow_forward,
          onPressed: widget.isLoading || _isSendingOtp ? null : _handleSubmit,
        ),
      ]));

  Future<void> _handleSubmit() async {
    setState(() => _isSendingOtp = true);
    try {
      await widget.onSubmit();
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }
}

class _EmailForm extends StatelessWidget {
  const _EmailForm(
      {super.key,
      required this.controller,
      required this.isLoading,
      required this.error,
      required this.onBack,
      required this.onSubmit});
  final TextEditingController controller;
  final bool isLoading;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) => _FormShell(
      title: AppLocalizations.of(context).continueWithEmail,
      onBack: onBack,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics( // ✅ FIX: Added accessibility
          label: 'Email address input',
          textField: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Email Address'),
              const SizedBox(height: 8),
              TextField(
                  controller: controller,
                  enabled: !isLoading,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onSubmitted: (_) => onSubmit(),
                  style: _style(AppColors.onSurface, 16),
                  decoration: _input('Enter your email', icon: Icons.email_outlined)),
            ],
          ),
        ),
        _Error(error),
        const SizedBox(height: 16),
        _PrimaryButton(
            label: AppLocalizations.of(context).continueWith,
            onPressed: isLoading ? null : onSubmit),
      ]));
}

class _FormShell extends StatelessWidget {
  const _FormShell(
      {required this.title, required this.onBack, required this.child});
  final String title;
  final VoidCallback onBack;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconButton(
            tooltip: 'Back to sign-in options',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: _forest,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48)),
        const SizedBox(height: 8),
        Text(title, style: _style(_forest, 20, FontWeight.w700)),
        const SizedBox(height: 20),
        child,
      ]);
}

class _Label extends StatelessWidget {
  const _Label(this.value);
  final String value;
  @override
  Widget build(BuildContext context) =>
      Text(value, style: _style(AppColors.onSurface, 14, FontWeight.w600));
}

class _Error extends StatelessWidget {
  const _Error(this.value);
  final String? value;
  @override
  Widget build(BuildContext context) => value == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(value!,
              style: _style(AppColors.error, 12, FontWeight.w500)));
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(
      {required this.label, this.icon, required this.onPressed});
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 19),
        label: Text(label,
            textAlign: TextAlign.center,
            style: _style(Colors.white, 16, FontWeight.w600)),
        style: ElevatedButton.styleFrom(
            backgroundColor: _forest,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.surfaceContainerHigh,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM))),
      ));
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton(
      {required this.label, this.icon, this.leading, required this.onPressed});
  final String label;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
            foregroundColor: _forest,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            side: const BorderSide(color: _green),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (leading != null)
            leading!
          else if (icon != null)
            Icon(icon, size: 19),
          if (leading != null || icon != null) const SizedBox(width: 10),
          Flexible(
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: _style(_forest, 16, FontWeight.w600))),
        ]),
      ));
}

class _Separator extends StatelessWidget {
  const _Separator();
  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(child: Divider(color: AppColors.outlineVariant)),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(AppLocalizations.of(context).continueWith, style: _style(_green, 12))),
        const Expanded(child: Divider(color: AppColors.outlineVariant))
      ]);
}

class _CreateAccount extends StatelessWidget {
  const _CreateAccount({required this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
      child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(style: _style(_green, 14), children: [
            TextSpan(text: AppLocalizations.of(context).newToJusLegal),
            TextSpan(
                text: AppLocalizations.of(context).register,
                style: _style(_forest, 14, FontWeight.w700, 1.2,
                    TextDecoration.underline))
          ])));
}

class _Footer extends StatelessWidget {
  const _Footer(
      {required this.terms, required this.privacy, required this.legal});
  final TapGestureRecognizer terms;
  final TapGestureRecognizer privacy;
  final TapGestureRecognizer legal;
  @override
  Widget build(BuildContext context) => Column(children: [
        const Divider(color: AppColors.outlineVariant),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context).footerCopyright,
            textAlign: TextAlign.center, style: _style(_green, 11)),
        const SizedBox(height: 10),
        Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _FooterLink(AppLocalizations.of(context).privacyPolicy, privacy),
              _FooterLink(AppLocalizations.of(context).terms, terms),
              _FooterLink(AppLocalizations.of(context).legalDisclaimer, legal),
            ]),
      ]);
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.text, this.recognizer);
  final String text;
  final TapGestureRecognizer recognizer;
  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          text: text,
          recognizer: recognizer,
          style: _style(
              _forest, 11, FontWeight.w600, 1.2, TextDecoration.underline),
        ),
      );
}

class _LoadingMessage extends StatelessWidget {
  const _LoadingMessage();
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const LoadingWidget(size: 40),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context).authenticating,
            style: _style(AppColors.textPrimary, 14, FontWeight.w600))
      ]));
}

TextStyle _style(Color color, double size,
        [FontWeight weight = FontWeight.w400,
        double height = 1.2,
        TextDecoration? decoration,
        FontStyle? fontStyle]) =>
    GoogleFonts.notoSans(
        color: color,
        fontSize: size,
        fontWeight: weight,
        height: height,
        decoration: decoration,
        fontStyle: fontStyle);

InputDecoration _input(String hint, {IconData? icon, String? prefix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: _style(AppColors.onSurfaceVariant, 16),
      prefixIcon: icon == null ? null : Icon(icon, color: _green),
      prefixText: prefix,
      prefixStyle: _style(_forest, 16, FontWeight.w600),
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: AppColors.outline)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: _green, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: AppColors.error)),
    );