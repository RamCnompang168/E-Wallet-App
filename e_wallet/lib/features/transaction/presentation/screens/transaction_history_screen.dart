import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_state.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/mock_data/mock_transactions.dart';
import '../../data/transaction_api_service.dart';
import '../../domain/models/transaction.dart';
import '../widgets/transaction_row.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key, required this.onTransactionTap});
  final ValueChanged<TransactionModel> onTransactionTap;

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _typeFilter = 'All';
  String _statusFilter = 'All Status';
  String _searchQuery = '';
  String _sortBy = 'Latest';

  @override
  void initState() {
    super.initState();
    TransactionApiService.instance.fetchTransactions().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = AuthState.instance.isAuthenticated
        ? TransactionApiService.instance.transactions
        : (TransactionApiService.instance.transactions.isNotEmpty
            ? TransactionApiService.instance.transactions
            : mockTransactions);

    var filtered = list.where((t) {
      if (!_matchesTypeFilter(t)) return false;
      if (!_matchesStatusFilter(t)) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return t.name.toLowerCase().contains(query) ||
            (t.transactionCode?.toLowerCase().contains(query) ?? false) ||
            t.id.toLowerCase().contains(query) ||
            t.status.toLowerCase().contains(query) ||
            (t.senderWalletNumber?.toLowerCase().contains(query) ?? false) ||
            (t.receiverWalletNumber?.toLowerCase().contains(query) ?? false);
      }
      return true;
    }).toList();

    if (_sortBy == 'Oldest') {
      filtered = filtered.reversed.toList();
    } else if (_sortBy == 'Highest amount') {
      filtered.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    } else if (_sortBy == 'Lowest amount') {
      filtered.sort((a, b) => a.amount.abs().compareTo(b.amount.abs()));
    } else if (_sortBy == 'Status') {
      filtered.sort((a, b) => a.status.compareTo(b.status));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await TransactionApiService.instance.fetchTransactions(filter: _typeFilter);
        if (mounted) setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction History',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort_rounded),
                tooltip: 'Sort transactions',
                initialValue: _sortBy,
                onSelected: (val) => setState(() => _sortBy = val),
                itemBuilder: (ctx) => [
                  'Latest',
                  'Oldest',
                  'Highest amount',
                  'Lowest amount',
                  'Status',
                ].map((s) => PopupMenuItem(value: s, child: Text('Sort: $s'))).toList(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Field (by ID, Code, Name, Status)
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by ID, name, or status...',
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),

          // Transaction Type Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Sent', 'Received', 'Deposit', 'Withdraw']
                  .map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: category == _typeFilter,
                        onSelected: (_) {
                          setState(() => _typeFilter = category);
                          TransactionApiService.instance.fetchTransactions(filter: category);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All Status', 'Completed', 'Pending', 'Failed', 'Cancelled', 'Reversed']
                  .map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(status, style: const TextStyle(fontSize: 12)),
                        selected: status == _statusFilter,
                        onSelected: (_) => setState(() => _statusFilter = status),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRANSACTIONS (${filtered.length})',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_sortBy != 'Latest')
                Text(
                  'Sorted: $_sortBy',
                  style: const TextStyle(color: AppColors.indigo, fontSize: 11, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 8),

          FintechCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 44, color: AppColors.muted),
                          const SizedBox(height: 8),
                          const Text(
                            'No transactions found matching your criteria.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          if (_typeFilter != 'All' || _statusFilter != 'All Status' || _searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => setState(() {
                                _typeFilter = 'All';
                                _statusFilter = 'All Status';
                                _searchQuery = '';
                              }),
                              child: const Text('Reset filters'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: filtered
                        .map(
                          (t) => TransactionRow(
                            title: t.name,
                            subtitle: t.description != null && t.description!.isNotEmpty
                                ? '${t.description} · ${t.date}'
                                : '${t.date} · ${t.status}',
                            amount:
                                '${t.credit ? '+' : '-'}\$${t.amount.abs().toStringAsFixed(2)}',
                            credit: t.credit,
                            onTap: () => widget.onTransactionTap(t),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  bool _matchesTypeFilter(TransactionModel transaction) => switch (_typeFilter) {
    'Sent' => transaction.category == TransactionCategory.sent,
    'Received' => transaction.category == TransactionCategory.received,
    'Deposit' => transaction.category == TransactionCategory.deposit,
    'Withdraw' => transaction.category == TransactionCategory.withdraw,
    _ => true,
  };

  bool _matchesStatusFilter(TransactionModel transaction) {
    if (_statusFilter == 'All Status') return true;
    return transaction.status.toLowerCase() == _statusFilter.toLowerCase();
  }
}
