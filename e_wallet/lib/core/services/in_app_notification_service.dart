import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Service to display real heads-up push notifications at the top of the screen.
class InAppNotificationService {
  InAppNotificationService._();
  static final InAppNotificationService instance = InAppNotificationService._();
  static GlobalKey<NavigatorState> get navigatorKey => appNavigatorKey;

  OverlayEntry? _currentEntry;
  String? _lastShownKey;
  DateTime? _lastShownTime;

  /// Display a real OS-style top notification banner.
  void show({
    required String title,
    required String message,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Prevent duplicate notification within 3 seconds
    final dedupeKey = '$title|$message';
    final now = DateTime.now();
    if (_lastShownKey == dedupeKey &&
        _lastShownTime != null &&
        now.difference(_lastShownTime!).inSeconds < 3) {
      return;
    }
    _lastShownKey = dedupeKey;
    _lastShownTime = now;

    // Remove any currently showing banner cleanly
    _dismissCurrentImmediately();

    final overlayState = appNavigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopNotificationBannerWidget(
        title: title,
        message: message,
        icon: icon ?? Icons.notifications_active_rounded,
        iconColor: iconColor ?? AppColors.primary,
        duration: duration,
        onTap: () {
          _dismissCurrentImmediately();
          if (onTap != null) {
            onTap();
          } else {
            // Default action: Open NotificationListScreen
            final navContext = appNavigatorKey.currentContext;
            if (navContext != null) {
              Navigator.of(navContext).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationListScreen(),
                ),
              );
            }
          }
        },
        onDismiss: () {
          if (_currentEntry == entry) {
            _dismissCurrentImmediately();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  void _dismissCurrentImmediately() {
    if (_currentEntry != null) {
      try {
        _currentEntry?.remove();
      } catch (_) {}
      _currentEntry = null;
    }
  }
}

class _TopNotificationBannerWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final Duration duration;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _TopNotificationBannerWidget({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.duration,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationBannerWidget> createState() =>
      _TopNotificationBannerWidgetState();
}

class _TopNotificationBannerWidgetState
    extends State<_TopNotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    _dismissTimer?.cancel();
    if (mounted) {
      _controller.reverse().then((_) {
        if (mounted) widget.onDismiss();
      });
    } else {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: true,
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () {
                      try {
                        HapticFeedback.selectionClick();
                      } catch (_) {}
                      _dismiss();
                      widget.onTap();
                    },
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta != null &&
                          details.primaryDelta! < -4) {
                        _dismiss();
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top grabber handle
                          Center(
                            child: Container(
                              width: 32,
                              height: 3.5,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white24 : Colors.black12,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          // Header: App badge, name, timestamp, close button
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'NOVAPAY',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '• Just now',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white54
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: _dismiss,
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Body: Icon + Title + Message
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: widget.iconColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: widget.iconColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      widget.message,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFF475569),
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
