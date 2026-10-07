import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'pages/reset_password_page.dart';
import 'services/auth_service.dart';

// Supabase credentials
const supabaseUrl = 'https://dfccorjkvgvigzrpbiny.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmY2Nvcmprdmd2aWd6cnBiaW55Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEzMTc2NTEsImV4cCI6MjEwNjg5MzY1MX0.lJFHPEi1o3f9pUg8Fk5X8MAItpebcqcpOJ23-v1EkB4';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );
  runApp(LiquidGlassWidgets.wrap(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.dark),
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

/// Chooses which screen to show: login, password recovery, or home.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _sub;
  Session? _session = AuthService.instance.currentSession;
  bool _recovering = false;

  @override
  void initState() {
    super.initState();
    _sub = AuthService.instance.authChanges.listen((state) {
      if (!mounted) return;
      setState(() {
        _session = state.session;
        if (state.event == AuthChangeEvent.passwordRecovery) {
          _recovering = true;
        }
        if (state.event == AuthChangeEvent.signedOut) {
          _recovering = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_recovering && _session != null) {
      return ResetPasswordPage(
        onDone: () => setState(() => _recovering = false),
      );
    }
    return _session != null ? const HomePage() : const AuthPage();
  }
}