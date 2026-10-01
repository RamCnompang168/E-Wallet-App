import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onThemeChanged});
  final VoidCallback onThemeChanged;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int index = 0;
  final titles = ['Send & receive', 'QR payments', 'Protected by design'];
  final icons = [
    Icons.send_rounded,
    Icons.qr_code_scanner_rounded,
    Icons.shield_rounded,
  ];

  void _skipToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(onThemeChanged: widget.onThemeChanged),
      ),
    );
  }

  void advance() {
    if (index == 2) {
      _skipToLogin();
    } else {
      setState(() => index++);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icons[index], size: 100, color: AppColors.indigo),
              const SizedBox(height: 38),
              Text(
                titles[index],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'A secure wallet designed around your daily life.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              Text(
                '${index + 1} of 3',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: advance,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppColors.indigo,
                ),
                child: Text(index == 2 ? 'Get started' : 'Continue'),
              ),
              TextButton(onPressed: _skipToLogin, child: const Text('Skip')),
            ],
          ),
        ),
      ),
    ),
  );
}
