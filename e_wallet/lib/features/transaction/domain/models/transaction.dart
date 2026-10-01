enum TransactionCategory { sent, received, deposit, withdraw }

/// Domain model representing a financial transaction record.
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.category,
    this.status = 'Completed',
    this.transactionCode,
    this.senderWalletNumber,
    this.receiverWalletNumber,
    this.senderName,
    this.receiverName,
    this.description,
    this.currency = 'USD',
    this.timestamp,
  });

  final String id;
  final String name;
  final double amount;
  final String date;
  final TransactionCategory category;
  final String status;
  final String? transactionCode;
  final String? senderWalletNumber;
  final String? receiverWalletNumber;
  final String? senderName;
  final String? receiverName;
  final String? description;
  final String currency;
  final DateTime? timestamp;

  bool get credit => amount >= 0;

  factory TransactionModel.fromJson(
    Map<String, dynamic> json, {
    String? currentWalletNumber,
    String? currentUserId,
  }) {
    final code = json['transaction_code']?.toString() ?? json['id']?.toString() ?? '';
    final type = (json['transaction_type']?.toString() ?? 'TRANSFER').toUpperCase();
    final rawAmount = double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0;
    final sender = json['sender_wallet_number']?.toString();
    final receiver = json['receiver_wallet_number']?.toString();
    final senderPerson = json['sender_name']?.toString().trim();
    final receiverPerson = json['receiver_name']?.toString().trim();
    final senderUserId = json['sender_user_id']?.toString();
    final receiverUserId = json['receiver_user_id']?.toString();
    final desc = json['description']?.toString().trim() ?? '';
    final direction = json['direction']?.toString().toUpperCase();
    final createdAt = json['created_at']?.toString() ?? '';

    TransactionCategory cat;
    double signedAmount;
    String displayName;

    if (type == 'TOPUP') {
      cat = TransactionCategory.deposit;
      signedAmount = rawAmount.abs();
      displayName = 'Top Up Deposit';
    } else if (type == 'WITHDRAWAL') {
      cat = TransactionCategory.withdraw;
      signedAmount = -rawAmount.abs();
      displayName = 'Bank Withdrawal';
    } else {
      // Determine if incoming (received) or outgoing (sent)
      bool isIncoming = false;
      if (direction == 'INCOMING') {
        isIncoming = true;
      } else if (direction == 'OUTGOING') {
        isIncoming = false;
      } else if (currentWalletNumber != null && currentWalletNumber.isNotEmpty) {
        if (receiver != null && receiver == currentWalletNumber) {
          isIncoming = true;
        } else if (sender != null && sender == currentWalletNumber) {
          isIncoming = false;
        }
      } else if (currentUserId != null && currentUserId.isNotEmpty) {
        if (receiverUserId != null && receiverUserId == currentUserId) {
          isIncoming = true;
        } else if (senderUserId != null && senderUserId == currentUserId) {
          isIncoming = false;
        }
      }

      if (isIncoming) {
        cat = TransactionCategory.received;
        signedAmount = rawAmount.abs();
        if (senderPerson != null && senderPerson.isNotEmpty) {
          displayName = senderPerson;
        } else if (sender != null && sender.isNotEmpty) {
          displayName = 'Transfer from $sender';
        } else {
          displayName = 'Payment Received';
        }
      } else {
        cat = TransactionCategory.sent;
        signedAmount = -rawAmount.abs();
        if (receiverPerson != null && receiverPerson.isNotEmpty) {
          displayName = receiverPerson;
        } else if (receiver != null && receiver.isNotEmpty) {
          displayName = 'Transfer to $receiver';
        } else if (desc.isNotEmpty) {
          displayName = desc;
        } else {
          displayName = 'Payment Sent';
        }
      }
    }

    // Format date string and timestamp
    String dateStr = 'Recent';
    DateTime? dt;
    if (createdAt.isNotEmpty) {
      try {
        dt = DateTime.parse(createdAt).toLocal();
        dateStr =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        dateStr = createdAt;
      }
    }

    return TransactionModel(
      id: json['id']?.toString() ?? code,
      name: displayName,
      amount: signedAmount,
      date: dateStr,
      category: cat,
      status: json['status']?.toString() ?? 'COMPLETED',
      transactionCode: code,
      senderWalletNumber: sender,
      receiverWalletNumber: receiver,
      senderName: senderPerson,
      receiverName: receiverPerson,
      description: desc.isNotEmpty ? desc : null,
      currency: json['currency']?.toString() ?? 'USD',
      timestamp: dt,
    );
  }
}
