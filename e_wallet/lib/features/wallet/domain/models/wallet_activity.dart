enum ActivityKind { income, expense, deposit, payment }

class WalletActivity {
  const WalletActivity({
    required this.name,
    required this.time,
    required this.amount,
    required this.kind,
  });
  final String name, time;
  final double amount;
  final ActivityKind kind;
  bool get isCredit => amount >= 0;
}
