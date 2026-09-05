class EmailValidator {
  const EmailValidator._();

  static bool isValid(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[A-Za-z]{2,}$').hasMatch(email.trim());
  }
}
