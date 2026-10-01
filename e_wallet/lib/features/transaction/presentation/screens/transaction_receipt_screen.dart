import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/transaction.dart';

class TransactionReceiptScreen extends StatelessWidget {
  const TransactionReceiptScreen({super.key, required this.transaction});
  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final formattedAmount = '${transaction.credit ? '+' : '-'}\$${transaction.amount.abs().toStringAsFixed(2)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Receipt'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 44, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Payment Successful',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: transaction.credit ? AppColors.accentGreen : AppColors.indigo,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          FintechCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _row('Transaction Ref', transaction.transactionCode ?? transaction.id),
                const Divider(height: 24),
                _row('Status', transaction.status),
                const Divider(height: 24),
                _row(transaction.credit ? 'Sender' : 'Recipient', transaction.name),
                if (transaction.description != null && transaction.description!.isNotEmpty) ...[
                  const Divider(height: 24),
                  _row('Remark / Note', transaction.description!),
                ],
                const Divider(height: 24),
                _row('Sender Account', transaction.senderWalletNumber ?? 'My Wallet'),
                const Divider(height: 24),
                _row('Recipient Account', transaction.receiverWalletNumber ?? 'External'),
                const Divider(height: 24),
                _row('Date & Time', transaction.date),
                const Divider(height: 24),
                _row('Currency', transaction.currency),
              ],
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt image downloaded to device.')),
              );
            },
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share Receipt'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.indigo,
            ),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    ],
  );
}
