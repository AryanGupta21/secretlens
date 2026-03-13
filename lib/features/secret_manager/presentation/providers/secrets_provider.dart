import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/aws_api_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/background_sync_service.dart';

enum LoadStatus { idle, loading, success, error }

class SecretsState {
  final LoadStatus status;
  final List<StoredSecretItem> secrets;
  final String? error;
  final bool isConnected;
  final bool isPolling;
  final DateTime? lastRefreshed;
  final int? lastAuditCount;

  const SecretsState({
    this.status = LoadStatus.idle,
    this.secrets = const [],
    this.error,
    this.isConnected = false,
    this.isPolling = false,
    this.lastRefreshed,
    this.lastAuditCount,
  });

  SecretsState copyWith({
    LoadStatus? status,
    List<StoredSecretItem>? secrets,
    String? error,
    bool? isConnected,
    bool? isPolling,
    DateTime? lastRefreshed,
    int? lastAuditCount,
  }) {
    return SecretsState(
      status:         status        ?? this.status,
      secrets:        secrets       ?? this.secrets,
      error:          error,
      isConnected:    isConnected   ?? this.isConnected,
      isPolling:      isPolling     ?? this.isPolling,
      lastRefreshed:  lastRefreshed ?? this.lastRefreshed,
      lastAuditCount: lastAuditCount ?? this.lastAuditCount,
    );
  }
}

class SecretsNotifier extends StateNotifier<SecretsState> {
  final AwsApiService _api = AwsApiService();
  Timer? _pollTimer;

  SecretsNotifier() : super(const SecretsState()) {
    loadSecrets();
  }

  Future<void> loadSecrets() async {
    state = state.copyWith(status: LoadStatus.loading);
    try {
      final ok      = await _api.healthCheck();
      final secrets = await _api.listSecrets();
      state = state.copyWith(
        status:        LoadStatus.success,
        secrets:       secrets,
        isConnected:   ok,
        lastRefreshed: DateTime.now(),
        error:         null,
      );
    } catch (e) {
      state = state.copyWith(
          status:      LoadStatus.error,
          error:       e.toString(),
          isConnected: false);
    }
  }

  void startPolling() {
    if (state.isPolling) return;
    state = state.copyWith(isPolling: true);
    _pollTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _silentRefresh());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    state = state.copyWith(isPolling: false);
  }

  Future<void> _silentRefresh() async {
    try {
      final secrets    = await _api.listSecrets();
      final auditLogs  = await _api.getAuditLogs();
      final newCount   = auditLogs.length;
      final prevCount  = state.lastAuditCount ?? 0;

      if (state.lastAuditCount != null && newCount > prevCount) {
        await NotificationService.showAuditUpdate(
            newCount: newCount, prevCount: prevCount);

        if (auditLogs.isNotEmpty) {
          final latest = auditLogs.first;
          if (latest.operationType == 'store') {
            await NotificationService.showNewSecretStored(
              secretId:    latest.secretId,
              serviceName: latest.serviceName,
            );
          }
        }
        await BackgroundSyncService.updateLastKnownCount(newCount);
      }

      state = state.copyWith(
        secrets:        secrets,
        lastAuditCount: newCount,
        lastRefreshed:  DateTime.now(),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _api.dispose();
    super.dispose();
  }
}

final secretsProvider =
    StateNotifierProvider<SecretsNotifier, SecretsState>(
        (ref) => SecretsNotifier());
