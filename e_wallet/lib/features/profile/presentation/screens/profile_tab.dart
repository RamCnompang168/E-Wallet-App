import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_state.dart';
import '../../../../core/widgets/action_row.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../beneficiaries/presentation/screens/beneficiaries_screen.dart';
import '../../../wallet/data/wallet_api_service.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.biometricsEnabled,
    required this.onBiometricsChanged,
    required this.onThemeChanged,
    required this.onAccountDetails,
    required this.onSecurity,
    required this.onSupport,
    required this.onLogOut,
  });

  final bool biometricsEnabled;
  final ValueChanged<bool> onBiometricsChanged;
  final VoidCallback onThemeChanged;
  final VoidCallback onAccountDetails;
  final VoidCallback onSecurity;
  final VoidCallback onSupport;
  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    final user = AuthState.instance.currentUser;
    final wallet = WalletApiService.instance.wallet;

    final displayName = user?.fullName ?? 'Jordan Davis';
    final initials = user?.initials ?? 'JD';
    final walletNumber = AuthState.instance.isAuthenticated
        ? wallet.walletNumber
        : 'NP-7390-5318';
    final kycTier = user?.kycTier ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      children: [
        const Text(
          'Profile',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 78,
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentGreen,
              borderRadius: BorderRadius.circular(26),
              image: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(user.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                ? null
                : Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            displayName,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 3),
        Center(
          child: Text(
            walletNumber,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (AuthState.instance.isAuthenticated) ...[
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.indigo.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'KYC Tier $kycTier Verified · ${user?.role ?? "CUSTOMER"}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.indigo,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 28),
        const Text(
          'SETTINGS',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        FintechCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MenuActionRow(
                icon: Icons.manage_accounts_outlined,
                label: 'Account details',
                subtitle: user?.email,
                onTap: onAccountDetails,
              ),
              const Divider(height: 1, indent: 67),
              MenuActionRow(
                icon: Icons.people_outline_rounded,
                label: 'Saved beneficiaries',
                subtitle: 'Manage transfer contacts',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BeneficiariesScreen()),
                ),
              ),
              const Divider(height: 1, indent: 67),
              MenuActionRow(
                icon: Icons.lock_outline_rounded,
                label: 'Security settings',
                onTap: onSecurity,
              ),
              const Divider(height: 1, indent: 67),
              MenuActionRow(
                icon: Icons.fingerprint_rounded,
                label: 'Biometric login',
                trailing: Switch(
                  value: biometricsEnabled,
                  onChanged: onBiometricsChanged,
                ),
              ),
              const Divider(height: 1, indent: 67),
              MenuActionRow(
                icon: Icons.dark_mode_outlined,
                label: 'Appearance',
                subtitle: 'Toggle light or dark mode',
                onTap: onThemeChanged,
              ),
              const Divider(height: 1, indent: 67),
              MenuActionRow(
                icon: Icons.help_outline_rounded,
                label: 'Help & support',
                onTap: onSupport,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FintechCard(
          padding: EdgeInsets.zero,
          child: MenuActionRow(
            icon: Icons.logout_rounded,
            label: 'Log out',
            destructive: true,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log out'),
                  content: const Text('Are you sure you want to log out of your account?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await AuthState.instance.logout();
                onLogOut();
              }
            },
          ),
        ),
      ],
    );
  }
}
