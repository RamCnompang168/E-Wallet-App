import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Modal bottom sheet confirming transaction recipient, amount, and fees.
class SendConfirmationBottomSheet extends StatefulWidget {
  const SendConfirmationBottomSheet({
    super.key,
    required this.receiver,
    required this.amount,
    this.receiverWalletNumber = 'NP-9081-7263',
  });

  final String receiver;
  final String amount;
  final String receiverWalletNumber;

  @override
  State<SendConfirmationBottomSheet> createState() =>
      _SendConfirmationBottomSheetState();
}

class _SendConfirmationBottomSheetState
    extends State<SendConfirmationBottomSheet> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      left: 24,
      right: 24,
      top: 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Review transfer',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        _item('Receiver', widget.receiver),
        _item('Wallet number', widget.receiverWalletNumber),
        _item('Amount', '\$${widget.amount}'),
        _item('Fee', '\$0.00'),
        TextField(
          controller: _noteController,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Add a note (optional)'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, _noteController.text.trim());
          },
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: AppColors.indigo,
          ),
          child: const Text('Confirm transfer'),
        ),
      ],
    ),
  );

  Widget _item(String left, String right) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Text(left, style: const TextStyle(color: AppColors.muted)),
        const Spacer(),
        Text(right, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
