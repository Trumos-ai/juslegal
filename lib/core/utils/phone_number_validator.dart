import '../config/app_config.dart';
import '../../services/auth_exceptions.dart';

class PhoneNumberValidator {
  PhoneNumberValidator._();

  // India-specific constants
  static const int _indianPhoneLength = 10;
  
  static String normalize(String phoneNumber) {
    final compact = phoneNumber.trim().replaceAll(RegExp(r'[\s()-]'), '');
    final countryCode = AppConfig.defaultCountryCode.trim();
    final countryDigits = countryCode.replaceAll(RegExp(r'\D'), '');
    final digits = compact.replaceAll(RegExp(r'\D'), '');

    if (compact.startsWith('+')) {
      return '+$digits';
    }
    if (digits.startsWith(countryDigits) && 
        digits.length == countryDigits.length + _indianPhoneLength) {
      return '+$digits';
    }
    if (digits.length == _indianPhoneLength) {
      return '$countryCode$digits';
    }
    return '+$digits';
  }

  static bool isValid(String phoneNumber) {
    final normalized = normalize(phoneNumber);
    final countryDigits = AppConfig.defaultCountryCode.replaceAll(RegExp(r'\D'), '');
    final digits = normalized.replaceAll(RegExp(r'\D'), '');

    return normalized.startsWith('+$countryDigits') &&
        digits.length == countryDigits.length + _indianPhoneLength &&
        RegExp(r'^[6-9]').hasMatch(digits.substring(countryDigits.length));
  }

  static String normalizeOrThrow(String phoneNumber) {
    if (!isValid(phoneNumber)) {
      throw const InvalidPhoneNumberException(
        'Enter a valid 10-digit Indian mobile number.',
      );
    }
    return normalize(phoneNumber);
  }
}