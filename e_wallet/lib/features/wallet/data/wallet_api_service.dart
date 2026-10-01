import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../domain/models/wallet.dart';
import 'mock_data/mock_wallet.dart';

class WalletApiService extends ChangeNotifier {
  WalletApiService._();
  static final WalletApiService instance = WalletApiService._();

  final ApiClient _client = ApiClient.instance;

  WalletModel _wallet = mockWallet;
  bool _isLoading = false;
  String? _errorMessage;

  WalletModel get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<WalletModel> fetchPrimaryWallet() async {
    if (!_client.isAuthenticated) {
      return _wallet;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _client.get('wallet/');
      if (res.data is Map<String, dynamic>) {
        _wallet = WalletModel.fromJson(res.data as Map<String, dynamic>);
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      // Offline fallback
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _wallet;
  }

  void reset() {
    _wallet = mockWallet;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
