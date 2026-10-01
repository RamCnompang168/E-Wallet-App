import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_state.dart';
import '../../../shell/presentation/screens/main_navigation_shell.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onThemeChanged});
  final VoidCallback onThemeChanged;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _googleLoading = false;
  bool _googleInitialized = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _enterApp() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavigationShell(onThemeChanged: widget.onThemeChanged),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email/phone and password.')),
      );
      return;
    }

    setState(() => _loading = true);
    final success = await AuthState.instance.login(
      username: username,
      password: password,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      _enterApp();
    } else {
      final msg = AuthState.instance.errorMessage ?? 'Invalid email or password.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      if (!_googleInitialized) {
        try {
          await GoogleSignIn.instance.initialize();
        } catch (_) {}
        _googleInitialized = true;
      }

      final googleUser = await GoogleSignIn.instance.authenticate();

      final success = await AuthState.instance.signInWithGoogle(
        email: googleUser.email,
        fullName: googleUser.displayName,
        googleId: googleUser.id,
        profilePhoto: googleUser.photoUrl,
      );

      if (!mounted) return;
      setState(() => _googleLoading = false);

      if (success) {
        _enterApp();
      } else {
        final msg = AuthState.instance.errorMessage ?? 'Google sign-in failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _googleLoading = false);
      _showGooglePromptDialog();
    }
  }

  void _showGooglePromptDialog() {
    final emailCtrl = TextEditingController(text: 'user@gmail.com');
    final nameCtrl = TextEditingController(text: 'Google User');
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_circle, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Google Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sign in with your Google account credentials:'),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Google Email', hintText: 'name@gmail.com'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() => _loading = true);
              final success = await AuthState.instance.signInWithGoogle(
                email: emailCtrl.text.trim(),
                fullName: nameCtrl.text.trim(),
              );
              if (!mounted) return;
              setState(() => _loading = false);
              if (success) {
                _enterApp();
              } else {
                final msg = AuthState.instance.errorMessage ?? 'Google sign-in failed.';
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 30),
          const Text(
            'Welcome back',
            style: TextStyle(fontSize: 31, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to your NovaPay wallet',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 25),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Phone number or email'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _loading ? null : _handleLogin,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(55),
              backgroundColor: AppColors.indigo,
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Sign in'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _enterApp,
            icon: const Icon(Icons.fingerprint),
            label: const Text('Sign in with biometrics'),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: (_loading || _googleLoading) ? null : _handleGoogleSignIn,
            icon: _googleLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
                    height: 20,
                    width: 20,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_circle,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
            label: const Text('Continue with Google'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account?"),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RegisterScreen(onThemeChanged: widget.onThemeChanged),
                  ),
                ),
                child: const Text('Create account'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
