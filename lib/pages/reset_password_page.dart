import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

/// Shown when the user opens the reset link from their email
/// (Supabase fires AuthChangeEvent.passwordRecovery).
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.onDone});

  /// Called after the password is updated so the gate can leave recovery mode.
  final VoidCallback onDone;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_password.text.length < AuthService.minPasswordLength) {
      setState(() =>
          _error = 'Password must be at least ${AuthService.minPasswordLength} characters.');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.updatePassword(_password.text);
      widget.onDone();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      background: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1026), Color(0xFF1B1B4B), Color(0xFF0E2A47)],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Set a new password',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassTextField(
                    useOwnLayer: true,
                    controller: _password,
                    placeholder: 'New password',
                    obscureText: true,
                    enabled: !_loading,
                    shape: const LiquidRoundedRectangle(borderRadius: 16),
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    useOwnLayer: true,
                    controller: _confirm,
                    placeholder: 'Confirm new password',
                    obscureText: true,
                    enabled: !_loading,
                    shape: const LiquidRoundedRectangle(borderRadius: 16),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style:
                        const TextStyle(color: CupertinoColors.systemRed)),
                  ],
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, c) => GlassButton.custom(
                      useOwnLayer: true,
                      width: c.maxWidth,
                      height: 52,
                      shape: const LiquidRoundedRectangle(borderRadius: 26),
                      enabled: !_loading,
                      onTap: _save,
                      label: 'Update password',
                      child: _loading
                          ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white)
                          : const Text(
                        'Update password',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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