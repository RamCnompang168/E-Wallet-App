import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Reset password',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          const TextField(
            decoration: InputDecoration(labelText: 'Phone number or email'),
          ),
          const SizedBox(height: 14),
          const TextField(
            decoration: InputDecoration(labelText: '6-digit reset code'),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Reset password'),
          ),
        ],
      ),
    ),
  );
}
