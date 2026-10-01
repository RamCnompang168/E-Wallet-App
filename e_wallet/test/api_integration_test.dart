import 'package:flutter_test/flutter_test.dart';
import 'package:e_wallet/core/network/api_client.dart';
import 'package:e_wallet/core/services/auth_state.dart';
import 'package:e_wallet/features/wallet/domain/models/wallet.dart';
import 'package:e_wallet/features/transaction/domain/models/transaction.dart';
import 'package:e_wallet/features/notifications/data/notification_api_service.dart';

void main() {
  group('UserModel parsing tests', () {
    test('parses full user details and formats initials', () {
      final json = {
        'id': 'u-1234',
        'email': 'alice@novapay.com',
        'phone_number': '+12025550101',
        'full_name': 'Alice Smith',
        'role': 'CUSTOMER',
        'status': 'ACTIVE',
        'kyc_tier': 1,
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'u-1234');
      expect(user.email, 'alice@novapay.com');
      expect(user.fullName, 'Alice Smith');
      expect(user.initials, 'AS');
      expect(user.kycTier, 1);
      expect(user.role, 'CUSTOMER');
    });

    test('handles single name initials fallback', () {
      final user = UserModel.fromJson({
        'id': '1',
        'email': 'b@b.com',
        'phone_number': '123',
        'full_name': 'Bob',
        'role': 'CUSTOMER',
        'status': 'ACTIVE',
        'kyc_tier': 0,
      });
      expect(user.initials, 'B');
    });
  });

  group('WalletModel parsing tests', () {
    test('parses wallet balances, currency, and available funds', () {
      final json = {
        'id': 'w-999',
        'wallet_number': 'WAL-12345678',
        'current_balance': '1250.7500',
        'available_balance': '1200.7500',
        'hold_balance': '50.0000',
        'currency': 'USD',
        'status': 'ACTIVE',
      };

      final wallet = WalletModel.fromJson(json);
      expect(wallet.id, 'w-999');
      expect(wallet.walletNumber, 'WAL-12345678');
      expect(wallet.balance, 1250.75);
      expect(wallet.availableBalance, 1200.75);
      expect(wallet.effectiveAvailable, 1200.75);
      expect(wallet.holdBalance, 50.0);
      expect(wallet.currency, 'USD');
    });
  });

  group('TransactionModel parsing tests', () {
    test('correctly identifies sent transfer and sets negative amount', () {
      final json = {
        'id': 't-1',
        'transaction_code': 'TXN-001',
        'transaction_type': 'TRANSFER',
        'status': 'COMPLETED',
        'sender_wallet_number': 'WAL-ALICE-1',
        'receiver_wallet_number': 'WAL-BOB-2',
        'amount': '50.0000',
        'fee_amount': '0.0000',
        'currency': 'USD',
        'description': 'Lunch payment',
        'created_at': '2026-09-23T12:00:00Z',
      };

      final txn = TransactionModel.fromJson(json, currentWalletNumber: 'WAL-ALICE-1');
      expect(txn.category, TransactionCategory.sent);
      expect(txn.amount, -50.0);
      expect(txn.credit, isFalse);
      expect(txn.transactionCode, 'TXN-001');
    });

    test('correctly identifies received transfer and sets positive amount', () {
      final json = {
        'id': 't-2',
        'transaction_code': 'TXN-002',
        'transaction_type': 'TRANSFER',
        'status': 'COMPLETED',
        'sender_wallet_number': 'WAL-ALICE-1',
        'receiver_wallet_number': 'WAL-BOB-2',
        'amount': '50.0000',
        'currency': 'USD',
        'description': 'Lunch payment',
        'created_at': '2026-09-23T12:00:00Z',
      };

      final txn = TransactionModel.fromJson(json, currentWalletNumber: 'WAL-BOB-2');
      expect(txn.category, TransactionCategory.received);
      expect(txn.amount, 50.0);
      expect(txn.credit, isTrue);
    });

    test('correctly identifies top-up deposit', () {
      final json = {
        'id': 't-3',
        'transaction_code': 'TXN-TOP-01',
        'transaction_type': 'TOPUP',
        'status': 'COMPLETED',
        'amount': '200.0000',
        'currency': 'USD',
        'description': 'Debit card deposit',
      };

      final txn = TransactionModel.fromJson(json);
      expect(txn.category, TransactionCategory.deposit);
      expect(txn.amount, 200.0);
      expect(txn.credit, isTrue);
    });

    test('correctly identifies withdrawal', () {
      final json = {
        'id': 't-4',
        'transaction_code': 'TXN-WTH-01',
        'transaction_type': 'WITHDRAWAL',
        'status': 'COMPLETED',
        'amount': '100.0000',
        'currency': 'USD',
        'description': 'ATM withdrawal',
      };

      final txn = TransactionModel.fromJson(json);
      expect(txn.category, TransactionCategory.withdraw);
      expect(txn.amount, -100.0);
      expect(txn.credit, isFalse);
    });
  });

  group('ApiException formatting tests', () {
    test('formats validation field errors into readable multiline message', () {
      final exc = ApiException(
        'Validation failed',
        statusCode: 400,
        errors: {
          'pin': ['PIN must be exactly 6 numeric digits.'],
          'amount': ['Amount must be greater than zero.'],
        },
      );

      final str = exc.toString();
      expect(str, contains('Validation failed'));
      expect(str, contains('pin: PIN must be exactly 6 numeric digits.'));
      expect(str, contains('amount: Amount must be greater than zero.'));
    });
  });

  group('NotificationModel parsing tests', () {
    test('parses deposit notification and assigns correct title and icon', () {
      final json = {
        'id': 'notif-1',
        'title': 'Deposit Confirmed',
        'message': 'Successfully deposited \$50.00 USD into your wallet via Card. Reference: TXN-01.',
        'notification_type': 'TRANSACTION',
        'transaction_code': 'TXN-01',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final notif = NotificationModel.fromJson(json);
      expect(notif.id, 'notif-1');
      expect(notif.title, 'Deposit Confirmed');
      expect(notif.transactionCode, 'TXN-01');
      expect(notif.isRead, isFalse);
      expect(notif.formattedTime, 'Just now');
    });

    test('parses withdrawal notification and assigns correct status', () {
      final json = {
        'id': 'notif-2',
        'title': 'Withdrawal Completed',
        'message': 'Withdrew \$25.00 USD to ABA Bank. Fee: \$1.50. Reference: TXN-02.',
        'notification_type': 'TRANSACTION',
        'is_read': true,
        'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      };

      final notif = NotificationModel.fromJson(json);
      expect(notif.id, 'notif-2');
      expect(notif.title, 'Withdrawal Completed');
      expect(notif.isRead, isTrue);
      expect(notif.formattedTime, '5m ago');
    });
  });
}
