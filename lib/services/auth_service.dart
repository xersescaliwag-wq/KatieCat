import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_api.dart';

/// Thin wrapper around Supabase auth so the UI stays clean.
class AuthService implements AuthApi {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Redirect URL configured in Supabase dashboard.
  static const String redirectUrl = 'com.katiecat.app://auth-callback';

  /// Minimum password length enforced by this project in Supabase
  /// (Dashboard > Auth > Settings > Password). Shorter ones are rejected
  /// server-side, so validating here keeps the message friendly.
  static const int minPasswordLength = 10;

  /// Digits in the emailed OTP (Supabase Dashboard > Auth > Email).
  static const int otpLength = 8;

  @override
  User? get currentUser => _client.auth.currentUser;
  @override
  Session? get currentSession => _client.auth.currentSession;
  @override
  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  /// Returns true if a session was created immediately (email confirmation off),
  /// false if the user must confirm their email first.
  @override
  Future<bool> signUp({required String email, required String password}) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: redirectUrl,
      );
      return res.session != null;
    } on AuthException catch (e) {
      if (e.statusCode == '429' || e.message.contains('rate limit')) {
        throw const AuthException(
          'Too many requests. Please wait a minute before trying again.',
        );
      }
      if (e.message.contains('already registered') ||
          e.message.contains('already exists') ||
          e.statusCode == '422') {
        throw const AuthException(
          'This email is already registered. Please sign in instead.',
        );
      }
      if (e.message.contains('disabled')) {
        throw const AuthException(
          'Signups are disabled. Please contact support.',
        );
      }
      if (e.message.contains('password') &&
          (e.message.contains('least') || e.message.contains('length'))) {
        throw AuthException(
          'Password must be at least $minPasswordLength characters.',
        );
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Sign in with password
  // ---------------------------------------------------------------------------

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      if (e.statusCode == '400' &&
          (e.message.contains('Invalid login credentials') ||
              e.message.contains('invalid_credentials'))) {
        throw const AuthException('Incorrect email or password.');
      }
      if (e.statusCode == '429' || e.message.contains('rate limit')) {
        throw const AuthException(
          'Too many sign-in attempts. Please wait a minute and try again.',
        );
      }
      if (e.message.contains('Email not confirmed') ||
          e.message.contains('email_not_confirmed')) {
        throw const AuthException(
          'This email is not confirmed yet. Check your inbox for the confirmation link.',
        );
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Sign in with OTP (email code)
  // ---------------------------------------------------------------------------

  /// Step 1: send the code to the email.
  @override
  Future<void> sendEmailOtp(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
        emailRedirectTo: redirectUrl,
      );
    } on AuthException catch (e) {
      if (e.statusCode == '429' || e.message.contains('rate limit')) {
        throw const AuthException(
          'Too many codes requested. Please wait a minute before asking for another one.',
        );
      }
      if (e.statusCode == '504' ||
          e.message.toLowerCase().contains('timeout') ||
          e.message.toLowerCase().contains('upstream')) {
        throw const AuthException(
          'The email service timed out. Please try again in a moment.',
        );
      }
      if (e.statusCode == '500' ||
          e.message.toLowerCase().contains('sending') ||
          e.message.toLowerCase().contains('smtp')) {
        throw const AuthException(
          'Could not send the email right now. Please try again in a moment.',
        );
      }
      rethrow;
    }
  }

  /// Step 2: verify the code the user typed.
  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid') ||
          e.message.toLowerCase().contains('expired') ||
          e.message.toLowerCase().contains('not found') ||
          e.statusCode == '400' ||
          e.statusCode == '404') {
        throw const AuthException(
          'That code is invalid or has expired. Please request a new one.',
        );
      }
      if (e.statusCode == '429' || e.message.contains('rate limit')) {
        throw const AuthException(
          'Too many attempts. Please wait a minute and try again.',
        );
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Reset password
  // ---------------------------------------------------------------------------

  /// Sends a reset link. Opening the link triggers
  /// [AuthChangeEvent.passwordRecovery], which the AuthGate listens for.
  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email, redirectTo: redirectUrl);
    } on AuthException catch (e) {
      if (e.statusCode == '429' || e.message.contains('rate limit')) {
        throw const AuthException(
          'Too many reset emails requested. Please wait a minute before trying again.',
        );
      }
      if (e.statusCode == '504' ||
          e.statusCode == '500' ||
          e.message.toLowerCase().contains('timeout') ||
          e.message.toLowerCase().contains('upstream')) {
        throw const AuthException(
          'Could not send the reset email right now. Please try again in a moment.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      if (e.message.contains('password') &&
          (e.message.contains('least') || e.message.contains('length'))) {
        throw AuthException(
          'Password must be at least $minPasswordLength characters.',
        );
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Print current user / sign out
  // ---------------------------------------------------------------------------

  /// Prints the current user to the debug console and returns the JSON string.
  String printCurrentUser() {
    final user = currentUser;
    final text = user == null
        ? 'No user signed in.'
        : const JsonEncoder.withIndent('  ').convert(user.toJson());
    debugPrint('===== CURRENT USER =====\n$text');
    return text;
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}