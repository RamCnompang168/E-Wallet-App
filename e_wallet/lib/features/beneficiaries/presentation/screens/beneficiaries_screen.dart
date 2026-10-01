import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../transaction/presentation/screens/send_amount_screen.dart';
import '../../data/beneficiary_api_service.dart';

class BeneficiariesScreen extends StatefulWidget {
  const BeneficiariesScreen({super.key});

  @override
  State<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends State<BeneficiariesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await BeneficiaryApiService.instance.fetchBeneficiaries();
    if (mounted) setState(() => _loading = false);
  }

  void _showAddDialog() {
    final walletController = TextEditingController();
    final nicknameController = TextEditingController();
    bool isFav = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Beneficiary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: walletController,
                decoration: const InputDecoration(
                  labelText: 'Wallet Number',
                  hintText: 'e.g. WAL-87654321',
                  prefixIcon: Icon(Icons.wallet_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname (optional)',
                  hintText: 'e.g. My Sister',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: isFav,
                title: const Text('Mark as favorite', style: TextStyle(fontSize: 14)),
                onChanged: (val) => setDialogState(() => isFav = val ?? false),
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
                if (wNum.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a wallet number.')),
                  );
                  return;
                }
                Navigator.pop(dialogCtx);
                try {
                  await BeneficiaryApiService.instance.addBeneficiary(
                    walletNumber: wNum,
                    nickname: nicknameController.text.trim(),
                    isFavorite: isFav,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.accentGreen,
                        content: Text('Beneficiary added successfully!', style: TextStyle(color: Colors.black)),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BeneficiaryItem beneficiary) {
    final nicknameController = TextEditingController(text: beneficiary.nickname);
    bool isFav = beneficiary.isFavorite;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit ${beneficiary.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: isFav,
                title: const Text('Mark as favorite', style: TextStyle(fontSize: 14)),
                onChanged: (val) => setDialogState(() => isFav = val ?? false),
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
                Navigator.pop(dialogCtx);
                final ok = await BeneficiaryApiService.instance.editBeneficiary(
                  id: beneficiary.id,
                  nickname: nicknameController.text.trim(),
                  isFavorite: isFav,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Beneficiary updated!' : 'Failed to update beneficiary.'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BeneficiaryItem beneficiary) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove Beneficiary'),
        content: Text('Are you sure you want to remove ${beneficiary.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final ok = await BeneficiaryApiService.instance.removeBeneficiary(beneficiary.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Beneficiary removed.' : 'Failed to remove beneficiary.'),
                  ),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _sendMoneyTo(BeneficiaryItem b) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SendAmountScreen(
          receiver: b.displayName,
          receiverWalletNumber: b.walletNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BeneficiaryApiService.instance,
      builder: (context, _) {
        final all = BeneficiaryApiService.instance.beneficiaries;
        final filtered = all.where((b) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return b.name.toLowerCase().contains(q) ||
              b.nickname.toLowerCase().contains(q) ||
              b.walletNumber.toLowerCase().contains(q);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manage Beneficiaries'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_outlined),
                tooltip: 'Add Beneficiary',
                onPressed: _showAddDialog,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by name, nickname, or wallet ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SAVED BENEFICIARIES (${filtered.length})',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add New'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (filtered.isEmpty)
                  FintechCard(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.muted),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No beneficiaries match "$_searchQuery"'
                                : 'No beneficiaries saved yet.',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _showAddDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add your first beneficiary'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  FintechCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (int i = 0; i < filtered.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 68),
                          _buildBeneficiaryTile(filtered[i]),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddDialog,
            backgroundColor: AppColors.indigo,
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            label: const Text('Add Beneficiary', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildBeneficiaryTile(BeneficiaryItem b) {
    return ListTile(
      onTap: () => _sendMoneyTo(b),
      leading: CircleAvatar(
        backgroundColor: b.isFavorite ? AppColors.accentGreen : AppColors.indigo,
        foregroundColor: b.isFavorite ? AppColors.primaryDark : Colors.white,
        child: Text(
          b.name.isNotEmpty ? b.name[0].toUpperCase() : 'U',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        b.displayName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        b.walletNumber.isNotEmpty ? b.walletNumber : 'NovaPay Account',
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              b.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: b.isFavorite ? Colors.amber : AppColors.muted,
            ),
            tooltip: b.isFavorite ? 'Unmark favorite' : 'Mark as favorite',
            onPressed: () {
              BeneficiaryApiService.instance.editBeneficiary(
                id: b.id,
                isFavorite: !b.isFavorite,
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (val) {
              if (val == 'send') {
                _sendMoneyTo(b);
              } else if (val == 'edit') {
                _showEditDialog(b);
              } else if (val == 'delete') {
                _confirmDelete(b);
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'send', child: Text('Send Money')),
              PopupMenuItem(value: 'edit', child: Text('Edit Nickname')),
              PopupMenuItem(value: 'delete', child: Text('Remove Beneficiary', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }
}
