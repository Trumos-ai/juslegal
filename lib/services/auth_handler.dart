import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:juslegal/core/utils/logger.dart';
import 'package:juslegal/core/utils/password_validator.dart';
import 'package:juslegal/core/utils/phone_number_validator.dart';
import 'package:juslegal/core/utils/rate_limiter.dart';

export 'auth_exceptions.dart';
import 'auth_exceptions.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final RateLimiter _otpRateLimiter;

  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    RateLimiter? otpRateLimiter,
  })  : _firebaseAuth = firebaseAuth ??
            (FirebaseAuth.instance..setPersistence(Persistence.LOCAL)), // ✅ FIX: Added persistence
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _otpRateLimiter = otpRateLimiter ??
            RateLimiter(
              minInterval: const Duration(seconds: 30),
              maxCallsPerInterval: 1,
            );

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // ✅ FIX: Added email verification check for Google sign-in
  Future<UserCredential> signInWithGoogle() async {
    try {
      logger.debug('Opening Google sign-in', tag: 'Auth');
      if (kIsWeb) {
        final credential = await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
        // ✅ FIX: Check email verification
        if (!(credential.user?.emailVerified ?? false)) {
          await credential.user?.sendEmailVerification();
          throw const EmailVerificationRequiredException(
            'Please verify your email address before signing in.',
          );
        }
        return credential;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthCancelledException('Google sign-in was cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      // ✅ FIX: Check email verification
      if (!(userCredential.user?.emailVerified ?? false)) {
        await userCredential.user?.sendEmailVerification();
        throw const EmailVerificationRequiredException(
          'Please verify your email address before signing in.',
        );
      }
      return userCredential;
    } on AuthCancelledException {
      rethrow;
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _failure(error, stackTrace, 'Google sign-in');
    } catch (error, stackTrace) {
      logger.error('Google sign-in failed',
          tag: 'Auth', error: error, stackTrace: stackTrace);
      throw const AuthFailureException(
          'Google sign-in failed. Please try again.');
    }
  }

  // ✅ FIX: Fixed rate limiter and race condition
  Future<void> verifyPhone(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(String) onError,
    Function(UserCredential)? onAutoVerified,
  ) async {
    final normalizedPhoneNumber =
        PhoneNumberValidator.normalizeOrThrow(phoneNumber);
    
    // ✅ FIX: Check AND record rate limit
    if (!_otpRateLimiter.isCallAllowed()) {
      throw const AuthRateLimitException(
        'Too many OTP requests. Please wait 30 seconds and try again.',
      );
    }
    final completer = Completer<UserCredential?>();
    var isCompleted = false;

    void completeWithValue(UserCredential? credential) {
      if (!isCompleted) {
        isCompleted = true;
        if (!completer.isCompleted) {
          completer.complete(credential);
        }
      }
    }

    void completeWithError(Object error, StackTrace stackTrace) {
      if (!isCompleted) {
        isCompleted = true;
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      }
    }

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: normalizedPhoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          if (isCompleted) return;
          try {
            final userCredential =
                await _firebaseAuth.signInWithCredential(credential);
            onAutoVerified?.call(userCredential);
            completeWithValue(userCredential);
          } on FirebaseAuthException catch (error, stackTrace) {
            final failure =
                _failure(error, stackTrace, 'Automatic OTP verification');
            onError(failure.message);
            completeWithError(failure, stackTrace);
          } catch (error, stackTrace) {
            logger.error('Automatic OTP verification failed',
                tag: 'Auth', error: error, stackTrace: stackTrace);
            const message =
                'Automatic OTP verification failed. Please enter the OTP.';
            onError(message);
            completeWithError(error, stackTrace);
          }
        },
        verificationFailed: (error) {
          if (isCompleted) return;
          final failure =
              _failure(error, StackTrace.current, 'OTP verification');
          onError(failure.message);
          completeWithError(failure, StackTrace.current);
        },
        codeSent: (verificationId, _) {
          if (isCompleted) return;
          logger.info('OTP code sent', tag: 'Auth');
          onCodeSent(verificationId);
          completeWithValue(null);
        },
        codeAutoRetrievalTimeout: (_) {},
      );
      await completer.future;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _failure(error, stackTrace, 'OTP verification');
    } catch (error, stackTrace) {
      logger.error('OTP verification failed',
          tag: 'Auth', error: error, stackTrace: stackTrace);
      throw const AuthFailureException(
          'OTP verification failed. Please try again.');
    }
  }

  Future<UserCredential> verifyOTP(String verificationId, String otp) async {
    if (verificationId.trim().isEmpty ||
        !RegExp(r'^\d{6}$').hasMatch(otp.trim())) {
      throw const AuthValidationException('Enter the 6-digit OTP.');
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp.trim(),
      );
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _failure(error, stackTrace, 'OTP verification');
    } catch (error, stackTrace) {
      logger.error('OTP verification failed',
          tag: 'Auth', error: error, stackTrace: stackTrace);
      throw const AuthFailureException(
          'OTP verification failed. Please try again.');
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    _validateEmail(email);
    _validatePassword(password, requireStrength: false);
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (!(credential.user?.emailVerified ?? false)) {
        throw const EmailVerificationRequiredException(
          'Please verify your email address before signing in.',
        );
      }
      return credential;
    } on EmailVerificationRequiredException {
      rethrow;
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _failure(error, stackTrace, 'Email sign-in');
    } catch (error, stackTrace) {
      throw _unexpectedFailure(error, stackTrace, 'Email sign-in');
    }
  }

  // ✅ FIX: Added proper weak password exception handling
  Future<UserCredential> registerWithEmail(
      String email, String password) async {
    _validateEmail(email);
    _validatePassword(password, requireStrength: true);
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.sendEmailVerification();
      return credential;
    } on FirebaseAuthException catch (error, stackTrace) {
      // ✅ FIX: Handle specific Firebase errors
      if (error.code == 'weak-password') {
        throw const WeakPasswordException(
          'Password must be at least 8 characters and include uppercase, lowercase, a number, and a special character.',
        );
      }
      throw _failure(error, stackTrace, 'Account registration');
    } catch (error, stackTrace) {
      throw _unexpectedFailure(error, stackTrace, 'Account registration');
    }
  }

  Future<void> resetPassword(String email) async {
    _validateEmail(email);
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _failure(error, stackTrace, 'Password reset');
    } catch (error, stackTrace) {
      throw _unexpectedFailure(error, stackTrace, 'Password reset');
    }
  }

 Future<void> sendEmailVerification() async {
  final user = currentUser;

  if (user == null) {
    throw const AuthFailureException('You must be signed in.');
  }

  if (user.emailVerified) return;

  try {
    await user.sendEmailVerification();
  } on FirebaseAuthException catch (error, stackTrace) {
    throw _failure(error, stackTrace, 'Email verification');
  }
}

  Future<bool> checkEmailVerification() async {
    final user = currentUser;
    if (user == null) return false;
    await user.reload();
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  // ✅ FIX: Added reauthentication methods
  Future<void> reauthenticateUser(String password) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthFailureException('No user is signed in.');
    }
    
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _failure(error, stackTrace, 'Re-authentication');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthFailureException('No user is signed in.');
    }
    
    _validatePassword(newPassword, requireStrength: true);
    
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _failure(error, stackTrace, 'Password update');
    }
  }

  Future<void> updateEmail(String newEmail) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthFailureException('No user is signed in.');
    }
    
    _validateEmail(newEmail);
    
    try {
      await user.verifyBeforeUpdateEmail(newEmail.trim());
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _failure(error, stackTrace, 'Email update');
    }
  }

  Future<String?> refreshToken({bool forceRefresh = true}) async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken(forceRefresh);
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _failure(error, stackTrace, 'Token refresh');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      if (!kIsWeb) await _googleSignIn.signOut();
    } finally {
      _otpRateLimiter.reset();
    }
  }

  // ✅ FIX: Fixed email validation regex (RFC 5322 compliant)
  void _validateEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    );
    
    if (!emailRegex.hasMatch(email.trim())) {
      throw const InvalidEmailException('Enter a valid email address.');
    }
  }

  void _validatePassword(String password, {required bool requireStrength}) {
    if (password.isEmpty) {
      throw const WeakPasswordException('Enter a password.');
    }
    if (requireStrength && !PasswordValidator.isStrong(password)) {
      throw const WeakPasswordException(
        'Password must be at least 8 characters and include uppercase, lowercase, a number, and a special character.',
      );
    }
  }

  AuthFailureException _failure(
    FirebaseAuthException error,
    StackTrace stackTrace,
    String operation,
  ) {
    logger.error('$operation failed',
        tag: 'Auth', error: error, stackTrace: stackTrace);
    return AuthFailureException(_firebaseMessage(error), code: error.code);
  }

  AuthFailureException _unexpectedFailure(
      Object error, StackTrace stackTrace, String operation) {
    logger.error('$operation failed',
        tag: 'Auth', error: error, stackTrace: stackTrace);
    return const AuthFailureException(
        'Authentication failed. Please try again.');
  }

  String _firebaseMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Enter a valid phone number with country code.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again later.';
      case 'invalid-verification-code':
        return 'The OTP is incorrect. Please check the 6-digit code.';
      case 'session-expired':
        return 'This OTP has expired. Please request a new one.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-credential':
      case 'wrong-password':
        return 'The email or password is incorrect.';
      case 'user-not-found':
        return 'No account was found for this email address.';
      case 'weak-password':
        return 'Choose a stronger password with at least 8 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  late final StreamSubscription<User?> _authSub;

  @override
  AuthState build() {
    final authService = ref.read(authServiceProvider);
    _authSub = authService.authStateChanges.listen((user) {
      state = state.copyWith(user: user, clearUser: user == null);
    });
    ref.onDispose(() {
      _authSub.cancel();
    });
    return AuthState(user: authService.currentUser);
  }

  Future<UserCredential> signInWithGoogle() => _runUserOperation(
        () => ref.read(authServiceProvider).signInWithGoogle(),
      );

  Future<UserCredential> verifyOTP(String verificationId, String otp) =>
      _runUserOperation(
        () => ref.read(authServiceProvider).verifyOTP(verificationId, otp),
      );

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _runUserOperation(
        () => ref.read(authServiceProvider).signInWithEmail(email, password),
      );

  Future<UserCredential> registerWithEmail(String email, String password) =>
      _runUserOperation(
        () => ref.read(authServiceProvider).registerWithEmail(email, password),
      );

  Future<void> resetPassword(String email) => _runOperation(
        () => ref.read(authServiceProvider).resetPassword(email),
      );

  Future<void> sendEmailVerification() => _runOperation(
        () => ref.read(authServiceProvider).sendEmailVerification(),
      );

  Future<void> verifyPhone(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(String) onError,
    Function(UserCredential)? onAutoVerified,
  ) =>
      _runOperation(
        () => ref.read(authServiceProvider).verifyPhone(
          phoneNumber,
          (id) {
            state = state.copyWith(isLoading: false);
            onCodeSent(id);
          },
          (message) {
            state = state.copyWith(isLoading: false, error: message);
            onError(message);
          },
          (credential) {
            state = state.copyWith(user: credential.user, isLoading: false);
            onAutoVerified?.call(credential);
          },
        ),
      );

  Future<bool> checkEmailVerification() async {
    final verified =
        await ref.read(authServiceProvider).checkEmailVerification();
    state = state.copyWith(user: ref.read(authServiceProvider).currentUser);
    return verified;
  }

  // ✅ FIX: Updated token refresh to update state
  Future<String?> refreshToken({bool forceRefresh = true}) async {
    try {
      final token = await ref.read(authServiceProvider).refreshToken(forceRefresh: forceRefresh);
      // ✅ FIX: Update user state after token refresh
      final user = ref.read(authServiceProvider).currentUser;
      state = state.copyWith(user: user);
      return token;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authServiceProvider).signOut();
      state = const AuthState();
    } catch (error, stackTrace) {
      logger.error('Sign-out failed',
          tag: 'Auth', error: error, stackTrace: stackTrace);
      state = AuthState(error: error.toString());
      rethrow;
    }
  }

  Future<UserCredential> _runUserOperation(
    Future<UserCredential> Function() operation,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await operation();
      state = state.copyWith(user: credential.user, isLoading: false);
      return credential;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      rethrow;
    }
  }

  Future<void> _runOperation(Future<void> Function() operation) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await operation();
      state = state.copyWith(isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      rethrow;
    }
  }
}