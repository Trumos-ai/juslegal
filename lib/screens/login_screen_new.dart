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
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpLimiter =
      RateLimiter(minInterval: const Duration(seconds: 30), maxCallsPerInterval: 1);
  late final AnimationController _entrance;
  late final Animation<double> _animation;
  late final _terms = TapGestureRecognizer()..onTap = _openTerms;
  late final _privacy = TapGestureRecognizer()..onTap = _openPrivacy;
  late final _legal = TapGestureRecognizer()..onTap = _openLegal;
  AuthStep _step = AuthStep.initial;
  String? _error;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))
      ..forward();
    _animation = CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _isDisposed = true;
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
  Future<void> _openPrivacy() => _openLink(
      AppConfig.privacyPolicyUrl, AppLocalizations.of(context).unableToOpenLink);
  void _openLegal() => context.push('/legal-terms');

  void _message(String value) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(value)));

  void _changeStep(AuthStep step) =>
      setState(() { _error = null; _step = step; });

  Future<void> _google() async {
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      if (mounted) context.go('/home');
    } catch (e) {
      if (e is AuthCancelledException) return;
      _handleAuthError(e.toString());
    }
  }

  Future<void> _sendOtp() async {
    if (_isDisposed) return;
    final phone = _phoneController.text.replaceAll(RegExp(r'\s+'), '').trim();
    final looksInvalid = phone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
    var normalizeFailed = false;
    try {
      PhoneNumberValidator.normalizeOrThrow(phone);
    } catch (_) {
      normalizeFailed = true;
    }
    if (normalizeFailed || looksInvalid) {
      setState(() => _error = AppLocalizations.of(context).validPhoneNumberError);
      return;
    }
    if (!_otpLimiter.isCallAllowed()) {
      _message(AppLocalizations.of(context).tooManyOtpRequests);
      return;
    }
    setState(() => _error = null);
    try {
      await ref.read(authProvider.notifier).verifyPhone('+91$phone', (id) {
        if (!mounted) return;
        _message(AppLocalizations.of(context).otpSentSuccessfully);
        context.push('/otp',
            extra: OtpRouteParams(verificationId: id, phoneNumber: phone));
      }, (error) => _handleAuthError(error), (_) {
        if (!mounted) return;
        _message(AppLocalizations.of(context).phoneNumberVerifiedSuccessfully);
        context.go('/home');
      });
    } catch (e) {
      _handleAuthError(e.toString());
    }
  }

  static final _emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");

  Future<void> _continueEmail() async {
    if (!_emailRegex.hasMatch(_emailController.text.trim())) {
      setState(() => _error = AppLocalizations.of(context).pleaseEnterValidEmail);
      return;
    }
    setState(() => _error = null);
    if (mounted) await context.push('/email-auth');
  }

  void _handleAuthError(String message) {
    if (!mounted || _isDisposed) return;
    final localized = _getLocalizedErrorMessage(message);
    setState(() => _error = localized);
    _message(localized);
  }

  String _getLocalizedErrorMessage(String error) {
    final l = AppLocalizations.of(context);
    final e = error.toLowerCase();
    final byKey = <String, String>{
      'network': l.networkError,
      'invalid-credential': l.invalidCredentials,
      'wrong-password': l.invalidCredentials,
      'user-not-found': l.userNotFound,
      'email-already-in-use': l.emailAlreadyInUse,
      'weak-password': l.weakPassword,
      'too-many-requests': l.tooManyRequests,
      'session-expired': l.sessionExpired,
      'invalid-phone-number': l.invalidPhoneNumber,
      'invalid-verification-code': l.invalidOtp,
      'otp': l.otpFailed,
    };
    for (final entry in byKey.entries) {
      if (e.contains(entry.key)) return entry.value;
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
          Positioned.fill(child: CustomPaint(painter: _DottedPainter(), size: Size.infinite)),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: FadeTransition(
                    opacity: _animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
                          .animate(_animation),
                      child: Column(children: [
                        _header(context),
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
                        _footer(context, terms: _terms, privacy: _privacy, legal: _legal),
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
                    color: Colors.white.withValues(alpha: .72), child: _loadingMessage(context))),
        ]),
      ),
    );
  }
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

Widget _header(BuildContext context) =>
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(AppLocalizations.of(context).appName, style: _style(_forest, 24, FontWeight.w700)),
      const Tooltip(message: 'Help', child: Icon(Icons.help_outline_rounded, color: _forest)),
    ]);

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
              BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 8))
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
                    position: Tween<Offset>(begin: const Offset(.04, 0), end: Offset.zero)
                        .animate(animation),
                    child: child)),
            child: _stepContent(context),
          ),
          const SizedBox(height: 20),
          _CreateAccount(onTap: isLoading ? null : onCreateAccount),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context).legalDisclaimer,
              textAlign: TextAlign.center,
              style: _style(_green, 11, FontWeight.w400, 1.2, null, FontStyle.italic)),
        ]),
      );

  Widget _stepContent(BuildContext context) => switch (step) {
        AuthStep.initial => _Options(
            key: const ValueKey(AuthStep.initial),
            isLoading: isLoading,
            onEmail: () => onStep(AuthStep.emailForm),
            onPhone: () => onStep(AuthStep.phoneForm),
            onGoogle: onGoogle),
        AuthStep.emailForm => _EmailForm(
            key: const ValueKey(AuthStep.emailForm),
            controller: emailController,
            isLoading: isLoading,
            error: error,
            onBack: () => onStep(AuthStep.initial),
            onSubmit: onEmail),
        AuthStep.phoneForm => _PhoneForm(
            key: const ValueKey(AuthStep.phoneForm),
            controller: phoneController,
            isLoading: isLoading,
            error: error,
            onBack: () => onStep(AuthStep.initial),
            onSubmit: onOtp),
      };
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
        _AuthButton(
            label: AppLocalizations.of(context).continueWithEmail,
            icon: Icons.email_outlined,
            onPressed: isLoading ? null : onEmail),
        const SizedBox(height: 12),
        _AuthButton(
            filled: false,
            label: AppLocalizations.of(context).signInInstantlyWithPhoneOtp,
            icon: Icons.phone_outlined,
            onPressed: isLoading ? null : onPhone),
        const SizedBox(height: 24),
        _separator(context),
        const SizedBox(height: 24),
        Semantics(
          button: true,
          label: 'Continue with Google',
          child: _AuthButton(
            filled: false,
            label: AppLocalizations.of(context).continueWithGoogle,
            leading: Semantics(
                label: 'Google', child: Text('G', style: _style(_forest, 18, FontWeight.w700))),
            onPressed: isLoading ? null : onGoogle,
          ),
        ),
      ]);
}

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
  Widget build(BuildContext context) => _formShell(
      context: context,
      title: AppLocalizations.of(context).signInInstantlyWithPhoneOtp,
      onBack: widget.onBack,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(
          label: 'Phone number input',
          textField: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Phone Number'),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM)),
                child: Text('+91', style: _style(_forest, 16, FontWeight.w600)),
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
                  decoration: _input('Enter 10-digit number').copyWith(counterText: ''),
                ),
              ),
            ]),
          ]),
        ),
        _error(widget.error),
        const SizedBox(height: 16),
        _AuthButton(
          label: _isSendingOtp
              ? AppLocalizations.of(context).sending
              : AppLocalizations.of(context).sendOtp,
          icon: _isSendingOtp ? null : Icons.arrow_forward,
          onPressed: widget.isLoading || _isSendingOtp ? null : _handleSubmit,
        ),
      ]));

  Future<void> _handleSubmit() async {
    setState(() => _isSendingOtp = true);
    try {
      await widget.onSubmit();
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
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
  Widget build(BuildContext context) => _formShell(
      context: context,
      title: AppLocalizations.of(context).continueWithEmail,
      onBack: onBack,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(
          label: 'Email address input',
          textField: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Email Address'),
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
          ]),
        ),
        _error(error),
        const SizedBox(height: 16),
        _AuthButton(
            label: AppLocalizations.of(context).continueWith,
            onPressed: isLoading ? null : onSubmit),
      ]));
}

Widget _formShell(
        {required BuildContext context,
        required String title,
        required VoidCallback onBack,
        required Widget child}) =>
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

Widget _label(String value) =>
    Text(value, style: _style(AppColors.onSurface, 14, FontWeight.w600));

Widget _error(String? value) => value == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(value, style: _style(AppColors.error, 12, FontWeight.w500)));

/// Single button used for both filled (primary) and outlined (secondary) styles.
class _AuthButton extends StatelessWidget {
  const _AuthButton(
      {required this.label,
      this.icon,
      this.leading,
      required this.onPressed,
      this.filled = true});
  final String label;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final content = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (leading != null)
        leading!
      else if (icon != null)
        Icon(icon, size: 19),
      if (leading != null || icon != null) const SizedBox(width: 10),
      Flexible(
          child: Text(label,
              textAlign: TextAlign.center,
              style: _style(filled ? Colors.white : _forest, 16, FontWeight.w600))),
    ]);
    final minSize = const Size(48, 48);
    final padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM));
    return SizedBox(
      width: double.infinity,
      child: filled
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _forest,
                  disabledBackgroundColor: AppColors.surfaceContainerHigh,
                  minimumSize: minSize,
                  padding: padding,
                  elevation: 0,
                  shape: shape),
              child: content)
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                  foregroundColor: _forest,
                  minimumSize: minSize,
                  padding: padding,
                  side: const BorderSide(color: _green),
                  shape: shape),
              child: content),
    );
  }
}

Widget _separator(BuildContext context) => Row(children: [
      const Expanded(child: Divider(color: AppColors.outlineVariant)),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(AppLocalizations.of(context).continueWith, style: _style(_green, 12))),
      const Expanded(child: Divider(color: AppColors.outlineVariant)),
    ]);

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
                style: _style(_forest, 14, FontWeight.w700, 1.2, TextDecoration.underline))
          ])));
}

Widget _footer(BuildContext context,
        {required TapGestureRecognizer terms,
        required TapGestureRecognizer privacy,
        required TapGestureRecognizer legal}) =>
    Column(children: [
      const Divider(color: AppColors.outlineVariant),
      const SizedBox(height: 16),
      Text(AppLocalizations.of(context).footerCopyright,
          textAlign: TextAlign.center, style: _style(_green, 11)),
      const SizedBox(height: 10),
      Wrap(alignment: WrapAlignment.center, spacing: 16, runSpacing: 8, children: [
        _footerLink(AppLocalizations.of(context).privacyPolicy, privacy),
        _footerLink(AppLocalizations.of(context).terms, terms),
        _footerLink(AppLocalizations.of(context).legalDisclaimer, legal),
      ]),
    ]);

Widget _footerLink(String text, TapGestureRecognizer recognizer) => Text.rich(TextSpan(
    text: text,
    recognizer: recognizer,
    style: _style(_forest, 11, FontWeight.w600, 1.2, TextDecoration.underline)));

Widget _loadingMessage(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
  const LoadingWidget(size: 40),
  const SizedBox(height: 16),
  Text(AppLocalizations.of(context).authenticating,
      style: _style(AppColors.textPrimary, 14, FontWeight.w600))
]));

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

InputDecoration _input(String hint, {IconData? icon, String? prefix}) => InputDecoration(
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