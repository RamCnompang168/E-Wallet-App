import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_tab.dart';
import '../../../notifications/presentation/screens/notification_list_screen.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';
import '../../../profile/presentation/screens/profile_tab.dart';
import '../../../profile/presentation/screens/security_settings_screen.dart';
import '../../../profile/presentation/screens/support_and_legal_screen.dart';
import '../../../qr/presentation/screens/qr_scanner_screen.dart';
import '../../../qr/presentation/screens/receive_qr_screen.dart';
import '../../../transaction/domain/models/transaction.dart';
import '../../../transaction/presentation/screens/deposit_simulation_screen.dart';
import '../../../transaction/presentation/screens/receiver_search_screen.dart';
import '../../../transaction/presentation/screens/transaction_detail_screen.dart';
import '../../../transaction/presentation/screens/transaction_history_screen.dart';
import '../../../transaction/presentation/screens/withdraw_simulation_screen.dart';
import '../../../government_services/presentation/screens/government_services_screen.dart';
import '../../../wallet/presentation/screens/wallet_tab.dart';
import '../widgets/floating_navigation_bar.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key, required this.onThemeChanged});
  final VoidCallback onThemeChanged;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _tab = 0;
  bool _balanceHidden = false;
  bool _biometricsEnabled = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: IndexedStack(
        index: _tab,
        children: [
          DashboardTab(
            balanceHidden: _balanceHidden,
            onVisibilityTap: () =>
                setState(() => _balanceHidden = !_balanceHidden),
            onCopyTap: _copyWalletId,
            onNotificationsTap: _notifications,
            onDepositTap: _deposit,
            onWithdrawTap: _withdraw,
            onSendTap: _send,
            onReceiveTap: _receive,
            onGovServicesTap: _govServices,
            onSeeAllActivityTap: () => setState(() => _tab = 3),
            onTransactionTap: _openTransaction,
          ),
          WalletTab(
            balanceHidden: _balanceHidden,
            onVisibilityTap: () =>
                setState(() => _balanceHidden = !_balanceHidden),
            onCopyTap: _copyWalletId,
            onDeposit: _deposit,
            onWithdraw: _withdraw,
          ),
          QrScannerScreen(onClose: () => setState(() => _tab = 0)),
          TransactionHistoryScreen(onTransactionTap: _openTransaction),
          ProfileTab(
            biometricsEnabled: _biometricsEnabled,
            onBiometricsChanged: (value) {
              setState(() => _biometricsEnabled = value);
              _showNotice(
                value
                    ? 'Biometric login enabled.'
                    : 'Biometric login disabled.',
              );
            },
            onThemeChanged: widget.onThemeChanged,
            onAccountDetails: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
            onSecurity: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SecuritySettingsScreen(
                  biometricsEnabled: _biometricsEnabled,
                  onBiometricsChanged: (value) => setState(() => _biometricsEnabled = value),
                ),
              ),
            ),
            onSupport: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportAndLegalScreen()),
            ),
            onLogOut: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => LoginScreen(onThemeChanged: widget.onThemeChanged),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    ),
    bottomNavigationBar: FloatingNavigationBar(
      selectedIndex: _tab,
      onTabSelected: (index) => setState(() => _tab = index),
    ),
  );

  void _openTransaction(TransactionModel transaction) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TransactionDetailScreen(transaction: transaction),
    ),
  );

  void _notifications() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const NotificationListScreen()),
  );

  void _send() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ReceiverSearchScreen()),
  );

  void _receive() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ReceiveQrScreen()),
  );

  void _deposit() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const DepositSimulationScreen()),
  );

  void _withdraw() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const WithdrawSimulationScreen()),
  );

  void _govServices() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const GovernmentServicesScreen()),
  );

  void _copyWalletId() {
    Clipboard.setData(const ClipboardData(text: 'NP-7390-5318'));
    _showNotice('Wallet ID copied to clipboard.');
  }

  void _showNotice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
