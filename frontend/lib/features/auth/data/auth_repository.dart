import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/constants/hive_keys.dart';

class AuthRepository {
  final ApiService _api;

  AuthRepository(this._api);

  // ─── Check if user is logged in (from Hive) ─────────────────────
  Future<UserModel?> getStoredUser() async {
    final box = Hive.box(HiveKeys.userBox);
    final token = box.get(HiveKeys.accessToken);
    final userJson = box.get(HiveKeys.userJson);
    if (token == null || userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  // ─── Google Sign In ──────────────────────────────────────────────
  Future<UserModel> loginWithGoogle(String idToken) async {
    final res = await _api.post('/auth/google', data: {'idToken': idToken});
    return _handleAuthResponse(res.data);
  }

  // ─── Email Login ─────────────────────────────────────────────────
  Future<UserModel> loginWithEmail(String email, String password) async {
    final res = await _api.post('/auth/login', data: {'email': email, 'password': password});
    return _handleAuthResponse(res.data);
  }

  // ─── Email Register ──────────────────────────────────────────────
  Future<void> registerWithEmail(String name, String email, String password) async {
    await _api.post('/auth/register', data: {'name': name, 'email': email, 'password': password});
  }

  // ─── Verify OTP ──────────────────────────────────────────────────
  Future<void> verifyOtp(String email, String otp) async {
    await _api.post('/auth/verify-otp', data: {'email': email, 'otp': otp});
  }

  // ─── Forgot Password ─────────────────────────────────────────────
  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', data: {'email': email});
  }

  // ─── Reset Password ──────────────────────────────────────────────
  Future<void> resetPassword(String email, String otp, String newPassword) async {
    await _api.post('/auth/reset-password', data: {'email': email, 'otp': otp, 'newPassword': newPassword});
  }

  // ─── Get current user from API ───────────────────────────────────
  Future<UserModel> getCurrentUser() async {
    final res = await _api.get('/auth/me');
    final user = UserModel.fromJson(res.data['user']);
    await _storeUser(user);
    return user;
  }

  // ─── Update profile ──────────────────────────────────────────────
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final res = await _api.put('/user/profile', data: data);
    final user = UserModel.fromJson(res.data['user']);
    await _storeUser(user);
    return user;
  }

  // ─── Update platforms ────────────────────────────────────────────
  Future<void> updatePlatforms(Map<String, String> platforms) async {
    await _api.put('/user/platforms', data: platforms);
  }

  // ─── Update onboarding step ──────────────────────────────────────
  Future<UserModel> updateOnboarding({required int step, bool complete = false, Map<String, dynamic>? data}) async {
    final res = await _api.put('/user/onboarding', data: {
      'step': step,
      if (complete) 'complete': true,
      if (data != null) ...data,
    });
    final user = UserModel.fromJson(res.data['user']);
    await _storeUser(user);
    return user;
  }

  // ─── Logout ──────────────────────────────────────────────────────
  Future<void> logout() async {
    final box = Hive.box(HiveKeys.userBox);
    await box.deleteAll([HiveKeys.accessToken, HiveKeys.refreshToken, HiveKeys.userJson]);
  }

  // ─── Internal helpers ────────────────────────────────────────────
  Future<UserModel> _handleAuthResponse(Map<String, dynamic> data) async {
    final user = UserModel.fromJson(data['user']);
    final box = Hive.box(HiveKeys.userBox);
    await box.put(HiveKeys.accessToken, data['accessToken']);
    if (data['refreshToken'] != null) {
      await box.put(HiveKeys.refreshToken, data['refreshToken']);
    }
    await _storeUser(user);
    return user;
  }

  Future<void> _storeUser(UserModel user) async {
    final box = Hive.box(HiveKeys.userBox);
    await box.put(HiveKeys.userJson, jsonEncode(user.toJson()));
  }
}
