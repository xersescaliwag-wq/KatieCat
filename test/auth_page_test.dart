import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katiecat/pages/auth_page.dart';
import 'package:katiecat/services/auth_api.dart';
import 'package:katiecat/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory [AuthApi] so the widget tests never touch the network.
class FakeAuthApi implements AuthApi {
  FakeAuthApi({
    this.signUpResult = false,
    this.sendOtpError,
    this.verifyOtpError,
    this.resetError,
    this.signInError,
  });

  /// When false, signUp reports "confirmation email sent" (no session).
  final bool signUpResult;
  AuthException? sendOtpError;
  AuthException? verifyOtpError;
  AuthException? resetError;
  AuthException? signInError;

  /// When set, [sendEmailOtp] waits on it — used to simulate a slow request
  /// so a test can dispose the page while it is still in flight.
  Completer<void>? sendOtpGate;

  final List<String> calls = <String>[];
  String? lastEmail;
  String? lastCode;
  String? lastPassword;

  @override
  User? get currentUser => null;

  @override
  Session? get currentSession => null;

  @override
  Stream<AuthState> get authChanges => const Stream<AuthState>.empty();

  @override
  Future<bool> signUp({required String email, required String password}) async {
    calls.add('signUp');
    lastEmail = email;
    lastPassword = password;
    return signUpResult;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    calls.add('signInWithPassword');
    lastEmail = email;
    lastPassword = password;
    final error = signInError;
    if (error != null) throw error;
  }

  @override
  Future<void> sendEmailOtp(String email) async {
    calls.add('sendEmailOtp');
    lastEmail = email;
    final gate = sendOtpGate;
    if (gate != null) await gate.future;
    final error = sendOtpError;
    if (error != null) throw error;
  }

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    calls.add('verifyEmailOtp');
    lastEmail = email;
    lastCode = code;
    final error = verifyOtpError;
    if (error != null) throw error;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    calls.add('sendPasswordReset');
    lastEmail = email;
    final error = resetError;
    if (error != null) throw error;
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    calls.add('updatePassword');
    lastPassword = newPassword;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
  }
}

/// Text fields in on-screen order:
/// email always; password (sign-in w/ password, or sign-up); confirm (sign-up);
/// OTP code (after a code was sent). Looked up by index rather than by
/// placeholder, because a filled field no longer renders its placeholder.
Finder _field(WidgetTester tester, int index) =>
    find.byType(CupertinoTextField).at(index);

Future<void> _enter(WidgetTester tester, int index, String text) async {
  expect(find.byType(CupertinoTextField), findsWidgets);
  await tester.enterText(_field(tester, index), text);
}

Future<void> _pumpAuth(WidgetTester tester, FakeAuthApi auth) async {
  await tester.pumpWidget(
    CupertinoApp(
      theme: const CupertinoThemeData(brightness: Brightness.dark),
      home: AuthPage(auth: auth),
    ),
  );
  await tester.pump();
}

/// Taps a label; buttons are rendered after titles/messages, so the last
/// match wins when a string appears twice (e.g. "Create account").
Future<void> _tap(WidgetTester tester, String label) async {
  final matches = find.text(label);
  expect(matches, findsWidgets, reason: 'label "$label" not found');
  await tester.tap(matches.last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Unmounts the page so no resend countdown timer is left running.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const CupertinoApp(home: SizedBox()));
  await tester.pump();
}

void main() {
  testWidgets('rejects invalid email before any network call',
      (tester) async {
    final auth = FakeAuthApi();
    await _pumpAuth(tester, auth);

    await _enter(tester, 0, 'not-an-email');
    await _tap(tester, 'Sign in');

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('password sign-in passes trimmed email and password',
      (tester) async {
    final auth = FakeAuthApi();
    await _pumpAuth(tester, auth);

    await _enter(tester, 0, '  user@test.com ');
    await _enter(tester, 1, 'supersecret1');
    await _tap(tester, 'Sign in');

    expect(auth.calls, ['signInWithPassword']);
    expect(auth.lastEmail, 'user@test.com');
    expect(auth.lastPassword, 'supersecret1');
  });

  testWidgets('blocks passwords shorter than Supabase min length',
      (tester) async {
    final auth = FakeAuthApi();
    await _pumpAuth(tester, auth);

    await _tap(tester, "Don't have an account? Register");
    await _enter(tester, 0, 'user@test.com');
    await _enter(tester, 1, 'short');
    await _enter(tester, 2, 'short');
    await _tap(tester, 'Create account');

    expect(
      find.text(
          'Password must be at least ${AuthService.minPasswordLength} characters.'),
      findsOneWidget,
    );
    expect(auth.calls, isEmpty);
  });

  testWidgets('sign-up mismatched passwords are rejected locally',
      (tester) async {
    final auth = FakeAuthApi();
    await _pumpAuth(tester, auth);

    await _tap(tester, "Don't have an account? Register");
    await _enter(tester, 0, 'user@test.com');
    await _enter(tester, 1, 'abcdefghij');
    await _enter(tester, 2, 'abcdefghik');
    await _tap(tester, 'Create account');

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('sign-up success flips back to sign-in with confirmation note',
      (tester) async {
    final auth = FakeAuthApi();
    await _pumpAuth(tester, auth);

    await _tap(tester, "Don't have an account? Register");
    await _enter(tester, 0, 'new@test.com');
    await _enter(tester, 1, 'abcdefghij');
    await _enter(tester, 2, 'abcdefghij');
    await _tap(tester, 'Create account');

    expect(auth.calls, ['signUp']);
    expect(auth.lastEmail, 'new@test.com');
    expect(find.text('Account created! Check your email to confirm it.'),
        findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('email-code send shows the 8-digit field and success note',
      (tester) async {
    final auth = FakeAuthApi();
    await _pumpAuth(tester, auth);

    await _enter(tester, 0, 'user@test.com');
    await _tap(tester, 'Email code');
    await _tap(tester, 'Send code');

    expect(auth.calls, ['sendEmailOtp']);
    expect(auth.lastEmail, 'user@test.com');
    expect(find.text('We sent a code to user@test.com.'), findsOneWidget);
    expect(find.byType(CupertinoTextField), findsNWidgets(2));
    expect(find.text('${AuthService.otpLength}-digit code'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('send failure keeps the send state so the user can retry',
      (tester) async {
    final auth = FakeAuthApi(
      sendOtpError: const AuthException('Could not send the email right now.'),
    );
    await _pumpAuth(tester, auth);

    await _enter(tester, 0, 'user@test.com');
    await _tap(tester, 'Email code');
    await _tap(tester, 'Send code');

    expect(find.text('Could not send the email right now.'), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget); // still sendable
    expect(find.text('${AuthService.otpLength}-digit code'), findsNothing);

    // Retry succeeds once the backend recovers.
    auth.sendOtpError = null;
    await _tap(tester, 'Send code');
    expect(auth.calls, ['sendEmailOtp', 'sendEmailOtp']);
    expect(find.text('${AuthService.otpLength}-digit code'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('verify requires a full-length code', (tester) async {
    final auth = FakeAuthApi();
    await _pumpAuth(tester, auth);

    await _enter(tester, 0, 'user@test.com');
    await _tap(tester, 'Email code');
    await _tap(tester, 'Send code');
    await _enter(tester, 1, '123');
    await _tap(tester, 'Verify code');

    expect(
      find.text(
          'Enter the ${AuthService.otpLength}-digit code from your email.'),
      findsOneWidget,
    );
    expect(auth.calls, ['sendEmailOtp']); // verify never fired
    await _unmount(tester);
  });

  testWidgets('verify sends the full-length code and reports success',
      (tester) async {
    final auth = FakeAuthApi();
    await _pumpAuth(tester, auth);

    await _enter(tester, 0, 'user@test.com');
    await _tap(tester, 'Email code');
    await _tap(tester, 'Send code');
    await _enter(tester, 1, '12345678');
    await _tap(tester, 'Verify code');

    expect(auth.calls, ['sendEmailOtp', 'verifyEmailOtp']);
    expect(auth.lastCode, '12345678');
    expect(find.text('Signed in!'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('invalid code surfaces the friendly error', (tester) async {
    final auth = FakeAuthApi(
      verifyOtpError: const AuthException(
          'That code is invalid or has expired. Please request a new one.'),
    );
    await _pumpAuth(tester, auth);

    await _enter(tester, 0, 'user@test.com');
    await _tap(tester, 'Email code');
    await _tap(tester, 'Send code');
    await _enter(tester, 1, '87654321');
    await _tap(tester, 'Verify code');

    expect(
        find.text(
            'That code is invalid or has expired. Please request a new one.'),
        findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('resend is on cooldown right after a code is sent',
      (tester) async {
    final auth = FakeAuthApi();
    await _pumpAuth(tester, auth);

    await _enter(tester, 0, 'user@test.com');
    await _tap(tester, 'Email code');
    await _tap(tester, 'Send code');

    expect(find.text('Resend code in 60s'), findsOneWidget);
    expect(auth.calls, ['sendEmailOtp']);

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Resend code in 55s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 55));
    expect(find.text('Resend code'), findsOneWidget);

    await _tap(tester, 'Resend code');
    expect(auth.calls, ['sendEmailOtp', 'sendEmailOtp']);
    await _unmount(tester);
  });

  testWidgets('forgot password requires a valid email first', (tester) async {
    final auth = FakeAuthApi();
    await _pumpAuth(tester, auth);

    await _tap(tester, 'Forgot password?');
    expect(find.text('Enter your email above first.'), findsOneWidget);
    expect(auth.calls, isEmpty);

    await _enter(tester, 0, 'user@test.com');
    await _tap(tester, 'Forgot password?');
    expect(auth.calls, ['sendPasswordReset']);
    expect(
        find.text('Reset link sent. Open it on this device.'), findsOneWidget);
  });

  testWidgets('forgot password shows backend errors', (tester) async {
    final auth = FakeAuthApi(
      resetError: const AuthException('Too many reset emails requested.'),
    );
    await _pumpAuth(tester, auth);

    await _enter(tester, 0, 'user@test.com');
    await _tap(tester, 'Forgot password?');
    expect(find.text('Too many reset emails requested.'), findsOneWidget);
  });

  testWidgets('switching back to password clears the OTP state',
      (tester) async {
    final auth = FakeAuthApi();
    await _pumpAuth(tester, auth);

    await _enter(tester, 0, 'user@test.com');
    await _tap(tester, 'Email code');
    await _tap(tester, 'Send code');
    expect(find.byType(CupertinoTextField), findsNWidgets(2));
    expect(find.text('Resend code in 60s'), findsOneWidget);

    await _tap(tester, 'Use password');
    expect(find.byType(CupertinoTextField), findsNWidgets(2)); // email+password
    expect(find.textContaining('Resend code'), findsNothing);
    expect(find.text('${AuthService.otpLength}-digit code'), findsNothing);
  });

  testWidgets('disposing the page during a send does not crash',
      (tester) async {
    final auth = FakeAuthApi()..sendOtpGate = Completer<void>();
    await _pumpAuth(tester, auth);

    await _enter(tester, 0, 'user@test.com');
    await _tap(tester, 'Email code');
    await _tap(tester, 'Send code');
    expect(auth.calls, ['sendEmailOtp']); // request is now in flight

    await _unmount(tester); // user navigates away mid-request
    auth.sendOtpGate!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
}
