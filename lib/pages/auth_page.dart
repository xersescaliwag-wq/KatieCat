import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';

enum _Mode { signIn, signUp }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _auth = AuthService.instance;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _otp = TextEditingController();

  _Mode _mode = _Mode.signIn;
  int _method = 0; // 0 = password, 1 = OTP
  bool _otpSent = false;
  bool _loading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _otp.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- helpers

  void _show(String text, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _message = text;
      _isError = error;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      _show(e.message, error: true);
    } catch (e) {
      _show(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _emailOk => _email.text.trim().contains('@');

  // ---------------------------------------------------------------- actions

  Future<void> _submit() => _run(() async {
    final email = _email.text.trim();
    if (!_emailOk) return _show('Enter a valid email address.', error: true);

    // ---- Registration
    if (_mode == _Mode.signUp) {
      if (_password.text.length < 6) {
        return _show('Password must be at least 6 characters.',
            error: true);
      }
      if (_password.text != _confirm.text) {
        return _show('Passwords do not match.', error: true);
      }
      final signedIn =
      await _auth.signUp(email: email, password: _password.text);
      if (!signedIn) {
        _show('Account created. Check your email to confirm it.');
      }
      return;
    }

    // ---- Sign in with password
    if (_method == 0) {
      if (_password.text.isEmpty) {
        return _show('Enter your password.', error: true);
      }
      await _auth.signInWithPassword(email: email, password: _password.text);
      return;
    }

    // ---- Sign in with OTP
    if (!_otpSent) {
      await _auth.sendEmailOtp(email);
      setState(() => _otpSent = true);
      _show('We sent a code to $email.');
    } else {
      if (_otp.text.trim().length < 6) {
        return _show('Enter the code from your email.', error: true);
      }
      await _auth.verifyEmailOtp(email: email, code: _otp.text.trim());
    }
  });

  Future<void> _forgotPassword() => _run(() async {
    if (!_emailOk) {
      return _show('Enter your email above first.', error: true);
    }
    await _auth.sendPasswordReset(_email.text.trim());
    _show('Reset link sent. Open it on this device.');
  });

  Future<void> _apple() => _run(() async {
    await _auth.signInWithApple();
  });

  // ------------------------------------------------------------------- UI

  String get _title =>
      _mode == _Mode.signUp ? 'Create account' : 'Welcome back';

  String get _primaryLabel {
    if (_mode == _Mode.signUp) return 'Create account';
    if (_method == 1) return _otpSent ? 'Verify code' : 'Send code';
    return 'Sign in';
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _mode == _Mode.signIn;

    return GlassScaffold(
      background: const _AuthBackground(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSignIn
                        ? 'Sign in to continue.'
                        : 'Register with your email and a password.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xB3FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 24),

                  GlassTextField(
                    useOwnLayer: true,
                    controller: _email,
                    placeholder: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_loading,
                    prefixIcon: const Icon(CupertinoIcons.mail,
                        size: 20, color: Color(0xB3FFFFFF)),
                    shape: const LiquidRoundedRectangle(borderRadius: 16),
                  ),

                  if (!isSignIn || _method == 0) ...[
                    const SizedBox(height: 12),
                    GlassTextField(
                      useOwnLayer: true,
                      controller: _password,
                      placeholder: 'Password',
                      obscureText: true,
                      textInputAction: isSignIn
                          ? TextInputAction.done
                          : TextInputAction.next,
                      onSubmitted: (_) => isSignIn ? _submit() : null,
                      enabled: !_loading,
                      prefixIcon: const Icon(CupertinoIcons.lock,
                          size: 20, color: Color(0xB3FFFFFF)),
                      shape: const LiquidRoundedRectangle(borderRadius: 16),
                    ),
                  ],

                  if (!isSignIn) ...[
                    const SizedBox(height: 12),
                    GlassTextField(
                      useOwnLayer: true,
                      controller: _confirm,
                      placeholder: 'Confirm password',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      enabled: !_loading,
                      prefixIcon: const Icon(CupertinoIcons.lock_shield,
                          size: 20, color: Color(0xB3FFFFFF)),
                      shape: const LiquidRoundedRectangle(borderRadius: 16),
                    ),
                  ],

                  if (isSignIn && _method == 1 && _otpSent) ...[
                    const SizedBox(height: 12),
                    GlassTextField(
                      useOwnLayer: true,
                      controller: _otp,
                      placeholder: '6-digit code',
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      enabled: !_loading,
                      prefixIcon: const Icon(CupertinoIcons.number,
                          size: 20, color: Color(0xB3FFFFFF)),
                      shape: const LiquidRoundedRectangle(borderRadius: 16),
                    ),
                  ],

                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _isError
                            ? CupertinoColors.systemRed
                            : CupertinoColors.systemGreen,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  _GlassActionButton(
                    label: _primaryLabel,
                    loading: _loading,
                    onTap: _submit,
                  ),

                  if (isSignIn)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_method == 0)
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _loading ? null : _forgotPassword,
                              child: const Text('Forgot password?'),
                            )
                          else
                            const SizedBox.shrink(),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _loading
                                ? null
                                : () => setState(() {
                                      _method = _method == 0 ? 1 : 0;
                                      _otpSent = false;
                                      _otp.clear();
                                      _message = null;
                                    }),
                            child: Text(
                              _method == 0 ? 'Email code' : 'Use password',
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                  const _OrDivider(),
                  const SizedBox(height: 16),

                  _GlassActionButton(
                    label: 'Continue with Apple',
                    icon: const FaIcon(FontAwesomeIcons.apple,
                        size: 20, color: CupertinoColors.white),
                    loading: false,
                    onTap: _apple,
                  ),

                  const SizedBox(height: 12),
                  CupertinoButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                      _mode = isSignIn ? _Mode.signUp : _Mode.signIn;
                      _method = 0;
                      _otpSent = false;
                      _message = null;
                    }),
                    child: Text(isSignIn
                        ? "Don't have an account? Register"
                        : 'Already registered? Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Small building blocks
// -----------------------------------------------------------------------------

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({
    required this.label,
    required this.onTap,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GlassButton.custom(
        useOwnLayer: true,
        width: constraints.maxWidth,
        height: 52,
        shape: const LiquidRoundedRectangle(borderRadius: 26),
        enabled: !loading,
        onTap: onTap,
        label: label,
        child: loading
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 10)],
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: Color(0x33FFFFFF)),
      ),
    );
    return const Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or',
              style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13)),
        ),
        line,
      ],
    );
  }
}

/// Colourful backdrop so the glass has something to refract and blur.
class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1026), Color(0xFF1B1B4B), Color(0xFF0E2A47)],
            ),
          ),
        ),
        Positioned(
          top: -80,
          left: -60,
          child: _blob(const Color(0xFF7C4DFF), 280),
        ),
        Positioned(
          bottom: -100,
          right: -80,
          child: _blob(const Color(0xFF00B8D4), 320),
        ),
        Positioned(
          top: 320,
          right: -40,
          child: _blob(const Color(0xFFFF4081), 180),
        ),
      ],
    );
  }

  Widget _blob(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: 0.55),
    ),
  );
}