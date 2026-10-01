import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';

class BeneficiaryItem {
  final String id;
  final String walletNumber;
  final String name;
  final String nickname;
  final bool isFavorite;

  const BeneficiaryItem({
    required this.id,
    required this.walletNumber,
    required this.name,
    this.nickname = '',
    this.isFavorite = false,
  });

  String get displayName => nickname.isNotEmpty ? '$nickname ($name)' : name;

  BeneficiaryItem copyWith({
    String? id,
    String? walletNumber,
    String? name,
    String? nickname,
    bool? isFavorite,
  }) =>
      BeneficiaryItem(
        id: id ?? this.id,
        walletNumber: walletNumber ?? this.walletNumber,
        name: name ?? this.name,
        nickname: nickname ?? this.nickname,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  factory BeneficiaryItem.fromJson(Map<String, dynamic> json) =>
      BeneficiaryItem(
        id: json['id']?.toString() ?? '',
        walletNumber: json['beneficiary_wallet_number']?.toString() ?? '',
        name: json['beneficiary_name']?.toString() ?? 'NovaPay User',
        nickname: json['nickname']?.toString() ?? '',
        isFavorite: json['is_favorite'] == true,
      );
}

class BeneficiaryApiService extends ChangeNotifier {
  BeneficiaryApiService._();
  static final BeneficiaryApiService instance = BeneficiaryApiService._();

  final ApiClient _client = ApiClient.instance;

  List<BeneficiaryItem> _beneficiaries = const [
    BeneficiaryItem(
      id: '1',
      name: 'Thida Meas',
      walletNumber: 'WAL-87654321',
      isFavorite: true,
    ),
    BeneficiaryItem(
      id: '2',
      name: 'Sokha Keo',
      walletNumber: 'WAL-11223344',
      isFavorite: true,
    ),
  ];

  List<BeneficiaryItem> get beneficiaries => _beneficiaries;

  Future<List<BeneficiaryItem>> fetchBeneficiaries() async {
    if (!_client.isAuthenticated) return _beneficiaries;

    try {
      final res = await _client.get('beneficiaries/');
      dynamic listData;
      if (res.data is Map<String, dynamic> &&
          (res.data as Map<String, dynamic>).containsKey('results')) {
        listData = res.data['results'];
      } else if (res.data is List) {
        listData = res.data;
      }
      if (listData is List) {
        _beneficiaries = listData
            .map((b) => BeneficiaryItem.fromJson(b as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {}

    return _beneficiaries;
  }

  Future<BeneficiaryItem?> addBeneficiary({
    required String walletNumber,
    String? nickname,
    bool isFavorite = false,
  }) async {
    if (_client.isAuthenticated) {
      final res = await _client.post('beneficiaries/', body: {
        'wallet_number': walletNumber.trim(),
        if (nickname != null && nickname.isNotEmpty) 'nickname': nickname.trim(),
        'is_favorite': isFavorite,
      });
      final item = BeneficiaryItem.fromJson(res.data as Map<String, dynamic>);
      _beneficiaries = [item, ..._beneficiaries];
      notifyListeners();
      return item;
    } else {
      final item = BeneficiaryItem(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        walletNumber: walletNumber.trim(),
        name: nickname ?? 'NovaPay User',
        nickname: nickname ?? '',
        isFavorite: isFavorite,
      );
      _beneficiaries = [item, ..._beneficiaries];
      notifyListeners();
      return item;
    }
  }

  Future<bool> editBeneficiary({
    required String id,
    String? nickname,
    bool? isFavorite,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (nickname != null) body['nickname'] = nickname.trim();
      if (isFavorite != null) body['is_favorite'] = isFavorite;

      if (_client.isAuthenticated) {
        await _client.patch('beneficiaries/$id/', body: body);
      }
      _beneficiaries = _beneficiaries.map((b) {
        if (b.id == id) {
          return b.copyWith(
            nickname: nickname ?? b.nickname,
            isFavorite: isFavorite ?? b.isFavorite,
          );
        }
        return b;
      }).toList();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to edit beneficiary: $e');
      return false;
    }
  }

  Future<bool> removeBeneficiary(String id) async {
    try {
      if (_client.isAuthenticated) {
        await _client.delete('beneficiaries/$id/');
      }
      _beneficiaries = _beneficiaries.where((b) => b.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to remove beneficiary: $e');
      return false;
    }
  }

  void reset() {
    _beneficiaries = const [
      BeneficiaryItem(
        id: '1',
        name: 'Thida Meas',
        walletNumber: 'WAL-87654321',
        isFavorite: true,
      ),
      BeneficiaryItem(
        id: '2',
        name: 'Sokha Keo',
        walletNumber: 'WAL-11223344',
        isFavorite: true,
      ),
    ];
    notifyListeners();
  }
}
