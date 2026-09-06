import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Keeps the public user record deliberately small; credentials always remain
/// with Firebase Authentication.
class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<bool> emailExists(String email, {String? exceptUid}) async {
    final result = await _users
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(2)
        .get();
    return result.docs.any((doc) => doc.id != exceptUid);
  }

  Future<bool> phoneExists(String phoneNumber, {String? exceptUid}) async {
    final result = await _users
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(2)
        .get();
    return result.docs.any((doc) => doc.id != exceptUid);
  }

  Future<bool> exists(String uid) async => (await _users.doc(uid).get()).exists;

  Future<void> saveProfile(
    User user, {
    required String legalName,
    required String provider,
    bool phoneVerified = false,
  }) async {
    final existing = await _users.doc(user.uid).get();
    final providers = <String>{
      ...?((existing.data()?['linkedAuthProviders'] as List?)?.cast<String>()),
      provider,
    }.toList();
    await _users.doc(user.uid).set({
      'legalName': legalName.trim(),
      if (user.email != null) 'email': user.email!.trim().toLowerCase(),
      if (user.phoneNumber != null) 'phoneNumber': user.phoneNumber,
      'authProvider': existing.data()?['authProvider'] ?? provider,
      'linkedAuthProviders': providers,
      'emailVerified': user.emailVerified,
      'phoneVerified': phoneVerified || user.phoneNumber != null,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markEmailVerified(String uid) => _users.doc(uid).set({
        'emailVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> delete(String uid) => _users.doc(uid).delete();
}
