import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/action_row.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/transaction.dart';
import 'transaction_receipt_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transaction});
  final TransactionModel transaction;

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.accentGreen,
        content: Text('$label copied to clipboard', style: const TextStyle(color: Colors.black)),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status.toUpperCase()) {
      'COMPLETED' || 'SUCCESS' => AppColors.accentGreen,
      'PENDING' => Colors.orange,
      'FAILED' || 'CANCELLED' => Colors.redAccent,
      'REVERSED' => Colors.purpleAccent,
      _ => AppColors.muted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(transaction.status);
    final ref = transaction.transactionCode ?? transaction.id;
    final fee = transaction.category == TransactionCategory.withdraw ? '\$1.50' : '\$0.00';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'View Receipt',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionReceiptScreen(transaction: transaction),
              ),
            ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withValues(alpha: .3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        transaction.status.toUpperCase() == 'COMPLETED'
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        transaction.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '${transaction.credit ? '+' : '-'}\$${transaction.amount.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: transaction.credit ? AppColors.emerald : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  transaction.name,
                  style: const TextStyle(fontSize: 15, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          FintechCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                MenuActionRow(
                  icon: Icons.tag_rounded,
                  label: 'Reference Code',
                  subtitle: ref,
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    onPressed: () => _copy(context, ref, 'Reference Code'),
                  ),
                ),
                const Divider(height: 1, indent: 67),
                MenuActionRow(
                  icon: Icons.person_outline_rounded,
                  label: transaction.credit ? 'Sender' : 'Recipient',
                  subtitle: transaction.name,
                ),
                if (transaction.description != null && transaction.description!.isNotEmpty) ...[
                  const Divider(height: 1, indent: 67),
                  MenuActionRow(
                    icon: Icons.notes_rounded,
                    label: 'Remark / Note',
                    subtitle: transaction.description!,
                  ),
                ],
                if (transaction.senderWalletNumber != null) ...[
                  const Divider(height: 1, indent: 67),
                  MenuActionRow(
                    icon: Icons.wallet_outlined,
                    label: 'Sender Account',
                    subtitle: transaction.senderWalletNumber!,
                  ),
                ],
                if (transaction.receiverWalletNumber != null) ...[
                  const Divider(height: 1, indent: 67),
                  MenuActionRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Recipient Account',
                    subtitle: transaction.receiverWalletNumber!,
                  ),
                ],
                const Divider(height: 1, indent: 67),
                MenuActionRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date & Time',
                  subtitle: transaction.date,
                ),
                const Divider(height: 1, indent: 67),
                MenuActionRow(
                  icon: Icons.monetization_on_outlined,
                  label: 'Currency',
                  subtitle: transaction.currency,
                ),
                const Divider(height: 1, indent: 67),
                MenuActionRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Network Fee',
                  subtitle: fee,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionReceiptScreen(transaction: transaction),
              ),
            ),
            icon: const Icon(Icons.receipt_rounded),
            label: const Text('View Official Receipt'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.indigo,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'NovaPay Transaction $ref: \$${transaction.amount.abs().toStringAsFixed(2)} ${transaction.currency} (${transaction.status})'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction details copied to clipboard.')),
              );
            },
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share details'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }
}
