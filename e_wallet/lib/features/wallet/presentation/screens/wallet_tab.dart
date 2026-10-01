import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_state.dart';
import '../../../../core/widgets/action_row.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../transaction/data/transaction_api_service.dart';
import '../../../transaction/domain/models/transaction.dart';
import '../../data/wallet_api_service.dart';
import '../widgets/gradient_wallet_card.dart';

class WalletTab extends StatefulWidget {
  const WalletTab({
    super.key,
    required this.balanceHidden,
    required this.onVisibilityTap,
    required this.onCopyTap,
    required this.onDeposit,
    required this.onWithdraw,
  });

  final bool balanceHidden;
  final VoidCallback onVisibilityTap;
  final VoidCallback onCopyTap;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  String _kpiPeriod = 'All Time';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await Future.wait([
      WalletApiService.instance.fetchPrimaryWallet(),
      TransactionApiService.instance.fetchTransactions(),
    ]);
    if (mounted) setState(() {});
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.accentGreen,
        content: Text('$label copied to clipboard', style: const TextStyle(color: Colors.black)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthState.instance.currentUser;
    final wallet = WalletApiService.instance.wallet;
    final transactions = TransactionApiService.instance.transactions;

    final displayName = user?.fullName ?? 'Jordan Davis';
    final formattedBalance = AuthState.instance.isAuthenticated
        ? '\$${wallet.balance.toStringAsFixed(2)}'
        : r'$18,908.00';
    final formattedWalletNumber = AuthState.instance.isAuthenticated
        ? wallet.walletNumber
        : '••••  ••••  5318';

    // Compute Wallet Summary Metrics
    double totalDeposit = 0.0;
    double totalWithdraw = 0.0;
    double totalSent = 0.0;
    double totalReceived = 0.0;

    for (final t in transactions) {
      if (t.category == TransactionCategory.deposit) {
        totalDeposit += t.amount.abs();
      } else if (t.category == TransactionCategory.withdraw) {
        totalWithdraw += t.amount.abs();
      } else if (t.category == TransactionCategory.sent) {
        totalSent += t.amount.abs();
      } else if (t.category == TransactionCategory.received) {
        totalReceived += t.amount.abs();
      }
    }

    // Compute KPI Analytics based on selected period
    final now = DateTime.now();
    final periodTransactions = transactions.where((t) {
      if (_kpiPeriod == 'All Time') return true;
      final d = t.timestamp;
      if (d == null) {
        try {
          final parsed = DateTime.tryParse(t.date);
          if (parsed == null) return true;
          if (_kpiPeriod == 'Daily') {
            return parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
          } else if (_kpiPeriod == 'Weekly') {
            return now.difference(parsed).inDays <= 7;
          } else if (_kpiPeriod == 'Monthly') {
            return (parsed.year == now.year && parsed.month == now.month) || now.difference(parsed).inDays <= 30;
          }
        } catch (_) {}
        return true;
      }
      if (_kpiPeriod == 'Daily') {
        return d.year == now.year && d.month == now.month && d.day == now.day;
      } else if (_kpiPeriod == 'Weekly') {
        return now.difference(d).inDays <= 7;
      } else if (_kpiPeriod == 'Monthly') {
        return (d.year == now.year && d.month == now.month) || now.difference(d).inDays <= 30;
      }
      return true;
    }).toList();

    final totalTxnCount = periodTransactions.length;
    int successCount = 0;
    double successAmount = 0.0;
    int failedCount = 0;
    double failedAmount = 0.0;
    double totalVolume = 0.0;

    double periodReceived = 0.0;
    int periodReceivedCount = 0;
    double periodDeposit = 0.0;
    int periodDepositCount = 0;
    double periodSent = 0.0;
    int periodSentCount = 0;
    double periodWithdraw = 0.0;
    int periodWithdrawCount = 0;

    for (final t in periodTransactions) {
      final statusUpper = t.status.toUpperCase();
      final absAmt = t.amount.abs();
      totalVolume += absAmt;

      if (statusUpper == 'COMPLETED' || statusUpper == 'SUCCESS') {
        successCount++;
        successAmount += absAmt;
      } else if (statusUpper == 'FAILED' || statusUpper == 'CANCELLED') {
        failedCount++;
        failedAmount += absAmt;
      } else {
        successCount++;
        successAmount += absAmt;
      }

      if (t.category == TransactionCategory.received) {
        periodReceived += absAmt;
        periodReceivedCount++;
      } else if (t.category == TransactionCategory.deposit) {
        periodDeposit += absAmt;
        periodDepositCount++;
      } else if (t.category == TransactionCategory.sent) {
        periodSent += absAmt;
        periodSentCount++;
      } else if (t.category == TransactionCategory.withdraw) {
        periodWithdraw += absAmt;
        periodWithdrawCount++;
      }
    }

    final avgAmount = totalTxnCount > 0 ? (totalVolume / totalTxnCount) : 0.0;
    final successRate = totalTxnCount > 0 ? ((successCount / totalTxnCount) * 100).toInt() : 100;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
        children: [
          const Text(
            'My wallet',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            AuthState.instance.isAuthenticated
                ? 'Account: ${wallet.walletNumber} · Currency: ${wallet.currency}'
                : 'A clear view of your money, balances, and analytics.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Main Wallet Card
          GradientWalletCard(
            balance: formattedBalance,
            cardHolder: displayName,
            walletNumber: formattedWalletNumber,
            hidden: widget.balanceHidden,
            onVisibilityTap: widget.onVisibilityTap,
            onCopyTap: widget.onCopyTap,
          ),

          const SizedBox(height: 20),

          // Wallet Account Details & Balances Card
          FintechCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'WALLET ACCOUNT DETAILS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        wallet.status,
                        style: const TextStyle(
                          color: AppColors.accentGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (wallet.id.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Wallet ID', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      Row(
                        children: [
                          Text(
                            wallet.id.length > 18
                                ? '${wallet.id.substring(0, 10)}...${wallet.id.substring(wallet.id.length - 6)}'
                                : wallet.id,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            onPressed: () => _copyToClipboard(wallet.id, 'Wallet ID'),
                            padding: const EdgeInsets.only(left: 4),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Wallet Number', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    Row(
                      children: [
                        Text(
                          wallet.walletNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          onPressed: () => _copyToClipboard(wallet.walletNumber, 'Wallet Number'),
                          padding: const EdgeInsets.only(left: 4),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Balance', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    Text(
                      '\$${wallet.balance.toStringAsFixed(2)} ${wallet.currency}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Available Balance', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    Text(
                      '\$${wallet.effectiveAvailable.toStringAsFixed(2)} ${wallet.currency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.accentGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Wallet Volume Summary (Total Sent, Received, Deposit, Withdraw)
          const Text(
            'WALLET SUMMARY',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildSummaryMetricCard(
                  title: 'Total Sent',
                  amount: '\$${totalSent.toStringAsFixed(2)}',
                  icon: Icons.arrow_upward_rounded,
                  iconColor: Colors.orange,
                  bgColor: Colors.orange.withValues(alpha: .1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryMetricCard(
                  title: 'Total Received',
                  amount: '\$${totalReceived.toStringAsFixed(2)}',
                  icon: Icons.arrow_downward_rounded,
                  iconColor: AppColors.accentGreen,
                  bgColor: AppColors.accentGreen.withValues(alpha: .1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetricCard(
                  title: 'Total Deposit',
                  amount: '\$${totalDeposit.toStringAsFixed(2)}',
                  icon: Icons.add_card_rounded,
                  iconColor: AppColors.indigo,
                  bgColor: AppColors.indigo.withValues(alpha: .12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryMetricCard(
                  title: 'Total Withdraw',
                  amount: '\$${totalWithdraw.toStringAsFixed(2)}',
                  icon: Icons.account_balance_outlined,
                  iconColor: Colors.redAccent,
                  bgColor: Colors.redAccent.withValues(alpha: .1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // Financial Report & KPI Analytics Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'REPORT & KPI ANALYTICS',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${transactions.length} Total Txns',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Period Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All Time', 'Monthly', 'Weekly', 'Daily'].map((period) {
                final isSelected = _kpiPeriod == period;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(period),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _kpiPeriod = period),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          FintechCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_kpiPeriod Performance',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalTxnCount transactions evaluated',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$successRate% Success',
                        style: const TextStyle(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Received and Deposited breakdown
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiItem(
                        label: 'Received',
                        value: '+\$${periodReceived.toStringAsFixed(2)}',
                        subValue: '$periodReceivedCount received',
                        icon: Icons.arrow_downward_rounded,
                        color: AppColors.accentGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildKpiItem(
                        label: 'Deposited',
                        value: '+\$${periodDeposit.toStringAsFixed(2)}',
                        subValue: '$periodDepositCount top-ups',
                        icon: Icons.add_card_rounded,
                        color: AppColors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Sent and Withdrawn breakdown
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiItem(
                        label: 'Sent',
                        value: '-\$${periodSent.toStringAsFixed(2)}',
                        subValue: '$periodSentCount transfers',
                        icon: Icons.arrow_upward_rounded,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildKpiItem(
                        label: 'Withdrawn',
                        value: '-\$${periodWithdraw.toStringAsFixed(2)}',
                        subValue: '$periodWithdrawCount payouts',
                        icon: Icons.account_balance_outlined,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Successful and Failed breakdown
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiItem(
                        label: 'Successful',
                        value: '\$${successAmount.toStringAsFixed(2)}',
                        subValue: '$successCount successful txns',
                        icon: Icons.check_circle_outline,
                        color: AppColors.accentGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildKpiItem(
                        label: 'Failed / Cancelled',
                        value: '\$${failedAmount.toStringAsFixed(2)}',
                        subValue: '$failedCount failed txns',
                        icon: Icons.highlight_off_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Volume & Average
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiItem(
                        label: 'Total Volume',
                        value: '\$${totalVolume.toStringAsFixed(2)}',
                        subValue: 'Sum of all volume',
                        icon: Icons.receipt_long_outlined,
                        color: AppColors.yellow,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildKpiItem(
                        label: 'Average Size',
                        value: '\$${avgAmount.toStringAsFixed(2)}',
                        subValue: 'Per transaction',
                        icon: Icons.auto_graph_rounded,
                        color: AppColors.indigo,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // Manage Wallet Action Row
          const Text(
            'WALLET ACTIONS',
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
                  icon: Icons.add_card_rounded,
                  label: 'Add money (Deposit)',
                  subtitle: 'Top up your available balance',
                  onTap: widget.onDeposit,
                ),
                const Divider(height: 1, indent: 67),
                MenuActionRow(
                  icon: Icons.account_balance_outlined,
                  label: 'Withdraw money',
                  subtitle: 'Transfer funds to linked bank account',
                  onTap: widget.onWithdraw,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetricCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return FintechCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem({
    required String label,
    required String value,
    String? subValue,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              if (subValue != null)
                Text(
                  subValue,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
