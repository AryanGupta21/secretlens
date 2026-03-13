import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around flutter_local_notifications.
///
/// Call [NotificationService.init] once at app start.
/// Then call [NotificationService.showSecretAlert] / [showNewSecretStored]
/// from anywhere — including the background isolate.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Notification channel IDs
  static const String _channelId = 'secretlens_secrets';
  static const String _channelName = 'AWS Secrets Updates';
  static const String _channelDesc =
      'Alerts when secrets are added or changed in AWS Secrets Manager';

  // Notification IDs
  static const int _newSecretId = 1001;
  static const int _auditUpdateId = 1002;

  /// Call once in [main] before [runApp].
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );

    // Create the Android notification channel (no-op on other platforms)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
  }

  /// Request notification permission (Android 13+ / iOS).
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  // ── Public notification helpers ──────────────────────────────────────────

  /// Show when a brand-new secret is stored in AWS Secrets Manager.
  static Future<void> showNewSecretStored({
    required String secretId,
    required String serviceName,
  }) async {
    await _plugin.show(
      _newSecretId,
      '🔐 New Secret Stored',
      '$serviceName → $secretId saved to AWS Secrets Manager',
      _buildDetails(),
    );
  }

  /// Show when the audit log count increases (background poll).
  static Future<void> showAuditUpdate({
    required int newCount,
    required int prevCount,
  }) async {
    final delta = newCount - prevCount;
    await _plugin.show(
      _auditUpdateId,
      '📋 Secrets Manager Updated',
      '$delta new operation${delta == 1 ? '' : 's'} detected in audit log',
      _buildDetails(),
    );
  }

  /// Generic alert (used by background isolate).
  static Future<void> showAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(id, title, body, _buildDetails());
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  static NotificationDetails _buildDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4D9FFF), // AppColors.info
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
