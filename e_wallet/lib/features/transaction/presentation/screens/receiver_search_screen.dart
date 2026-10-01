import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../beneficiaries/data/beneficiary_api_service.dart';
import '../../../beneficiaries/presentation/screens/beneficiaries_screen.dart';
import '../../data/transaction_api_service.dart';
import 'send_amount_screen.dart';

class ReceiverSearchScreen extends StatefulWidget {
  const ReceiverSearchScreen({super.key});

  @override
  State<ReceiverSearchScreen> createState() => _ReceiverSearchScreenState();
}

class _ReceiverSearchScreenState extends State<ReceiverSearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, String>> _remoteReceivers = [];

  @override
  void initState() {
    super.initState();
    BeneficiaryApiService.instance.fetchBeneficiaries().then((_) {
      if (mounted) setState(() {});
    });
    TransactionApiService.instance.lookupRecipients().then((list) {
      if (mounted && list.isNotEmpty) {
        setState(() => _remoteReceivers = list);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _open(BuildContext context, String receiver, String walletNumber) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SendAmountScreen(
            receiver: receiver,
            receiverWalletNumber: walletNumber,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BeneficiaryApiService.instance,
      builder: (context, _) {
        final allBeneficiaries = BeneficiaryApiService.instance.beneficiaries;
        final filteredBeneficiaries = allBeneficiaries.where((b) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return b.name.toLowerCase().contains(q) ||
              b.nickname.toLowerCase().contains(q) ||
              b.walletNumber.toLowerCase().contains(q);
        }).toList();

        final defaultReceivers = [
          {'name': 'Sokha Chan', 'wallet': 'WAL-01493803', 'phone': '012 345 678'},
          {'name': 'Thida Meas', 'wallet': 'WAL-59433784', 'phone': '098 765 432'},
          {'name': 'Ron Ram', 'wallet': 'WAL-40564511', 'phone': '018 937 583'},
          {'name': 'Lay Kimkruy', 'wallet': 'WAL-58627901', 'phone': '017 828 282'},
        ];
        final recentReceivers = (_remoteReceivers.isNotEmpty ? _remoteReceivers : defaultReceivers).where((item) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return (item['name'] ?? '').toLowerCase().contains(q) ||
              (item['wallet'] ?? '').toLowerCase().contains(q) ||
              (item['phone'] ?? '').toLowerCase().contains(q);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Send money'),
            actions: [
              IconButton(
                icon: const Icon(Icons.contacts_outlined),
                tooltip: 'Manage Beneficiaries',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BeneficiariesScreen()),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Wallet ID (e.g. WAL-...), phone, or name',
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded),
                          onPressed: () => _open(context, _searchQuery, _searchQuery),
                        )
                      : null,
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    _open(context, text.trim(), text.trim());
                  }
                },
              ),
              const SizedBox(height: 24),
              if (recentReceivers.isNotEmpty) ...[
                const Text(
                  'RECENT RECEIVERS',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 18,
                  children: recentReceivers.map(
                    (item) => InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => _open(context, item['name']!, item['wallet']!),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 27,
                            backgroundColor: AppColors.indigo,
                            child: Text(
                              item['name']![0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item['name']!,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SAVED BENEFICIARIES',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.manage_accounts_outlined, size: 16),
                        label: const Text('Manage'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BeneficiariesScreen()),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                        onPressed: _showAddBeneficiaryDialog,
                      ),
                    ],
                  ),
                ],
              ),
              if (filteredBeneficiaries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'No beneficiaries match "$_searchQuery".'
                          : 'No saved beneficiaries yet.',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              else
                ...filteredBeneficiaries.map(
                  (b) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    onTap: () => _open(context, b.displayName, b.walletNumber),
                    leading: CircleAvatar(
                      backgroundColor: b.isFavorite ? AppColors.accentGreen : AppColors.indigo,
                      foregroundColor: b.isFavorite ? AppColors.primaryDark : Colors.white,
                      child: Text(b.name.isNotEmpty ? b.name[0].toUpperCase() : 'U'),
                    ),
                    title: Text(b.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      b.walletNumber.isNotEmpty ? b.walletNumber : 'NovaPay wallet',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        b.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: b.isFavorite ? Colors.amber : AppColors.muted,
                      ),
                      onPressed: () {
                        BeneficiaryApiService.instance.editBeneficiary(
                          id: b.id,
                          isFavorite: !b.isFavorite,
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddBeneficiaryDialog() {
    final walletController = TextEditingController();
    final nicknameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Beneficiary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: walletController,
              decoration: const InputDecoration(labelText: 'Wallet Number (e.g. WAL-...)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(labelText: 'Nickname (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final wNum = walletController.text.trim();
              if (wNum.isEmpty) return;
              Navigator.pop(dialogCtx);
              try {
                await BeneficiaryApiService.instance.addBeneficiary(
                  walletNumber: wNum,
                  nickname: nicknameController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Beneficiary saved successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
