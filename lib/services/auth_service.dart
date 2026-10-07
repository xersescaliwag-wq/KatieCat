import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase auth so the UI stays clean.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Redirect URL configured in Supabase dashboard.
  static const String redirectUrl = 'com.katiecat.app://auth-callback';

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  /// Returns true if a session was created immediately (email confirmation off),
  /// false if the user must confirm their email first.
  Future<bool> signUp({required String email, required String password}) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: redirectUrl,
    );
    return res.session != null;
  }

  // ---------------------------------------------------------------------------
  // Sign in with password
  // ---------------------------------------------------------------------------

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  // ---------------------------------------------------------------------------
  // Sign in with OTP (email code)
  // ---------------------------------------------------------------------------

  /// Step 1: send a 6-digit code to the email.
  Future<void> sendEmailOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
      emailRedirectTo: redirectUrl,
    );
  }

  /// Step 2: verify the code the user typed.
  Future<void> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    await _client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );
  }

  // ---------------------------------------------------------------------------
  // Reset password
  // ---------------------------------------------------------------------------

  /// Sends a reset link. Opening the link triggers
  /// [AuthChangeEvent.passwordRecovery], which the AuthGate listens for.
  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email, redirectTo: redirectUrl);
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ---------------------------------------------------------------------------
  // Sign in with Apple (native Apple SDK -> Supabase ID token)
  // ---------------------------------------------------------------------------

  /// Returns false if the user cancelled the Apple sheet.
  Future<bool> signInWithApple() async {
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      try {
        await _client.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: redirectUrl,
        );
        return true;
      } on AuthException catch (e) {
        if (e.message.contains('not enabled') || e.statusCode == '400') {
          throw const AuthException(
            'Apple Sign-In on Android requires an Apple Secret Key (.p8), Key ID, and Service ID configured in Supabase.',
          );
        }
        rethrow;
      }
    }

    final rawNonce = _randomNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('Apple did not return an identity token.');
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      // Apple only sends the name on the very first sign-in; save it.
      final given = credential.givenName;
      final family = credential.familyName;
      if (given != null || family != null) {
        await _client.auth.updateUser(UserAttributes(data: {
          'full_name': [given, family].whereType<String>().join(' '),
        }));
      }
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return false;
      if (e.code == AuthorizationErrorCode.unknown) {
        throw const AuthException(
          'Sign in with Apple error 1000: Please rebuild the app with the new entitlements file or sign into Apple ID on this device.',
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

  Future<void> signOut() => _client.auth.signOut();

  // ---------------------------------------------------------------------------

  String _randomNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
          (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}