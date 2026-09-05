import 'package:firebase_auth/firebase_auth.dart';

// ============================================
// BASE EXCEPTIONS
// ============================================

/// Base exception class for all authentication errors
class AuthException implements Exception {
  final String message;
  final String? code;
  final String? localizationKey;
  final StackTrace? stackTrace;

  const AuthException(
    this.message, {
    this.code,
    this.localizationKey,
    this.stackTrace,
  });

  @override
  String toString() {
    var result = message;
    if (code != null) {
      result += ' (code: $code)';
    }
    if (localizationKey != null) {
      result += ' [key: $localizationKey]';
    }
    return result;
  }

  // ✅ Factory method for Firebase error conversion
  factory AuthException.fromFirebase(
    FirebaseAuthException error, {
    StackTrace? stackTrace,
    String? localizationKey,
  }) {
    switch (error.code) {
      // Validation errors
      case 'invalid-phone-number':
        return InvalidPhoneNumberException(
          _getMessageForCode(error.code),
          code: error.code,
          stackTrace: stackTrace,
        );
      case 'invalid-email':
        return InvalidEmailException(
          _getMessageForCode(error.code),
          code: error.code,
          stackTrace: stackTrace,
        );
      case 'weak-password':
        return WeakPasswordException(
          _getMessageForCode(error.code),
          code: error.code,
          stackTrace: stackTrace,
        );

      // Rate limiting
      case 'too-many-requests':
        return AuthRateLimitException(
          _getMessageForCode(error.code),
          code: error.code,
          stackTrace: stackTrace,
        );

      // Session errors
      case 'session-expired':
        return SessionExpiredException(
          _getMessageForCode(error.code),
          code: error.code,
          stackTrace: stackTrace,
        );
      case 'invalid-verification-code':
        return SessionExpiredException(
          'The OTP is incorrect or expired. Please request a new one.',
          code: error.code,
          stackTrace: stackTrace,
        );

      // Account errors
      case 'user-not-found':
        return AccountNotFoundException(
          _getMessageForCode(error.code),
          code: error.code,
          stackTrace: stackTrace,
        );
      case 'account-exists-with-different-credential':
        return const AuthFailureException(
          'An account already exists with a different sign-in method.',
        );
      case 'email-already-in-use':
        return const AuthFailureException(
          'An account already exists with this email address.',
        );

      // Credential errors
      case 'wrong-password':
        return InvalidCredentialsException(
          _getMessageForCode(error.code),
          code: error.code,
          stackTrace: stackTrace,
        );
      case 'invalid-credential':
        return InvalidCredentialsException(
          _getMessageForCode(error.code),
          code: error.code,
          stackTrace: stackTrace,
        );

      // Network errors
      case 'network-request-failed':
        return NetworkException(
          _getMessageForCode(error.code),
          code: error.code,
          stackTrace: stackTrace,
        );

      // Email verification
      case 'requires-recent-login':
        return const AuthFailureException(
          'This operation requires recent authentication. Please sign in again.',
        );

      // Default
      default:
        return AuthFailureException(
          error.message ?? 'Authentication failed. Please try again.',
          code: error.code,
          stackTrace: stackTrace,
        );
    }
  }

  static String _getMessageForCode(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Please enter a valid phone number.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'session-expired':
        return 'Your session has expired. Please try again.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

// ============================================
// GENERAL EXCEPTIONS
// ============================================

/// Generic authentication failure
class AuthFailureException extends AuthException {
  const AuthFailureException(
    super.message, {
    super.code,
    super.localizationKey,
    super.stackTrace,
  });
}

/// User cancelled the authentication operation
class AuthCancelledException extends AuthException {
  const AuthCancelledException(
    super.message, {
    super.code,
    super.localizationKey,
    super.stackTrace,
  });
}

/// Rate limit exceeded
class AuthRateLimitException extends AuthException {
  final int? waitSeconds;

  const AuthRateLimitException(
    super.message, {
    this.waitSeconds,
    super.code,
    super.localizationKey,
    super.stackTrace,
  });
}

// ============================================
// VALIDATION EXCEPTIONS
// ============================================

/// Base validation exception
class AuthValidationException extends AuthException {
  const AuthValidationException(
    super.message, {
    super.code,
    super.localizationKey,
    super.stackTrace,
  });
}

/// Invalid phone number
class InvalidPhoneNumberException extends AuthValidationException {
  const InvalidPhoneNumberException(
    super.message, {
    super.code,
    super.localizationKey,
    super.stackTrace,
  });
}

/// Invalid email address
class InvalidEmailException extends AuthValidationException {
  const InvalidEmailException(
    super.message, {
    super.code,
    super.localizationKey,
    super.stackTrace,
  });
}

/// Weak password
class WeakPasswordException extends AuthValidationException {
  const WeakPasswordException(
    super.message, {
    super.code,
    super.localizationKey,
    super.stackTrace,
  });
}

// ============================================
// ACCOUNT EXCEPTIONS
// ============================================

/// Account not found
class AccountNotFoundException extends AuthException {
  const AccountNotFoundException(
    super.message, {
    super.code,
    super.localizationKey,
    super.stackTrace,
  });
}

/// Account locked due to too many failed attempts
class AccountLockedException extends AuthException {
  final int? remainingMinutes;

  const AccountLockedException(
    super.message, {
    this.remainingMinutes,
    super.code,
    super.localizationKey,
    super.stackTrace,
  });
}

/// Email verification required
class EmailVerificationRequiredException extends AuthException {
  const EmailVerificationRequiredException(
    super.message, {
    super.code,
    super.localizationKey,
    super.stackTrace,
  });
}

// ============================================
// CREDENTIAL EXCEPTIONS
// ============================================

/// Invalid credentials
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException(
    super.message, {
    super.code,
    super.localizationKey,
    super.stackTrace,
  });
}

// ============================================
// SESSION EXCEPTIONS
// ============================================

/// Session expired
class SessionExpiredException extends AuthException {
  const SessionExpiredException(
    super.message, {
    super.code,
    super.localizationKey,
    super.stackTrace,
  });
}

// ============================================
// NETWORK EXCEPTIONS
// ============================================

/// Network error
class NetworkException extends AuthException {
  const NetworkException(
    super.message, {
    super.code,
    super.localizationKey,
    super.stackTrace,
  });
}

// ============================================
// UTILITY EXTENSIONS
// ============================================

/// Extension to convert FirebaseAuthException to AuthException
extension FirebaseAuthExceptionExtension on FirebaseAuthException {
  AuthException toAuthException({StackTrace? stackTrace}) {
    return AuthException.fromFirebase(
      this,
      stackTrace: stackTrace,
    );
  }
}