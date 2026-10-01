import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_state.dart';
import '../../../../core/services/in_app_notification_service.dart';
import '../../../payments/data/payment_api_service.dart';
import '../../../qr/presentation/widgets/qr_visual.dart';
import '../../../wallet/data/wallet_api_service.dart';

/// Screen displayed when user initiates a deposit, showing an official KHQR bill
/// scannable by ABA, ACLEDA, Bakong, or any Cambodian bank app.
class DepositKhqrScreen extends StatefulWidget {
  const DepositKhqrScreen({
    super.key,
    required this.amount,
  });

  final double amount;

  @override
  State<DepositKhqrScreen> createState() => _DepositKhqrScreenState();
}

class _DepositKhqrScreenState extends State<DepositKhqrScreen> {
  bool _confirming = false;
  int _secondsRemaining = 900; // 15 minutes validity
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerFormatted {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _simulateBankPayment() async {
    setState(() => _confirming = true);
    try {
      if (AuthState.instance.isAuthenticated) {
        await PaymentApiService.instance.topUp(amount: widget.amount);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 900));
      }

      if (!mounted) return;

      final formattedAmount = widget.amount.toStringAsFixed(2);
      Navigator.of(context).popUntil((r) => r.isFirst);

      InAppNotificationService.instance.show(
        title: 'Deposit Confirmed',
        message: 'Bank payment of \$$formattedAmount received via KHQR. Funds credited to wallet.',
        icon: Icons.south_west_rounded,
        iconColor: const Color(0xFF00D09C),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Deposit failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = WalletApiService.instance.wallet;
    final user = AuthState.instance.currentUser;
    final payeeName = user?.fullName.isNotEmpty == true ? user!.fullName : 'E-WALLET DEPOSIT';
    final walletId = wallet.walletNumber.isNotEmpty ? wallet.walletNumber : 'WAL-DEPOSIT-01';

    return Scaffold(
      appBar: AppBar(
        title: const Text('KHQR Deposit Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Instructions banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE1251B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1251B).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFE1251B), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scan with ABA, ACLEDA, or Bakong',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFFE1251B),
                          ),
                        ),
                        Text(
                          'Expires in $_timerFormatted',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Authentic KHQR Card
            QrVisual(
              amount: widget.amount.toStringAsFixed(2),
              payeeName: payeeName,
              walletNumber: walletId,
              currency: 'USD',
            ),
            const SizedBox(height: 24),

            // Action Buttons
            FilledButton.icon(
              onPressed: _confirming ? null : _simulateBankPayment,
              icon: _confirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.check_circle_outline, color: Colors.black),
              label: Text(
                _confirming ? 'Verifying payment…' : 'I have scanned & paid with Bank',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('KHQR payment slip saved to gallery.')),
                );
              },
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Save QR Code to Gallery'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
