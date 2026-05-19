import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/domain/auth_models.dart';
import 'package:frontend/providers/core_providers.dart';

class AuthRepository {
  final Dio _dio;
  final FirebaseAuth _firebaseAuth;

  AuthRepository(this._dio, this._firebaseAuth);

  /// Triggers Firebase to send an SMS OTP to [phoneNumber].
  /// Returns the verificationId once Firebase confirms the SMS was sent.
  /// Throws a [String] error message on failure.
  Future<String> sendOtp(String phoneNumber) async {
    final completer = Completer<String>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (_) {
        // Auto-retrieval not used — we always want manual OTP entry.
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(e.message ?? 'Verification failed');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );

    return completer.future;
  }

  /// Verifies the [smsCode] against [verificationId] with Firebase,
  /// then sends the resulting ID token to our Django backend to get a DRF token.
  Future<AuthSession> verifyOtp(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final idToken = await userCredential.user!.getIdToken();

    final response = await _dio.post(
      '/api/users/auth/verify-otp/',
      data: {'id_token': idToken},
    );
    return AuthSession.fromJson(response.data);
  }

  Future<MeData> getMe() async {
    final response = await _dio.get('/api/users/auth/me/');
    return MeData.fromJson(response.data);
  }

  Future<void> markOnboarded() => _dio.post('/api/users/auth/onboarded/');

  /// Verifies a new phone number via Firebase and sends its id_token to the backend.
  Future<void> changePhone(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final idToken = await userCredential.user!.getIdToken();
    await _dio.post('/api/users/change-phone/confirm/', data: {'id_token': idToken});
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(dioProvider), FirebaseAuth.instance),
);
