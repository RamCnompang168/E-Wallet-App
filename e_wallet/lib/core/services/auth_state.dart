import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../../features/wallet/data/wallet_api_service.dart';
import '../../features/transaction/data/transaction_api_service.dart';
import '../../features/notifications/data/notification_api_service.dart';
import '../../features/beneficiaries/data/beneficiary_api_service.dart';

class UserModel {
  final String id;
  final String email;
  final String phoneNumber;
  final String fullName;
  final String role;
  final String status;
  final int kycTier;
  final String? profilePhoto;
  final String? gender;
  final String? dateOfBirth;
  final String? idDocumentType;
  final String? idDocumentNumber;
  final String? idDocumentPhoto;

  const UserModel({
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
    required this.status,
    required this.kycTier,
    this.profilePhoto,
    this.gender,
    this.dateOfBirth,
    this.idDocumentType,
    this.idDocumentNumber,
    this.idDocumentPhoto,
  });

  bool get isAdminOrStaff =>
      role.toUpperCase() == 'ADMIN' ||
      role.toUpperCase() == 'SUPER_ADMIN' ||
      role.toUpperCase() == 'STAFF' ||
      role.toUpperCase() == 'STAFFMEMBER';

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'NP';
  }

  String? get avatarUrl {
    if (profilePhoto == null || profilePhoto!.isEmpty) return null;
    if (profilePhoto!.startsWith('http://') || profilePhoto!.startsWith('https://')) {
      return profilePhoto;
    }
    final host = ApiClient.instance.baseUrl.replaceAll('/api/v1', '');
    final cleanPath = profilePhoto!.startsWith('/') ? profilePhoto! : '/$profilePhoto';
    return '$host$cleanPath';
  }

  String? get idDocumentPhotoUrl {
    if (idDocumentPhoto == null || idDocumentPhoto!.isEmpty) return null;
    if (idDocumentPhoto!.startsWith('http://') || idDocumentPhoto!.startsWith('https://')) {
      return idDocumentPhoto;
    }
    final host = ApiClient.instance.baseUrl.replaceAll('/api/v1', '');
    final cleanPath = idDocumentPhoto!.startsWith('/') ? idDocumentPhoto! : '/$idDocumentPhoto';
    return '$host$cleanPath';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phoneNumber: json['phone_number']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? 'NovaPay User',
        role: json['role']?.toString() ?? 'CUSTOMER',
        status: json['status']?.toString() ?? 'ACTIVE',
        kycTier: (json['kyc_tier'] is int)
            ? json['kyc_tier']
            : int.tryParse(json['kyc_tier']?.toString() ?? '0') ?? 0,
        profilePhoto: json['profile_photo']?.toString(),
        gender: json['gender']?.toString(),
        dateOfBirth: json['date_of_birth']?.toString(),
        idDocumentType: json['id_document_type']?.toString(),
        idDocumentNumber: json['id_document_number']?.toString(),
        idDocumentPhoto: json['id_document_photo']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone_number': phoneNumber,
        'full_name': fullName,
        'role': role,
        'status': status,
        'kyc_tier': kycTier,
        'profile_photo': profilePhoto,
        'gender': gender,
        'date_of_birth': dateOfBirth,
        'id_document_type': idDocumentType,
        'id_document_number': idDocumentNumber,
        'id_document_photo': idDocumentPhoto,
      };
}

class AuthState extends ChangeNotifier {
  AuthState._();
  static final AuthState instance = AuthState._();

  final ApiClient _client = ApiClient.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _client.isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    if (_initialized) return;
    await _client.init();

    final savedUser = await _client.getSavedUserProfile();
    if (savedUser != null) {
      _currentUser = UserModel.fromJson(savedUser);
    }

    if (_client.isAuthenticated) {
      try {
        await refreshProfile();
        await WalletApiService.instance.fetchPrimaryWallet();
        await TransactionApiService.instance.fetchTransactions();
        NotificationApiService.instance.fetchNotifications();
        NotificationApiService.instance.startPolling();
      } catch (_) {
        // Token might be expired or offline, fallback to cached profile
      }
    }
    _initialized = true;
    notifyListeners();
  }

  bool _isPendingApproval = false;
  bool get isPendingApproval => _isPendingApproval;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _client.post(
        'auth/login/',
        requiresAuth: false,
        body: {
          'username': username.trim(),
          'password': password,
          'device_name': 'NovaPay Mobile',
          'device_type': 'MOBILE',
        },
      );

      final data = res.data as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>;
      final userMap = data['user'] as Map<String, dynamic>;

      await _client.saveTokens(
        accessToken: tokens['access_token'] ?? tokens['access'] ?? '',
        refreshToken: tokens['refresh_token'] ?? tokens['refresh'] ?? '',
      );

      _currentUser = UserModel.fromJson(userMap);
      await _client.saveUserProfile(userMap);
      await WalletApiService.instance.fetchPrimaryWallet();
      await TransactionApiService.instance.fetchTransactions();
      NotificationApiService.instance.fetchNotifications();
      NotificationApiService.instance.startPolling();
      BeneficiaryApiService.instance.fetchBeneficiaries();

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Connection error: Could not connect to API server.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle({
    required String email,
    String? fullName,
    String? googleId,
    String? profilePhoto,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _client.post(
        'auth/google/',
        requiresAuth: false,
        body: {
          'email': email.trim().toLowerCase(),
          'full_name': fullName?.trim() ?? '',
          'google_id': googleId ?? '',
          'profile_photo': profilePhoto ?? '',
        },
      );

      final data = res.data as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>;
      final userMap = data['user'] as Map<String, dynamic>;

      await _client.saveTokens(
        accessToken: tokens['access_token'] ?? tokens['access'] ?? '',
        refreshToken: tokens['refresh_token'] ?? tokens['refresh'] ?? '',
      );

      _currentUser = UserModel.fromJson(userMap);
      await _client.saveUserProfile(userMap);
      await WalletApiService.instance.fetchPrimaryWallet();
      await TransactionApiService.instance.fetchTransactions();
      NotificationApiService.instance.fetchNotifications();
      NotificationApiService.instance.startPolling();
      BeneficiaryApiService.instance.fetchBeneficiaries();

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Google sign-in error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String phoneNumber,
    required String fullName,
    required String password,
    String pin = '123456',
    String? gender,
    String? dateOfBirth,
    String? idDocumentType,
    String? idDocumentNumber,
    String? idDocumentPhotoBase64,
    String? profilePhotoBase64,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isPendingApproval = false;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'phone_number': phoneNumber.trim(),
        'full_name': fullName.trim(),
        'password': password,
        'pin': pin,
        'role': 'CUSTOMER',
      };
      if (gender != null && gender.isNotEmpty) {
        body['gender'] = gender;
      }
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        body['date_of_birth'] = dateOfBirth;
      }
      if (idDocumentType != null && idDocumentType.isNotEmpty) {
        body['id_document_type'] = idDocumentType;
      }
      if (idDocumentNumber != null && idDocumentNumber.isNotEmpty) {
        body['id_document_number'] = idDocumentNumber;
      }
      if (idDocumentPhotoBase64 != null && idDocumentPhotoBase64.isNotEmpty) {
        body['id_document_photo_base64'] = idDocumentPhotoBase64;
      }
      if (profilePhotoBase64 != null && profilePhotoBase64.isNotEmpty) {
        body['profile_photo_base64'] = profilePhotoBase64;
      }

      final res = await _client.post(
        'auth/register/',
        requiresAuth: false,
        body: body,
      );

      final data = res.data as Map<String, dynamic>;
      final isPending = data['pending_approval'] == true || data['tokens'] == null;
      _isPendingApproval = isPending;

      if (!isPending && data['tokens'] is Map<String, dynamic>) {
        final tokens = data['tokens'] as Map<String, dynamic>;
        final userMap = data['user'] as Map<String, dynamic>?;

        await _client.saveTokens(
          accessToken: tokens['access_token'] ?? tokens['access'] ?? '',
          refreshToken: tokens['refresh_token'] ?? tokens['refresh'] ?? '',
        );

        if (userMap != null) {
          _currentUser = UserModel.fromJson(userMap);
          await _client.saveUserProfile(userMap);
        }
        await WalletApiService.instance.fetchPrimaryWallet();
        await TransactionApiService.instance.fetchTransactions();
        NotificationApiService.instance.fetchNotifications();
        BeneficiaryApiService.instance.fetchBeneficiaries();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfilePhoto({
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      await _client.uploadFile(
        'users/me/profile-photo/',
        fileField: 'profile_photo',
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        requiresAuth: true,
      );
      await refreshProfile();
      return true;
    } catch (e) {
      debugPrint('Failed to upload profile photo: $e');
      return false;
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? gender,
    String? dateOfBirth,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName.trim();
      if (gender != null) body['gender'] = gender;
      if (dateOfBirth != null) body['date_of_birth'] = dateOfBirth;

      await _client.patch('users/me/', body: body);
      await refreshProfile();
      return true;
    } catch (e) {
      debugPrint('Failed to update profile: $e');
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final res = await _client.get('users/me/');
      if (res.data is Map<String, dynamic>) {
        _currentUser = UserModel.fromJson(res.data as Map<String, dynamic>);
        await _client.saveUserProfile(res.data as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      if (_client.refreshToken != null) {
        await _client.post(
          'auth/logout/',
          body: {'refresh_token': _client.refreshToken},
        );
      }
    } catch (_) {}

    await _client.clearAuth();
    _currentUser = null;
    _errorMessage = null;
    WalletApiService.instance.reset();
    TransactionApiService.instance.reset();
    NotificationApiService.instance.reset();
    BeneficiaryApiService.instance.reset();
    notifyListeners();
  }
}
