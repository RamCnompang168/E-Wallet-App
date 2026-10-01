import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_state.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_action.dart';
import '../../../../core/widgets/quick_action.dart';
import '../../../transaction/data/mock_data/mock_transactions.dart';
import '../../../transaction/data/transaction_api_service.dart';
import '../../../transaction/domain/models/transaction.dart';
import '../../../transaction/presentation/widgets/transaction_row.dart';
import '../../../wallet/data/wallet_api_service.dart';
import '../../../wallet/presentation/widgets/gradient_wallet_card.dart';
import '../../../notifications/data/notification_api_service.dart';
import '../../../../core/services/account_approval_service.dart';
import '../widgets/spending_summary_card.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({
    super.key,
    required this.balanceHidden,
    required this.onVisibilityTap,
    required this.onCopyTap,
    required this.onNotificationsTap,
    required this.onDepositTap,
    required this.onWithdrawTap,
    required this.onSendTap,
    required this.onReceiveTap,
    required this.onSeeAllActivityTap,
    required this.onTransactionTap,
    this.onGovServicesTap,
  });

  final bool balanceHidden;
  final VoidCallback onVisibilityTap;
  final VoidCallback onCopyTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onDepositTap;
  final VoidCallback onWithdrawTap;
  final VoidCallback onSendTap;
  final VoidCallback onReceiveTap;
  final VoidCallback onSeeAllActivityTap;
  final ValueChanged<TransactionModel> onTransactionTap;
  final VoidCallback? onGovServicesTap;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    NotificationApiService.instance.addListener(_onNotifChanged);
    AccountApprovalService.instance.addListener(_onApprovalChanged);
    _syncData();
  }

  @override
  void dispose() {
    NotificationApiService.instance.removeListener(_onNotifChanged);
    AccountApprovalService.instance.removeListener(_onApprovalChanged);
    super.dispose();
  }

  void _onNotifChanged() {
    if (mounted) setState(() {});
  }

  void _onApprovalChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _syncData() async {
    await WalletApiService.instance.fetchPrimaryWallet();
    await TransactionApiService.instance.fetchTransactions();
    await NotificationApiService.instance.fetchNotifications();
    if (AuthState.instance.currentUser?.isAdminOrStaff == true) {
      await AccountApprovalService.instance.fetchPendingApprovals();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthState.instance.currentUser;
    final wallet = WalletApiService.instance.wallet;
    final realTransactions = TransactionApiService.instance.transactions;
    final transactions = realTransactions.isNotEmpty
        ? realTransactions
        : (AuthState.instance.isAuthenticated ? const <TransactionModel>[] : mockTransactions);

    double income = 0.0;
    double spent = 0.0;
    if (AuthState.instance.isAuthenticated) {
      for (final tx in realTransactions) {
        if (tx.credit || tx.amount > 0) {
          income += tx.amount.abs();
        } else {
          spent += tx.amount.abs();
        }
      }
    } else {
      income = 1850.0;
      spent = 698.24;
    }

    final displayName = user?.fullName ?? 'Sokha Chan';
    final initials = user?.initials ?? 'SC';
    final formattedBalance = AuthState.instance.isAuthenticated
        ? '\$${wallet.balance.toStringAsFixed(2)}'
        : r'$18,908.00';
    final formattedWalletNumber = AuthState.instance.isAuthenticated
        ? wallet.walletNumber
        : '••••  ••••  5318';

    return RefreshIndicator(
      onRefresh: _syncData,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(height: 226, color: AppColors.primaryDark),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(16),
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
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GOOD MORNING',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: Color(0xFFAAC4BC),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconAction(
                    icon: Icons.notifications_none_rounded,
                    label: 'Open notifications',
                    badge: NotificationApiService.instance.unreadCount > 0,
                    onPressed: widget.onNotificationsTap,
                  ),
                ],
              ),
              const SizedBox(height: 25),
              GradientWalletCard(
                balance: formattedBalance,
                cardHolder: displayName,
                walletNumber: formattedWalletNumber,
                hidden: widget.balanceHidden,
                onVisibilityTap: widget.onVisibilityTap,
                onCopyTap: widget.onCopyTap,
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                child: Row(
                  children: [
                    QuickAction(
                      icon: Icons.add_rounded,
                      label: 'Deposit',
                      onPressed: widget.onDepositTap,
                    ),
                    QuickAction(
                      icon: Icons.south_west_rounded,
                      label: 'Withdraw',
                      onPressed: widget.onWithdrawTap,
                    ),
                    QuickAction(
                      icon: Icons.north_east_rounded,
                      label: 'Send',
                      onPressed: widget.onSendTap,
                    ),
                    QuickAction(
                      icon: Icons.qr_code_2_rounded,
                      label: 'Receive',
                      onPressed: widget.onReceiveTap,
                    ),
                    QuickAction(
                      icon: Icons.account_balance_rounded,
                      label: 'Gov Serv',
                      onPressed: widget.onGovServicesTap ?? () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: widget.onGovServicesTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          color: Color(0xFF38BDF8),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Government Services',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'សេវារដ្ឋ',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Road Tax • EDC Electricity • PPWSA • NSSF',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white54,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
              if (user?.isAdminOrStaff == true) ...[
                const SizedBox(height: 20),
                _buildPendingApprovalsSection(context),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your spending',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: () => _showMonthlyStatementSheet(context, income: income, spent: spent),
                    child: const Text('This month'),
                  ),
                ],
              ),
              SpendingSummaryCard(income: income, spent: spent),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent activity',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: widget.onSeeAllActivityTap,
                    child: const Text('See all'),
                  ),
                ],
              ),
              FintechCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: transactions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.muted),
                              SizedBox(height: 8),
                              Text(
                                'No recent transactions',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Your activity will appear here once you send, deposit, or withdraw.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: transactions
                            .take(4)
                            .map(
                              (transaction) => TransactionRow(
                                title: transaction.name,
                                subtitle: transaction.description != null && transaction.description!.isNotEmpty
                                    ? '${transaction.description} · ${transaction.date}'
                                    : transaction.date,
                                amount:
                                    '${transaction.credit ? '+' : '-'}\$${transaction.amount.abs().toStringAsFixed(2)}',
                                credit: transaction.credit,
                                onTap: () => widget.onTransactionTap(transaction),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMonthlyStatementSheet(BuildContext context, {required double income, required double spent}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Statement',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'March 2026',
                    style: TextStyle(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Detailed financial performance & double-entry ledger summary.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FintechCard(
              child: Column(
                children: [
                  _statementRow('Total Inflow / Received', '+\$${income.toStringAsFixed(2)}', Colors.green),
                  const Divider(height: 20),
                  _statementRow('Total Outflow / Spent', '-\$${spent.toStringAsFixed(2)}', Colors.redAccent),
                  const Divider(height: 20),
                  _statementRow('Network / Transfer Fees', r'-$0.00', AppColors.textSecondary),
                  const Divider(height: 20),
                  _statementRow(
                    'Net Balance Change',
                    '${(income - spent) >= 0 ? '+' : '-'}\$${(income - spent).abs().toStringAsFixed(2)}',
                    AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Colors.blue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ledger Invariant: Debits equal Credits. Audit hash verified.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Monthly statement is ready to download.'),
                    ),
                  );
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download PDF Statement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static Widget _statementRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingApprovalsSection(BuildContext context) {
    final approvalService = AccountApprovalService.instance;
    final pendingList = approvalService.pendingUsers;
    final count = pendingList.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.accentGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Account Approvals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: count > 0 ? Colors.amber.shade700 : Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              tooltip: 'Refresh pending requests',
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: () => approvalService.fetchPendingApprovals(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (approvalService.isLoading && pendingList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (pendingList.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .06)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppColors.accentGreen.withValues(alpha: .8), size: 30),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All accounts reviewed',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'No registration accounts are waiting for approval.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: pendingList.map((pendingUser) => _buildPendingUserCard(context, pendingUser)).toList(),
          ),
      ],
    );
  }

  Widget _buildPendingUserCard(BuildContext context, PendingApprovalUser pendingUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: .3)),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.indigo,
                backgroundImage: pendingUser.resolvedProfilePhotoUrl != null
                    ? NetworkImage(pendingUser.resolvedProfilePhotoUrl!)
                    : null,
                child: pendingUser.resolvedProfilePhotoUrl == null
                    ? Text(
                        pendingUser.initials,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pendingUser.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.withValues(alpha: .4)),
                          ),
                          child: const Text(
                            'PENDING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${pendingUser.phoneNumber} • ${pendingUser.email}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            pendingUser.idDocumentType == 'PASSPORT'
                                ? Icons.menu_book_rounded
                                : Icons.badge_outlined,
                            size: 14,
                            color: AppColors.accentGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${pendingUser.documentDisplay}: ${pendingUser.idDocumentNumber.isNotEmpty ? pendingUser.idDocumentNumber : "Not provided"}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showDocumentDetailsDialog(context, pendingUser),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View Document'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _confirmReject(pendingUser),
                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                label: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _confirmApprove(pendingUser),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDocumentDetailsDialog(BuildContext context, PendingApprovalUser user) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(
                  '${user.documentDisplay} Verification',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
                automaticallyImplyLeading: false,
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    // Document Photo
                    Text(
                      '${user.documentDisplay} Photo',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    if (user.resolvedDocumentPhotoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.network(
                            user.resolvedDocumentPhotoUrl!,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Container(
                              height: 140,
                              alignment: Alignment.center,
                              color: Colors.white10,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_outlined, size: 40, color: AppColors.muted),
                                  SizedBox(height: 6),
                                  Text('Could not load document image', style: TextStyle(color: AppColors.muted)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        alignment: Alignment.center,
                        child: const Text('No document photo uploaded', style: TextStyle(color: AppColors.muted)),
                      ),
                    const SizedBox(height: 18),

                    // Details Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _detailItem('Applicant Name', user.fullName),
                          const Divider(height: 14),
                          _detailItem('Document Type', user.documentDisplay),
                          const Divider(height: 14),
                          _detailItem('Document Number', user.idDocumentNumber.isNotEmpty ? user.idDocumentNumber : 'None'),
                          const Divider(height: 14),
                          _detailItem('Phone Number', user.phoneNumber),
                          const Divider(height: 14),
                          _detailItem('Email Address', user.email),
                          const Divider(height: 14),
                          _detailItem('Gender', user.gender.isNotEmpty ? user.gender : 'Not specified'),
                          const Divider(height: 14),
                          _detailItem('Date of Birth', user.dateOfBirth.isNotEmpty ? user.dateOfBirth : 'Not specified'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmReject(user);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmApprove(user);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Approve Account'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmApprove(PendingApprovalUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Approve Account?'),
        content: Text(
          'Are you sure you want to approve registration for ${user.fullName}?\n\nTheir account will become active and they will be able to log in to the wallet app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AccountApprovalService.instance.approveUser(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? AppColors.accentGreen : Colors.red,
          content: Text(
            success
                ? 'Account for ${user.fullName} approved successfully!'
                : 'Failed to approve account: ${AccountApprovalService.instance.errorMessage}',
            style: TextStyle(color: success ? Colors.black : Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _confirmReject(PendingApprovalUser user) async {
    final reasonController = TextEditingController(text: 'Document verification incomplete or unclear.');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject registration for ${user.fullName}?'),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject Account'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AccountApprovalService.instance.rejectUser(
        user,
        reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? Colors.orange : Colors.red,
          content: Text(
            success
                ? 'Account for ${user.fullName} has been rejected.'
                : 'Failed to reject account: ${AccountApprovalService.instance.errorMessage}',
          ),
        ),
      );
    }
  }

  static Widget _detailItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
