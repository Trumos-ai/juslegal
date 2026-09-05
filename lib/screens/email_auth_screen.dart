import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:juslegal/core/core.dart';
import '../l10n/gen/app_localizations.dart';
import '../services/auth_handler.dart';

class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final FocusNode _emailFocusNode;
  late final GlobalKey<FormState> _formKey;

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showVerification = false;
  bool _isSendingReset = false;
  bool _isVerificationLoading = false;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _emailFocusNode = FocusNode();
    _formKey = GlobalKey<FormState>();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _slideController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emailFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      if (_isLoginMode) {
        await ref.read(authProvider.notifier).signInWithEmail(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
        if (mounted) {
          _showSnackBar(_l10n.loginSuccessful, isError: false);
          context.go('/home');
        }
      } else {
        await ref.read(authProvider.notifier).registerWithEmail(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
        if (mounted) {
          setState(() => _showVerification = true);
          _showSnackBar(_l10n.accountCreatedSuccessfully, isError: false);
        }
      }
    } catch (error) {
      if (!mounted) return;
      if (error is EmailVerificationRequiredException) {
        setState(() => _showVerification = true);
        _showSnackBar(_l10n.emailVerificationRequired);
      } else {
        _showSnackBar(error.toString());
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (!EmailValidator.isValid(email)) {
      _showSnackBar(_l10n.pleaseEnterValidEmail);
      return;
    }
    setState(() => _isSendingReset = true);
    try {
      await ref.read(authProvider.notifier).resetPassword(email);
      if (mounted) {
        _showSnackBar(_l10n.passwordResetEmailSent(email), isError: false);
      }
    } catch (error) {
      if (mounted) _showSnackBar(error.toString());
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _isVerificationLoading = true);
    try {
      await ref.read(authProvider.notifier).sendEmailVerification();
      if (mounted) _showSnackBar(_l10n.verificationEmailResent, isError: false);
    } catch (error) {
      if (mounted) _showSnackBar(error.toString());
    } finally {
      if (mounted) setState(() => _isVerificationLoading = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isVerificationLoading = true);
    try {
      final verified =
          await ref.read(authProvider.notifier).checkEmailVerification();
      if (!mounted) return;
      if (verified) {
        _showSnackBar(_l10n.emailVerifiedSuccessfully, isError: false);
        context.go('/home');
      } else {
        _showSnackBar(_l10n.emailNotVerifiedYet);
      }
    } catch (error) {
      if (mounted) _showSnackBar(error.toString());
    } finally {
      if (mounted) setState(() => _isVerificationLoading = false);
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _l10n.pleaseEnterYourPassword;
    }
    if (!_isLoginMode && !PasswordValidator.isStrong(value)) {
      return _l10n.passwordStrengthRequirements;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading ||
        _isSendingReset ||
        _isVerificationLoading;
    final compact = MediaQuery.sizeOf(context).width < 600;
    return PopScope(
      canPop: !isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.balance_rounded,
                                  color: AppTheme.legalGold, size: 72),
                              const SizedBox(height: 12),
                              Text(_l10n.yourLegalRightsProtected,
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              compact ? 0 : 24, 0, compact ? 0 : 24, 16),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 450),
                              child: _showVerification
                                  ? _buildVerificationCard(compact, isLoading)
                                  : _buildAuthCard(compact, isLoading),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, required bool compact}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: compact
            ? const BorderRadius.only(
                topLeft: Radius.circular(24), topRight: Radius.circular(24))
            : BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: compact
            ? null
            : const [
                BoxShadow(
                    color: AppColors.shadowBlack,
                    blurRadius: 24,
                    offset: Offset(0, 12))
              ],
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }

  Widget _buildVerificationCard(bool compact, bool isLoading) {
    return _card(
      compact: compact,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_l10n.verifyYourEmail,
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Text(_l10n.verificationEmailSent(_emailController.text.trim()),
              style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _checkVerification,
            child: Text(_l10n.checkVerification),
          ),
          TextButton(
            onPressed: isLoading ? null : _resendVerification,
            child: Text(_l10n.resendVerificationEmail),
          ),
          TextButton(
            onPressed: isLoading
                ? null
                : () => setState(() => _showVerification = false),
            child: Text(_l10n.backToLoginOptions),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(bool compact, bool isLoading) {
    return _card(
      compact: compact,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: _modeButton(_l10n.login, true)),
              Expanded(child: _modeButton(_l10n.register, false)),
            ]),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email
              ],
              enabled: !isLoading,
              decoration: InputDecoration(
                  labelText: _l10n.email,
                  hintText: _l10n.enterYourEmail,
                  prefixIcon: const Icon(Icons.email_outlined)),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return _l10n.pleaseEnterYourEmail;
                }
                if (!EmailValidator.isValid(value)) {
                  return _l10n.pleaseEnterValidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _passwordField(
              controller: _passwordController,
              obscure: _obscurePassword,
              label: _l10n.password,
              hint: _l10n.enterYourPassword,
              autofillHints: _isLoginMode
                  ? const [AutofillHints.password]
                  : const [AutofillHints.newPassword],
              onToggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              validator: _validatePassword,
              enabled: !isLoading,
            ),
            if (!_isLoginMode) ...[
              const SizedBox(height: 16),
              _passwordField(
                controller: _confirmPasswordController,
                obscure: _obscureConfirmPassword,
                label: _l10n.confirmPassword,
                hint: _l10n.confirmYourPassword,
                autofillHints: const [AutofillHints.newPassword],
                onToggle: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return _l10n.pleaseConfirmYourPassword;
                  }
                  if (value.trim() != _passwordController.text.trim()) {
                    return _l10n.passwordsDoNotMatch;
                  }
                  return null;
                },
                enabled: !isLoading,
              ),
            ],
            if (_isLoginMode)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : _handleForgotPassword,
                  child: Text(
                      _isSendingReset ? _l10n.sending : _l10n.forgotPassword),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleSubmit,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isLoginMode ? _l10n.login : _l10n.register),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: isLoading ? null : () => context.pop(),
                child: Text(_l10n.backToLoginOptions),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String label, bool loginMode) {
    final selected = _isLoginMode == loginMode;
    return GestureDetector(
      onTap: () => setState(() => _isLoginMode = loginMode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: selected ? AppTheme.legalGold : AppTheme.border,
                    width: 2))),
        child: Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppTheme.legalGold : AppTheme.textSecondary)),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool obscure,
    required String label,
    required String hint,
    required Iterable<String> autofillHints,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    required bool enabled,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      autofillHints: autofillHints,
      decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: const Icon(Icons.lock_outlined),
          suffixIcon: IconButton(
            icon: Icon(obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined),
            onPressed: onToggle,
          )),
      validator: validator,
    );
  }
}
