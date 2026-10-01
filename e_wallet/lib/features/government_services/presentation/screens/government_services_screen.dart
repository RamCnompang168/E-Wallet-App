import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_state.dart';
import '../../../../core/services/in_app_notification_service.dart';
import '../../../transaction/domain/models/transaction.dart';
import '../../../transaction/presentation/screens/transaction_receipt_screen.dart';
import '../../../wallet/data/wallet_api_service.dart';
import '../../data/government_service_api.dart';
import '../../domain/models/government_service.dart';

class GovernmentServicesScreen extends StatefulWidget {
  const GovernmentServicesScreen({super.key});

  @override
  State<GovernmentServicesScreen> createState() => _GovernmentServicesScreenState();
}

class _GovernmentServicesScreenState extends State<GovernmentServicesScreen> {
  final _searchController = TextEditingController();
  GovServiceCategory _selectedCategory = GovServiceCategory.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GovernmentServiceItem> get _filteredServices {
    return kGovernmentServices.where((s) {
      final matchesCat =
          _selectedCategory == GovServiceCategory.all || s.category == _selectedCategory;
      final q = _searchQuery.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          s.title.toLowerCase().contains(q) ||
          s.titleKh.toLowerCase().contains(q) ||
          s.ministry.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q);
      return matchesCat && matchesQuery;
    }).toList();
  }

  void _openPaymentSheet(GovernmentServiceItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _GovernmentPaymentSheet(
        item: item,
        onSuccess: (txn) {
          Navigator.pop(sheetCtx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionReceiptScreen(transaction: txn),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Services'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D253F), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: Colors.amber,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Public Services & Taxes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'សេវាសាធារណៈ និងបង់ពន្ធរដ្ឋផ្លូវការ',
                        style: TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Direct, instant settlement with 0% service charge.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search services (e.g. Road Tax, EDC, NSSF)...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All', GovServiceCategory.all),
                const SizedBox(width: 8),
                _buildCategoryChip('Taxes & Dues', GovServiceCategory.tax),
                const SizedBox(width: 8),
                _buildCategoryChip('Utilities (EDC/Water)', GovServiceCategory.utility),
                const SizedBox(width: 8),
                _buildCategoryChip('Transport & MPWT', GovServiceCategory.transport),
                const SizedBox(width: 8),
                _buildCategoryChip('Social Security (NSSF)', GovServiceCategory.social),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Services List
          if (_filteredServices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 48, color: AppColors.muted),
                    const SizedBox(height: 12),
                    const Text(
                      'No matching government service found',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._filteredServices.map((service) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildServiceTile(service),
                )),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, GovServiceCategory category) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = category),
      selectedColor: AppColors.indigo.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.indigo : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
    );
  }

  Widget _buildServiceTile(GovernmentServiceItem service) {
    return InkWell(
      onTap: () => _openPaymentSheet(service),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x050F172A),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: service.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(service.icon, color: service.color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          service.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '0% FEE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.titleKh,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.ministry,
                    style: TextStyle(
                      fontSize: 11,
                      color: service.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _GovernmentPaymentSheet extends StatefulWidget {
  const _GovernmentPaymentSheet({
    required this.item,
    required this.onSuccess,
  });

  final GovernmentServiceItem item;
  final ValueChanged<TransactionModel> onSuccess;

  @override
  State<_GovernmentPaymentSheet> createState() => _GovernmentPaymentSheetState();
}

class _GovernmentPaymentSheetState extends State<_GovernmentPaymentSheet> {
  final _referenceController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  final _notesController = TextEditingController();

  bool _obscurePin = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.item.defaultAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    final ref = _referenceController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final pin = _pinController.text.trim();
    final notes = _notesController.text.trim();

    if (ref.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter ${widget.item.referenceLabel}.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid payment amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (AuthState.instance.isAuthenticated && pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your 6-digit transaction PIN.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final balance = WalletApiService.instance.wallet.effectiveAvailable;
    if (balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance. Your balance is \$${balance.toStringAsFixed(2)}.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await GovernmentServiceApiService.instance.payGovernmentService(
        serviceType: widget.item.id,
        serviceName: widget.item.title,
        consumerNumber: ref,
        amount: amount,
        pin: pin,
        notes: notes,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      final txnCode = res['transaction_code']?.toString() ?? 'GOV-${DateTime.now().millisecondsSinceEpoch}';
      final createdTxn = TransactionModel(
        id: txnCode,
        name: widget.item.title,
        amount: -amount,
        date: 'Today',
        category: TransactionCategory.sent,
        status: 'Completed',
        transactionCode: txnCode,
        receiverName: widget.item.ministry,
        description: '${widget.item.title} ($ref)${notes.isNotEmpty ? ' - $notes' : ''}',
        currency: 'USD',
      );

      InAppNotificationService.instance.show(
        title: 'Payment Successful',
        message: 'Paid \$${amount.toStringAsFixed(2)} for ${widget.item.title} ($ref).',
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF00D09C),
      );

      widget.onSuccess(createdTxn);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = WalletApiService.instance.wallet.effectiveAvailable;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Service Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.item.icon, color: widget.item.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.item.ministry,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.item.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Balance Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.indigo.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.indigo.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Available Balance:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '\$${balance.toStringAsFixed(2)} USD',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Reference Number
            Text(
              widget.item.referenceLabel,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                hintText: widget.item.referenceHint,
                prefixIcon: const Icon(Icons.numbers_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Amount Field
            const Text(
              'Payment Amount (USD)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 10),

            // Preset Amount Chips
            Wrap(
              spacing: 8,
              children: widget.item.presetAmounts.map((amt) {
                return ActionChip(
                  label: Text('\$${amt.toStringAsFixed(0)}'),
                  onPressed: () {
                    setState(() {
                      _amountController.text = amt.toStringAsFixed(2);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Note / Remark
            const Text(
              'Remarks / Details (Optional)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'e.g. 2026 sticker or family contribution',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // 6-digit PIN
            const Text(
              'Transaction PIN',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: _obscurePin,
              decoration: InputDecoration(
                hintText: 'Enter 6-digit wallet PIN',
                counterText: '',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Pay Button
            FilledButton(
              onPressed: _loading ? null : _submitPayment,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: AppColors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirm & Pay Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
