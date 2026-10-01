import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_state.dart';
import '../../../../core/services/in_app_notification_service.dart';
import '../../../payments/data/payment_api_service.dart';
import '../../../wallet/data/wallet_api_service.dart';
import 'deposit_khqr_screen.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({
    super.key,
    required this.title,
    required this.button,
    required this.positive,
  });

  final String title;
  final String button;
  final bool positive;

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final _amountController = TextEditingController();
  final _destinationController =
      TextEditingController(text: '001 234 567 (ABA Bank)');
  final _pinController = TextEditingController();
  bool _obscurePin = true;
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _destinationController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final available = WalletApiService.instance.wallet.effectiveAvailable > 0
        ? WalletApiService.instance.wallet.effectiveAvailable
        : (AuthState.instance.isAuthenticated ? 0.0 : 12450.80);

    final chips = widget.positive
        ? ['\$50', '\$100', '\$500']
        : ['\$20', '\$50', '\$100', 'MAX'];

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.positive
                  ? 'Instantly add funds to your wallet'
                  : 'Available balance: \$${available.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                labelText: 'Amount',
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: chips.map((option) {
                return ActionChip(
                  label: Text(option),
                  onPressed: () {
                    if (option == 'MAX') {
                      // Max available minus estimated fee $1.50
                      final maxVal = available > 1.50 ? available - 1.50 : available;
                      _amountController.text =
                          maxVal > 0 ? maxVal.toStringAsFixed(2) : '0.00';
                    } else {
                      _amountController.text = option.substring(1);
                    }
                    setState(() {});
                  },
                );
              }).toList(),
            ),
            if (!widget.positive) ...[
              const SizedBox(height: 22),
              TextField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'Destination Bank / Account',
                  hintText: 'e.g. 001 234 567 (ABA Bank)',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Transaction PIN',
                  hintText: 'Enter 6-digit PIN',
                  prefixIcon: const Icon(Icons.lock_outline),
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePin
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Standard fixed withdrawal fee of \$1.50 applies.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _canSubmit() ? _submit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor:
                    widget.positive ? AppColors.yellow : AppColors.primary,
                foregroundColor: widget.positive ? Colors.black : Colors.white,
              ),
              child: _submitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.positive ? Colors.black : Colors.white,
                      ),
                    )
                  : Text(widget.button),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    if (_submitting) return false;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return false;
    if (!widget.positive) {
      if (_pinController.text.trim().length != 6) return false;
    }
    return true;
  }

  Future<void> _submit() async {
    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    if (!widget.positive && _pinController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please enter your 6-digit transaction PIN.'),
        ),
      );
      return;
    }

    if (widget.positive) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DepositKhqrScreen(amount: parsed),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      if (AuthState.instance.isAuthenticated) {
        final dest = _destinationController.text.trim().isNotEmpty
            ? _destinationController.text.trim()
            : '001 234 567 (ABA Bank)';
        await PaymentApiService.instance.withdraw(
          amount: parsed,
          destinationAccount: dest,
          pin: _pinController.text.trim(),
        );
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }

      if (!mounted) return;
      setState(() => _submitting = false);

      final formattedAmount = parsed.toStringAsFixed(2);
      Navigator.pop(context);

      if (widget.positive) {
        InAppNotificationService.instance.show(
          title: 'Deposit Confirmed',
          message: 'Deposit of \$$formattedAmount completed and added to wallet balance.',
          icon: Icons.south_west_rounded,
          iconColor: const Color(0xFF00D09C),
        );
      } else {
        InAppNotificationService.instance.show(
          title: 'Withdrawal Successful',
          message: 'Withdrawal of \$$formattedAmount processed to destination account.',
          icon: Icons.north_east_rounded,
          iconColor: Colors.deepOrangeAccent,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Operation failed: ${e.toString()}'),
        ),
      );
    }
  }
}
