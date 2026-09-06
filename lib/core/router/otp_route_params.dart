class OtpRouteParams {
  const OtpRouteParams({
    required this.verificationId,
    required this.phoneNumber,
    this.legalName,
    this.isSignup = false,
  });

  final String verificationId;
  final String phoneNumber;
  final String? legalName;
  final bool isSignup;

  factory OtpRouteParams.fromExtra(Object? extra) {
    if (extra is OtpRouteParams) return extra;
    if (extra is Map) {
      return OtpRouteParams(
        verificationId: extra['verificationId'] as String? ?? '',
        phoneNumber: extra['phoneNumber'] as String? ?? '',
        legalName: extra['legalName'] as String?,
        isSignup: extra['isSignup'] as bool? ?? false,
      );
    }
    return const OtpRouteParams(verificationId: '', phoneNumber: '');
  }
}
