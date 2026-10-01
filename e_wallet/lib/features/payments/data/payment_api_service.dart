import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../wallet/data/wallet_api_service.dart';
import '../../transaction/data/transaction_api_service.dart';
import '../../notifications/data/notification_api_service.dart';

class PaymentMethodItem {
  final String id;
  final String name;
  final String type;
  final String provider;

  const PaymentMethodItem({
    required this.id,
    required this.name,
    required this.type,
    required this.provider,
  });

  factory PaymentMethodItem.fromJson(Map<String, dynamic> json) =>
      PaymentMethodItem(
        id: json['id']?.toString() ?? '',
        name: json['method_name']?.toString() ?? 'Card',
        type: json['method_type']?.toString() ?? 'CARD',
        provider: json['provider_name']?.toString() ?? 'Gateway',
      );
}

class PaymentApiService extends ChangeNotifier {
  PaymentApiService._();
  static final PaymentApiService instance = PaymentApiService._();

  final ApiClient _client = ApiClient.instance;

  List<PaymentMethodItem> _methods = [];
  bool _isLoading = false;

  List<PaymentMethodItem> get methods => _methods;
  bool get isLoading => _isLoading;

  Future<List<PaymentMethodItem>> getPaymentMethods() async {
    if (!_client.isAuthenticated) return _methods;
    try {
      final res = await _client.get('payments/methods/');
      dynamic listData;
      if (res.data is Map<String, dynamic> && (res.data as Map<String, dynamic>).containsKey('results')) {
        listData = res.data['results'];
      } else if (res.data is List) {
        listData = res.data;
      }
      if (listData is List) {
        _methods = listData.map((m) => PaymentMethodItem.fromJson(m as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (_) {}
    return _methods;
  }

  Future<bool> topUp({
    required double amount,
    String? paymentMethodId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (paymentMethodId == null) {
        final methods = await getPaymentMethods();
        if (methods.isNotEmpty) {
          paymentMethodId = methods.first.id;
        }
      }

      if (paymentMethodId == null) {
        throw ApiException('No payment method available for top up.');
      }

      await _client.post(
        'payments/topups/',
        idempotent: true,
        body: {
          'payment_method_id': paymentMethodId,
          'amount': amount.toStringAsFixed(4),
          'provider_reference': 'TOP-${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      await WalletApiService.instance.fetchPrimaryWallet();
      await TransactionApiService.instance.fetchTransactions();
      await NotificationApiService.instance.fetchNotifications();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> withdraw({
    required double amount,
    required String destinationAccount,
    required String pin,
    String? paymentMethodId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (paymentMethodId == null) {
        final methods = await getPaymentMethods();
        if (methods.isNotEmpty) {
          paymentMethodId = methods.first.id;
        }
      }

      if (paymentMethodId == null) {
        throw ApiException('No payment method available for withdrawal.');
      }

      await _client.post(
        'payments/withdrawals/',
        idempotent: true,
        pin: pin,
        body: {
          'payment_method_id': paymentMethodId,
          'destination_account': destinationAccount,
          'amount': amount.toStringAsFixed(4),
          'pin': pin,
        },
      );

      await WalletApiService.instance.fetchPrimaryWallet();
      await TransactionApiService.instance.fetchTransactions();
      await NotificationApiService.instance.fetchNotifications();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
