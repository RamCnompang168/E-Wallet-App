import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SupportAndLegalScreen extends StatelessWidget {
  const SupportAndLegalScreen({super.key, this.initialTabIndex = 0});
  final int initialTabIndex;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    initialIndex: initialTabIndex,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Support & Legal'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'Help & FAQ'),
            Tab(text: 'About App'),
            Tab(text: 'Terms'),
            Tab(text: 'Privacy Policy'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          _HelpFaqTab(),
          _AboutAppTab(),
          _TermsTab(),
          _PrivacyPolicyTab(),
        ],
      ),
    ),
  );
}

class _HelpFaqTab extends StatelessWidget {
  const _HelpFaqTab();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 14),
      _faqItem('How do I send money?', 'Navigate to the Send icon on your Dashboard, search for the recipient by wallet ID or phone, enter the amount, and confirm using your 6-digit transaction PIN.'),
      _faqItem('What happens if I enter the wrong PIN 3 times?', 'Your transaction PIN will be automatically locked for 30 minutes to protect your funds against unauthorized access.'),
      _faqItem('How does double-entry accounting protect my balance?', 'Every transaction generates balanced debits and credits in an immutable ledger, ensuring zero money creation or loss.'),
      _faqItem('Are QR code payments supported?', 'Yes! You can generate a personal receive QR with an optional requested amount, or scan a merchant QR code.'),
      const SizedBox(height: 24),
      FilledButton.icon(
        icon: const Icon(Icons.headset_mic_rounded),
        label: const Text('Contact 24/7 Support'),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Support ticket created. An agent will contact you shortly.')),
          );
        },
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: AppColors.indigo,
        ),
      ),
    ],
  );

  Widget _faqItem(String question, String answer) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
        ),
      ],
    ),
  );
}

class _AboutAppTab extends StatelessWidget {
  const _AboutAppTab();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      Center(
        child: Icon(Icons.account_balance_wallet, size: 64, color: AppColors.indigo),
      ),
      SizedBox(height: 12),
      Center(
        child: Text('NovaPay Digital Wallet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      ),
      Center(
        child: Text('Version 1.0.0+1 (Assignment Edition)', style: TextStyle(color: AppColors.muted)),
      ),
      SizedBox(height: 24),
      Text(
        'About This Project\n\n'
        'NovaPay is an enterprise-grade digital wallet and banking simulation platform built with a high-integrity Python Django REST backend and a modern cross-platform Flutter client.\n\n'
        'Key Architectural Pillars:\n'
        '• Double-Entry Bookkeeping Ledger\n'
        '• Canonical Row-Level Locking (Deadlock-Free)\n'
        '• Cryptographic Idempotency Keys\n'
        '• Tiered KYC Compliance & Limits\n'
        '• 6-digit Transaction PIN Protection\n'
        '• JWT Token Authentication with Session Auditing',
        style: TextStyle(height: 1.5),
      ),
    ],
  );
}

class _TermsTab extends StatelessWidget {
  const _TermsTab();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      Text('Terms & Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      SizedBox(height: 12),
      Text(
        '1. Acceptance of Terms: By registering with NovaPay, you agree to comply with all electronic fund transfer policies and security guidelines.\n\n'
        '2. Account Eligibility: You must provide verifiable identity documents to qualify for Tier 1 and Tier 2 withdrawal limits.\n\n'
        '3. Transaction Limits: Standard consumer accounts have daily and monthly transaction limits governed by the dynamic fee engine.\n\n'
        '4. Idempotency: All payment mutation requests carry unique idempotency keys to safeguard against duplicate debits.\n\n'
        '5. Simulation Notice: This app is a production-grade banking demonstration prototype developed for academic and portfolio evaluation.',
        style: TextStyle(height: 1.5),
      ),
    ],
  );
}

class _PrivacyPolicyTab extends StatelessWidget {
  const _PrivacyPolicyTab();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      Text('Privacy & Data Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      SizedBox(height: 12),
      Text(
        '1. Information Collection: We store minimal required identification data (Full name, phone, email, and verification tier) strictly to authorize transactions.\n\n'
        '2. Sensitive Data Protection: Transaction PINs and passwords are cryptographic one-way hashes (PBKDF2/Argon2) and cannot be read by administrators.\n\n'
        '3. Data Masking: Account numbers and balances are masked on client displays to prevent shoulder surfing.\n\n'
        '4. Security Auditing: Login devices, IP addresses, and transaction timestamps are recorded in immutable audit logs.',
        style: TextStyle(height: 1.5),
      ),
    ],
  );
}
