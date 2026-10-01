import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/in_app_notification_service.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String notificationType;
  final String? transactionCode;
  bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    this.transactionCode,
    this.isRead = false,
    this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    if (json['created_at'] != null) {
      created = DateTime.tryParse(json['created_at'].toString());
    }

    DateTime? read;
    if (json['read_at'] != null) {
      read = DateTime.tryParse(json['read_at'].toString());
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      notificationType: json['notification_type']?.toString() ?? 'TRANSACTION',
      transactionCode: json['transaction_code']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: created,
      readAt: read,
    );
  }

  String get formattedTime {
    if (createdAt == null) return 'Recently';
    final now = DateTime.now().toUtc();
    final diff = now.difference(createdAt!.toUtc());

    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt!.year}-${createdAt!.month.toString().padLeft(2, '0')}-${createdAt!.day.toString().padLeft(2, '0')}';
  }

  IconData get icon {
    final lowerTitle = title.toLowerCase();
    final lowerMsg = message.toLowerCase();
    if (lowerTitle.contains('deposit') || lowerMsg.contains('deposited')) {
      return Icons.south_west_rounded;
    }
    if (lowerTitle.contains('withdraw') || lowerMsg.contains('withdrew')) {
      return Icons.north_east_rounded;
    }
    if (lowerTitle.contains('received') || lowerMsg.contains('received')) {
      return Icons.south_west_rounded;
    }
    if (lowerTitle.contains('transfer') || lowerMsg.contains('transferred')) {
      return Icons.swap_horiz_rounded;
    }
    if (notificationType == 'SECURITY') {
      return Icons.shield_outlined;
    }
    return Icons.notifications_none_rounded;
  }

  Color get iconColor {
    final lowerTitle = title.toLowerCase();
    final lowerMsg = message.toLowerCase();
    if (lowerTitle.contains('deposit') || lowerMsg.contains('deposited') || lowerTitle.contains('received')) {
      return const Color(0xFF00D09C);
    }
    if (lowerTitle.contains('withdraw') || lowerMsg.contains('withdrew')) {
      return Colors.redAccent;
    }
    if (lowerTitle.contains('transfer') || lowerMsg.contains('transferred')) {
      return const Color(0xFF6366F1);
    }
    if (notificationType == 'SECURITY') {
      return Colors.amber;
    }
    return const Color(0xFF00D09C);
  }
}

class NotificationApiService extends ChangeNotifier {
  NotificationApiService._();
  static final NotificationApiService instance = NotificationApiService._();

  final ApiClient _client = ApiClient.instance;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  final Set<String> _seenNotificationIds = {};
  bool _initialFetchCompleted = false;
  Timer? _pollingTimer;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void startPolling({Duration interval = const Duration(seconds: 12)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) {
      if (_client.isAuthenticated) {
        fetchNotifications();
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void markSeenLocally(String id) {
    _seenNotificationIds.add(id);
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    if (!_client.isAuthenticated) {
      return _notifications;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _client.get('notifications/');
      dynamic listData;
      int? reportedUnread;

      if (res.data is Map<String, dynamic>) {
        final map = res.data as Map<String, dynamic>;
        if (map['data'] is Map<String, dynamic>) {
          final dataMap = map['data'] as Map<String, dynamic>;
          listData = dataMap['results'];
          reportedUnread = dataMap['unread_count'] as int?;
        } else if (map['results'] is List) {
          listData = map['results'];
          reportedUnread = map['unread_count'] as int?;
        }
      } else if (res.data is List) {
        listData = res.data;
      }

      if (listData is List) {
        final fetched = listData
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();

        if (!_initialFetchCompleted) {
          // On first launch or login, mark all existing items as seen so we don't spam old notifications
          for (final n in fetched) {
            _seenNotificationIds.add(n.id);
          }
          _initialFetchCompleted = true;
        } else {
          // Find any new notifications not yet seen and unread
          final unseen = fetched
              .where((n) => !_seenNotificationIds.contains(n.id) && !n.isRead)
              .toList();

          for (final n in unseen) {
            _seenNotificationIds.add(n.id);
          }

          // Trigger top notification banner for the newest unseen notification
          if (unseen.isNotEmpty) {
            final latest = unseen.first;
            InAppNotificationService.instance.show(
              title: latest.title,
              message: latest.message,
              icon: latest.icon,
              iconColor: latest.iconColor,
            );
          }
        }

        _notifications = fetched;
        _unreadCount = reportedUnread ?? _notifications.where((n) => !n.isRead).length;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      // Offline fallback
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _notifications;
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx].isRead = true;
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }

    if (_client.isAuthenticated && id.length > 5) {
      try {
        await _client.patch('notifications/$id/read/');
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    _unreadCount = 0;
    notifyListeners();

    if (_client.isAuthenticated) {
      try {
        await _client.patch('notifications/read-all/');
      } catch (_) {}
    }
  }

  void reset() {
    stopPolling();
    _seenNotificationIds.clear();
    _initialFetchCompleted = false;
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
