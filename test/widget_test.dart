import 'package:flutter_test/flutter_test.dart';
import 'package:katiecat/services/auth_api.dart';
import 'package:katiecat/services/auth_service.dart';

void main() {
  test('AuthService implements the AuthApi contract the UI depends on', () {
    expect(AuthService.instance, isA<AuthApi>());
  });

  test('auth constants match the Supabase project configuration', () {
    // Dashboard > Auth > Settings: password_min_length = 10
    expect(AuthService.minPasswordLength, 10);
    // Dashboard > Auth > Email: mailer_otp_length = 8
    expect(AuthService.otpLength, 8);
    expect(AuthService.redirectUrl, 'com.katiecat.app://auth-callback');
  });
}
