import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/in_app_notification_service.dart';
import '../../data/transaction_api_service.dart';
import '../screens/transaction_receipt_screen.dart';

/// Bottom sheet keypad for entering 6-digit transaction PIN.
class TransactionPinPadSheet extends StatefulWidget {
  const TransactionPinPadSheet({
    super.key,
    this.scrambled = false,
    this.receiverWalletNumber,
    this.amount,
    this.note,
    this.onCompleted,
  });

  final bool scrambled;
  final String? receiverWalletNumber;
  final double? amount;
  final String? note;
  final ValueChanged<String>? onCompleted;

  @override
  State<TransactionPinPadSheet> createState() => _TransactionPinPadSheetState();
}

class _TransactionPinPadSheetState extends State<TransactionPinPadSheet> {
  String pin = '';
  bool _submitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    // 1-9 in grid, 0 in center of bottom row
    final topDigits = widget.scrambled
        ? ['4', '1', '8', '2', '9', '5', '7', '3', '6']
        : ['1', '2', '3', '4', '5', '6', '7', '8', '9'];

    final keypadItems = [...topDigits, '', '0', '⌫'];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            top: 14,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Enter transaction PIN',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Authorized transaction confirmation',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_submitting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.indigo),
                      SizedBox(height: 14),
                      Text(
                        'Processing secure transfer…',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    6,
                    (i) => Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < pin.length
                            ? AppColors.indigo
                            : Colors.transparent,
                        border: Border.all(
                          color: i < pin.length
                              ? AppColors.indigo
                              : AppColors.muted.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 2.1,
                  children: keypadItems.map((key) {
                    if (key.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return TextButton(
                      onPressed: () => tap(key),
                      style: TextButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      child: key == '⌫'
                          ? Icon(
                              Icons.backspace_outlined,
                              size: 22,
                              color: Theme.of(context).colorScheme.onSurface,
                            )
                          : Text(
                              key,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> tap(String key) async {
    HapticFeedback.lightImpact();
    final newPin = key == '⌫'
        ? (pin.isEmpty ? '' : pin.substring(0, pin.length - 1))
        : '$pin$key';

    setState(() {
      pin = newPin;
      _errorMessage = null;
    });

    if (newPin.length == 6) {
      if (widget.onCompleted != null) {
        Navigator.of(context).pop();
        widget.onCompleted!(newPin);
        return;
      }

      if (widget.receiverWalletNumber != null && widget.amount != null) {
        setState(() => _submitting = true);
        try {
          final txn = await TransactionApiService.instance.sendTransfer(
            receiverWalletNumber: widget.receiverWalletNumber!,
            amount: widget.amount!,
            pin: newPin,
            description: widget.note,
          );

          if (!mounted) return;
          final nav = Navigator.of(context, rootNavigator: true);
          nav.popUntil((r) => r.isFirst);
          nav.push(
            MaterialPageRoute(
              builder: (_) => TransactionReceiptScreen(transaction: txn),
            ),
          );

          InAppNotificationService.instance.show(
            title: 'Transfer Sent Successfully',
            message: 'Transferred \$${widget.amount!.toStringAsFixed(2)} to ${widget.receiverWalletNumber}.',
            icon: Icons.swap_horiz_rounded,
            iconColor: const Color(0xFF6366F1),
          );
        } on ApiException catch (e) {
          if (!mounted) return;
          setState(() {
            _submitting = false;
            pin = '';
            _errorMessage = e.message;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _submitting = false;
            pin = '';
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          });
        }
      } else {
        Navigator.of(context).pop();
      }
    }
  }
}
