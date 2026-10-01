import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../network/api_client.dart';
import 'in_app_notification_service.dart';

class PendingApprovalUser {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String idDocumentType;
  final String idDocumentNumber;
  final String? idDocumentPhoto;
  final String? profilePhoto;
  final String gender;
  final String dateOfBirth;
  final String createdAt;

  const PendingApprovalUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.idDocumentType,
    required this.idDocumentNumber,
    this.idDocumentPhoto,
    this.profilePhoto,
    this.gender = '',
    this.dateOfBirth = '',
    this.createdAt = '',
  });

  String get documentDisplay =>
      idDocumentType == 'PASSPORT' ? 'Passport' : 'National ID';

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'ID';
  }

  String? get resolvedDocumentPhotoUrl {
    if (idDocumentPhoto == null || idDocumentPhoto!.isEmpty) return null;
    var url = idDocumentPhoto!;
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid && (url.contains('127.0.0.1') || url.contains('localhost'))) {
          url = url.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2');
        }
      } catch (_) {}
    }
    return url;
  }

  String? get resolvedProfilePhotoUrl {
    if (profilePhoto == null || profilePhoto!.isEmpty) return null;
    var url = profilePhoto!;
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid && (url.contains('127.0.0.1') || url.contains('localhost'))) {
          url = url.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2');
        }
      } catch (_) {}
    }
    return url;
  }

  factory PendingApprovalUser.fromJson(Map<String, dynamic> json) =>
      PendingApprovalUser(
        id: json['id']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? 'Pending User',
        email: json['email']?.toString() ?? '',
        phoneNumber: json['phone_number']?.toString() ?? '',
        idDocumentType: json['id_document_type']?.toString() ?? 'NATIONAL_ID',
        idDocumentNumber: json['id_document_number']?.toString() ?? '',
        idDocumentPhoto: json['id_document_photo']?.toString(),
        profilePhoto: json['profile_photo']?.toString(),
        gender: json['gender']?.toString() ?? '',
        dateOfBirth: json['date_of_birth']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
      );
}

class AccountApprovalService extends ChangeNotifier {
  AccountApprovalService._();
  static final AccountApprovalService instance = AccountApprovalService._();

  final ApiClient _client = ApiClient.instance;

  List<PendingApprovalUser> _pendingUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PendingApprovalUser> get pendingUsers => _pendingUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get pendingCount => _pendingUsers.length;

  Future<List<PendingApprovalUser>> fetchPendingApprovals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _client.get('users/admin/pending-approvals/');
      if (res.data is List) {
        _pendingUsers = (res.data as List)
            .map((item) => PendingApprovalUser.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Could not load pending accounts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _pendingUsers;
  }

  Future<bool> approveUser(PendingApprovalUser user) async {
    try {
      await _client.post('users/admin/users/${user.id}/approve/');
      _pendingUsers.removeWhere((u) => u.id == user.id);
      notifyListeners();

      InAppNotificationService.instance.show(
        title: 'Account Approved! 🎉',
        message: 'Account for ${user.fullName} has been approved and activated.',
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF00D09C),
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Approval failed: $e';
      return false;
    }
  }

  Future<bool> rejectUser(PendingApprovalUser user, [String? reason]) async {
    try {
      await _client.post(
        'users/admin/users/${user.id}/reject/',
        body: {'reason': reason ?? 'Document verification could not be completed.'},
      );
      _pendingUsers.removeWhere((u) => u.id == user.id);
      notifyListeners();

      InAppNotificationService.instance.show(
        title: 'Account Registration Rejected',
        message: 'Registration for ${user.fullName} has been rejected.',
        icon: Icons.cancel_outlined,
        iconColor: Colors.redAccent,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Rejection failed: $e';
      return false;
    }
  }
}
