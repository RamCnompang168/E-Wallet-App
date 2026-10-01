import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../data/notification_api_service.dart';

class _NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  bool isRead;

  _NotificationItem({
    required this.id,
    required this.title,
    this.message = '',
    required this.time,
    this.icon = Icons.notifications_none_rounded,
    this.iconColor = AppColors.yellow,
    this.isRead = false,
  });
}

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  bool _allRead = false;
  List<_NotificationItem> _notifications = [
    _NotificationItem(id: '1', title: 'Payment received from Thida', time: '1h ago', icon: Icons.south_west_rounded, iconColor: const Color(0xFF00D09C)),
    _NotificationItem(id: '2', title: 'Security: new device sign-in', time: '1h ago', icon: Icons.shield_outlined, iconColor: Colors.amber),
    _NotificationItem(id: '3', title: 'Your cash deposit is complete', time: '1h ago', icon: Icons.south_west_rounded, iconColor: const Color(0xFF00D09C)),
  ];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    NotificationApiService.instance.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    NotificationApiService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (!mounted || !ApiClient.instance.isAuthenticated) return;
    _populateFromService();
  }

  void _populateFromService() {
    final apiList = NotificationApiService.instance.notifications;
    if (apiList.isNotEmpty || ApiClient.instance.isAuthenticated) {
      setState(() {
        _notifications = apiList.map((item) {
          return _NotificationItem(
            id: item.id,
            title: item.title,
            message: item.message,
            time: item.formattedTime,
            icon: item.icon,
            iconColor: item.iconColor,
            isRead: item.isRead,
          );
        }).toList();
        _allRead = _notifications.isEmpty || _notifications.every((n) => n.isRead);
      });
    }
  }

  Future<void> _fetchNotifications() async {
    if (!ApiClient.instance.isAuthenticated) return;
    await NotificationApiService.instance.fetchNotifications();
    if (mounted) {
      _populateFromService();
    }
  }

  Future<void> _markAllRead() async {
    setState(() {
      _allRead = true;
      for (final n in _notifications) {
        n.isRead = true;
      }
    });

    if (ApiClient.instance.isAuthenticated) {
      await NotificationApiService.instance.markAllAsRead();
    }
  }

  Future<void> _openNotification(_NotificationItem notification) async {
    setState(() {
      notification.isRead = true;
      if (_notifications.every((n) => n.isRead)) {
        _allRead = true;
      }
    });

    if (ApiClient.instance.isAuthenticated && notification.id.length > 5) {
      await NotificationApiService.instance.markAsRead(notification.id);
    }

    if (!mounted) return;
    if (notification.message.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: notification.iconColor.withValues(alpha: 0.15),
                child: Icon(notification.icon, color: notification.iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  notification.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 14),
              Text(
                notification.time,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opened: ${notification.title}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [
        TextButton(
          onPressed: _allRead ? null : _markAllRead,
          child: Text(_allRead ? 'All caught up' : 'Mark all read'),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: _notifications.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 54, color: AppColors.muted),
                      SizedBox(height: 14),
                      Text(
                        'No notifications yet',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Alerts for your deposits, withdrawals, and transfers will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView(
              children: _notifications
                  .map(
                    (notification) => ListTile(
                      onTap: () => _openNotification(notification),
                      leading: CircleAvatar(
                        backgroundColor: (_allRead || notification.isRead)
                            ? AppColors.surfaceRaised
                            : notification.iconColor.withValues(alpha: 0.18),
                        child: Icon(
                          notification.icon,
                          color: (_allRead || notification.isRead) ? Colors.white70 : notification.iconColor,
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: (_allRead || notification.isRead)
                              ? FontWeight.w500
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (notification.message.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 2),
                              child: Text(
                                notification.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          Text(
                            (_allRead || notification.isRead) ? 'Read' : notification.time,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      trailing: (!_allRead && !notification.isRead)
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00D09C),
                              ),
                            )
                          : null,
                    ),
                  )
                  .toList(),
            ),
    ),
  );
}
