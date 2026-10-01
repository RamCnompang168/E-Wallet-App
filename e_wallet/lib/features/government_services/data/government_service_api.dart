import '../../../../core/network/api_client.dart';
import '../../notifications/data/notification_api_service.dart';
import '../../transaction/data/transaction_api_service.dart';
import '../../wallet/data/wallet_api_service.dart';

class GovernmentServiceApiService {
  GovernmentServiceApiService._();
  static final GovernmentServiceApiService instance = GovernmentServiceApiService._();

  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> payGovernmentService({
    required String serviceType,
    required String serviceName,
    required String consumerNumber,
    required double amount,
    required String pin,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw ApiException('Payment amount must be greater than zero.');
    }
    if (consumerNumber.trim().isEmpty) {
      throw ApiException('Bill or reference number is required.');
    }

    if (_client.isAuthenticated) {
      final res = await _client.post(
        'payments/government/',
        idempotent: true,
        pin: pin,
        body: {
          'service_type': serviceType,
          'service_name': serviceName,
          'consumer_number': consumerNumber.trim(),
          'amount': amount.toStringAsFixed(4),
          'pin': pin.trim(),
          'notes': notes?.trim() ?? '',
        },
      );

      // Refresh wallet balance, transactions, and notifications
      await WalletApiService.instance.fetchPrimaryWallet();
      await TransactionApiService.instance.fetchTransactions();
      await NotificationApiService.instance.fetchNotifications();

      return res.data as Map<String, dynamic>;
    } else {
      // Mock / Offline mode fallback
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return {
        'transaction_code': 'GOV-MOCK-${DateTime.now().millisecondsSinceEpoch}',
        'reference_number': 'REF-${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount.toStringAsFixed(2),
        'service_name': serviceName,
        'consumer_number': consumerNumber,
        'created_at': DateTime.now().toIso8601String(),
      };
    }
  }
}
