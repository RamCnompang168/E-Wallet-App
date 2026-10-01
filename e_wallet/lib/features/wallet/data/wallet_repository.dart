import '../domain/models/wallet_activity.dart';

class WalletRepository {
  List<WalletActivity> recent() => const [
    WalletActivity(
      name: 'Sophia Martinez',
      time: 'Today · 10:42',
      amount: 250,
      kind: ActivityKind.income,
    ),
    WalletActivity(
      name: 'Netflix',
      time: 'Today · 08:15',
      amount: -15.49,
      kind: ActivityKind.payment,
    ),
    WalletActivity(
      name: 'Cash deposit',
      time: 'Yesterday · 16:30',
      amount: 600,
      kind: ActivityKind.deposit,
    ),
    WalletActivity(
      name: 'Mika Chen',
      time: 'Yesterday · 12:10',
      amount: -82.75,
      kind: ActivityKind.expense,
    ),
  ];
}
