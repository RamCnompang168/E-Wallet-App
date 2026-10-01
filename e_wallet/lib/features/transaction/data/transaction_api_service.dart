import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_state.dart';
import '../../wallet/data/wallet_api_service.dart';
import '../../notifications/data/notification_api_service.dart';
import '../domain/models/transaction.dart';
import 'mock_data/mock_transactions.dart';

class TransactionApiService extends ChangeNotifier {
  TransactionApiService._();
  static final TransactionApiService instance = TransactionApiService._();

  final ApiClient _client = ApiClient.instance;

  List<TransactionModel> _transactions = mockTransactions;
  bool _isLoading = false;
  String? _errorMessage;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<List<TransactionModel>> fetchTransactions({String? filter}) async {
    if (!_client.isAuthenticated) {
      return _transactions;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (filter != null && filter != 'All') {
        if (filter == 'Sent') queryParams['transaction_type'] = 'TRANSFER';
        if (filter == 'Deposit') queryParams['transaction_type'] = 'TOPUP';
        if (filter == 'Withdraw') queryParams['transaction_type'] = 'WITHDRAWAL';
      }

      final res = await _client.get('transactions/', queryParams: queryParams);
      final currentWalletNumber = WalletApiService.instance.wallet.walletNumber;
      final currentUserId = AuthState.instance.currentUser?.id;

      dynamic listData;
      if (res.data is Map<String, dynamic> && (res.data as Map<String, dynamic>).containsKey('results')) {
        listData = res.data['results'];
      } else if (res.data is List) {
        listData = res.data;
      }

      if (listData is List) {
        final parsed = listData
            .map((item) => TransactionModel.fromJson(
                  item as Map<String, dynamic>,
                  currentWalletNumber: currentWalletNumber,
                  currentUserId: currentUserId,
                ))
            .toList();

        // If user is authenticated, use real transactions (even if empty)
        // If unauthenticated / demo mode, fallback to mock data only if parsed is empty
        if (_client.isAuthenticated || parsed.isNotEmpty) {
          _transactions = parsed;
        }
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      // Offline fallback: keep mock transactions
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _transactions;
  }

  void reset() {
    _transactions = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<List<Map<String, String>>> lookupRecipients([String query = '']) async {
    if (!_client.isAuthenticated) return [];
    try {
      final res = await _client.get(
        'transfers/lookup/',
        queryParams: query.isNotEmpty ? {'q': query} : null,
      );
      if (res.data is List) {
        return (res.data as List).map((item) {
          final m = item as Map<String, dynamic>;
          return {
            'wallet': m['wallet_number']?.toString() ?? '',
            'name': m['name']?.toString() ?? '',
            'phone': m['phone_number']?.toString() ?? '',
          };
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<TransactionModel> sendTransfer({
    required String receiverWalletNumber,
    required double amount,
    required String pin,
    String? description,
  }) async {
    if (!_client.isAuthenticated) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final mockTxn = TransactionModel(
        id: 'TXN-DEMO-${DateTime.now().millisecondsSinceEpoch}',
        name: receiverWalletNumber,
        amount: -amount,
        date: 'Today · Just now',
        category: TransactionCategory.sent,
        status: 'Completed',
        receiverName: receiverWalletNumber,
        receiverWalletNumber: receiverWalletNumber,
        description: description?.trim() ?? 'P2P Transfer',
        timestamp: DateTime.now(),
      );
      _transactions = [mockTxn, ..._transactions];
      notifyListeners();
      return mockTxn;
    }

    final res = await _client.post(
      'transfers/',
      idempotent: true,
      pin: pin,
      body: {
        'receiver_wallet_number': receiverWalletNumber.trim(),
        'amount': amount.toStringAsFixed(4),
        'description': description?.trim() ?? 'P2P Transfer',
        'pin': pin,
      },
    );

    final data = res.data as Map<String, dynamic>;
    final currentWalletNumber = WalletApiService.instance.wallet.walletNumber;
    final currentUserId = AuthState.instance.currentUser?.id;
    final createdTxn = TransactionModel.fromJson(
      data,
      currentWalletNumber: currentWalletNumber,
      currentUserId: currentUserId,
    );

    // Refresh wallet balance, transactions list, and notifications
    await WalletApiService.instance.fetchPrimaryWallet();
    await NotificationApiService.instance.fetchNotifications();
    _transactions = [createdTxn, ..._transactions];
    notifyListeners();

    return createdTxn;
  }
}
