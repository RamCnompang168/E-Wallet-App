/// Wallet domain entity representing account balance, ledger state, and currency.
class WalletModel {
  const WalletModel({
    required this.balance,
    required this.currency,
    required this.isHidden,
    this.id = '',
    this.walletNumber = 'NP-7390-5318',
    this.availableBalance,
    this.holdBalance = 0.0,
    this.status = 'ACTIVE',
  });

  final String id;
  final String walletNumber;
  final double balance;
  final double? availableBalance;
  final double holdBalance;
  final String currency;
  final bool isHidden;
  final String status;

  double get effectiveAvailable => availableBalance ?? balance;

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        id: json['id']?.toString() ?? '',
        walletNumber: json['wallet_number']?.toString() ?? 'NP-7390-5318',
        balance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
        availableBalance: double.tryParse(json['available_balance']?.toString() ?? '0') ?? 0.0,
        holdBalance: double.tryParse(json['hold_balance']?.toString() ?? '0') ?? 0.0,
        currency: json['currency']?.toString() ?? 'USD',
        status: json['status']?.toString() ?? 'ACTIVE',
        isHidden: false,
      );
}
