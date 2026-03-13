import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Task names — must be stable strings (used as WorkManager task IDs)
// ─────────────────────────────────────────────────────────────────────────────

const _kAuditPollTask = 'secretlens.auditPoll';
const _kSecretsCountKey = 'secretlens_last_audit_count';
const _kBaseUrl = 'https://code-gaurd.onrender.com';

// ─────────────────────────────────────────────────────────────────────────────
// Top-level callback — runs in a separate Dart isolate.
// Must be a top-level function (not a class method).
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == _kAuditPollTask) {
      await _runAuditPoll();
    }
    return Future.value(true);
  });
}

/// Fetches the audit log, compares against the persisted count,
/// and fires a local notification if new operations have appeared.
Future<void> _runAuditPoll() async {
  try {
    final res = await http
        .get(
          Uri.parse('$_kBaseUrl/api/v1/secrets-audit/all'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) return;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final currentCount = (data['total'] as int?) ?? 0;

    final prefs = await SharedPreferences.getInstance();
    final lastCount = prefs.getInt(_kSecretsCountKey) ?? 0;

    if (currentCount > lastCount) {
      // Initialise notifications in the background isolate
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      await plugin.show(
        2001,
        '📋 Secrets Manager Updated',
        '${currentCount - lastCount} new operation${(currentCount - lastCount) == 1 ? '' : 's'} in AWS Secrets Manager',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'secretlens_secrets',
            'AWS Secrets Updates',
            channelDescription:
                'Alerts when secrets are added or changed in AWS Secrets Manager',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      // Also check for new secret names and mention the latest one
      final ops = data['operations'] as List<dynamic>? ?? [];
      if (ops.isNotEmpty) {
        final latest = ops.first as Map<String, dynamic>;
        final secretId = latest['secret_id'] as String? ?? '';
        final service = latest['service_name'] as String? ?? '';
        if (secretId.isNotEmpty) {
          await plugin.show(
            2002,
            '🔐 Latest: $service',
            '$secretId stored in AWS Secrets Manager',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'secretlens_secrets',
                'AWS Secrets Updates',
                channelDescription:
                    'Alerts when secrets are added or changed in AWS Secrets Manager',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentSound: false,
              ),
            ),
          );
        }
      }
    }

    // Always persist the latest count
    await prefs.setInt(_kSecretsCountKey, currentCount);
  } catch (_) {
    // Silently swallow — background tasks must not crash
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API — call from main.dart
// ─────────────────────────────────────────────────────────────────────────────

class BackgroundSyncService {
  BackgroundSyncService._();

  /// Initialise workmanager and register the periodic audit-poll task.
  /// Safe to call multiple times — workmanager deduplicates by task name.
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Minimum period is 15 minutes on both Android and iOS (OS enforced).
    // This covers the "app closed" notification case.
    await Workmanager().registerPeriodicTask(
      _kAuditPollTask,
      _kAuditPollTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }

  /// Persist the current audit count so the background task has a baseline.
  /// Call this whenever you receive a fresh audit count from the API.
  static Future<void> updateLastKnownCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSecretsCountKey, count);
  }

  /// Read the persisted baseline count (used for in-app diff).
  static Future<int> getLastKnownCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kSecretsCountKey) ?? 0;
  }
}
