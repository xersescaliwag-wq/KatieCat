import 'package:supabase_flutter/supabase_flutter.dart';

/// The subset of auth operations the UI needs.
///
/// [AuthService] implements this, and widgets accept an [AuthApi] so tests can
/// substitute a fake instead of a live Supabase client.
abstract class AuthApi {
  User? get currentUser;
  Session? get currentSession;
  Stream<AuthState> get authChanges;

  Future<bool> signUp({required String email, required String password});

  Future<void> signInWithPassword({required String email, required String password});

  Future<void> sendEmailOtp(String email);

  Future<void> verifyEmailOtp({required String email, required String code});

  Future<void> sendPasswordReset(String email);

  Future<void> updatePassword(String newPassword);

  Future<void> signOut();
}
