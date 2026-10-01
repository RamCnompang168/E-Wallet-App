import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../wallet/data/wallet_api_service.dart';
import '../widgets/send_confirmation_bottom_sheet.dart';
import '../widgets/transaction_pin_pad_sheet.dart';

class SendAmountScreen extends StatefulWidget {
  const SendAmountScreen({
    super.key,
    required this.receiver,
    this.receiverWalletNumber = 'NP-9081-7263',
  });

  final String receiver;
  final String receiverWalletNumber;

  @override
  State<SendAmountScreen> createState() => _SendAmountScreenState();
}

class _SendAmountScreenState extends State<SendAmountScreen> {
  String amount = '0';

  @override
  Widget build(BuildContext context) {
    final available = WalletApiService.instance.wallet.effectiveAvailable > 0
        ? WalletApiService.instance.wallet.effectiveAvailable
        : 12450.80;
    final parsedAmount = double.tryParse(amount) ?? 0.0;
    final tooMuch = parsedAmount > available;

    return Scaffold(
      appBar: AppBar(title: const Text('Enter amount')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            ListTile(
              tileColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: CircleAvatar(
                backgroundColor: AppColors.indigo,
                child: Text(widget.receiver.isNotEmpty ? widget.receiver[0] : 'R'),
              ),
              title: Text(widget.receiver),
              subtitle: Text('NovaPay wallet · ${widget.receiverWalletNumber}'),
            ),
            const SizedBox(height: 32),
            Text(
              '\$$amount',
              style: TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w800,
                color: tooMuch ? Colors.red : AppColors.indigo,
              ),
            ),
            Text(
              tooMuch
                  ? 'Insufficient balance'
                  : 'Available: \$${available.toStringAsFixed(2)}',
              style: TextStyle(color: tooMuch ? Colors.red : AppColors.muted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ['+10', '+50', '+100', 'MAX']
                  .map(
                    (x) => ActionChip(
                      label: Text(x),
                      onPressed: () => setState(
                        () => amount = x == 'MAX'
                            ? available.toStringAsFixed(2)
                            : ((double.tryParse(amount) ?? 0) +
                                      double.parse(x.substring(1)))
                                  .toStringAsFixed(0),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const Spacer(),
            keypad(),
            FilledButton(
              onPressed: tooMuch || parsedAmount <= 0 ? null : confirm,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                backgroundColor: AppColors.indigo,
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget keypad() => GridView.count(
    shrinkWrap: true,
    crossAxisCount: 3,
    childAspectRatio: 1.8,
    children: [...'123456789'.split(''), '.', '0', '⌫']
        .map(
          (key) => TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                if (key == '⌫') {
                  amount = amount.length > 1
                      ? amount.substring(0, amount.length - 1)
                      : '0';
                } else if (key != '.' || !amount.contains('.')) {
                  amount = amount == '0' ? key : '$amount$key';
                }
              });
            },
            child: Text(
              key,
              style: TextStyle(
                fontSize: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        )
        .toList(),
  );

  Future<void> confirm() async {
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => SendConfirmationBottomSheet(
        receiver: widget.receiver,
        receiverWalletNumber: widget.receiverWalletNumber,
        amount: amount,
      ),
    );

    if (note != null && mounted) {
      final parsedAmount = double.tryParse(amount) ?? 0.0;
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TransactionPinPadSheet(
          receiverWalletNumber: widget.receiverWalletNumber,
          amount: parsedAmount,
          note: note,
        ),
      );
    }
  }
}
