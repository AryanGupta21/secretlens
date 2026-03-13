import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/commit_block/data/datasources/secrets_api_datasource.dart';
import '../../../../../core/services/background_sync_service.dart';
import '../../../../../core/services/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum ExplorerTab { secrets, audit, generate }

enum LoadStatus { idle, loading, success, error }

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class BackendExplorerState {
  final bool? isConnected; // null = not checked yet
  final LoadStatus healthStatus;

  final LoadStatus secretsStatus;
  final List<StoredSecretItem> secrets;
  final String? secretsError;

  final LoadStatus auditStatus;
  final List<AuditLogItem> auditLogs;
  final String? auditError;
  final int? lastAuditCount; // persisted baseline for diff

  final ExplorerTab activeTab;

  // Live-poll indicator — pulses while auto-refresh is ticking
  final bool isPolling;
  final DateTime? lastRefreshed;

  // Generate-code tab state
  final String? selectedSecretId;
  final String selectedLanguage;
  final LoadStatus generateStatus;
  final String? generatedCode;
  final String? generateError;
  final bool codeCopied;

  const BackendExplorerState({
    this.isConnected,
    this.healthStatus = LoadStatus.idle,
    this.secretsStatus = LoadStatus.idle,
    this.secrets = const [],
    this.secretsError,
    this.auditStatus = LoadStatus.idle,
    this.auditLogs = const [],
    this.auditError,
    this.lastAuditCount,
    this.activeTab = ExplorerTab.secrets,
    this.isPolling = false,
    this.lastRefreshed,
    this.selectedSecretId,
    this.selectedLanguage = 'python',
    this.generateStatus = LoadStatus.idle,
    this.generatedCode,
    this.generateError,
    this.codeCopied = false,
  });

  BackendExplorerState copyWith({
    bool? isConnected,
    LoadStatus? healthStatus,
    LoadStatus? secretsStatus,
    List<StoredSecretItem>? secrets,
    String? secretsError,
    bool clearSecretsError = false,
    LoadStatus? auditStatus,
    List<AuditLogItem>? auditLogs,
    String? auditError,
    bool clearAuditError = false,
    int? lastAuditCount,
    ExplorerTab? activeTab,
    bool? isPolling,
    DateTime? lastRefreshed,
    String? selectedSecretId,
    bool clearSelectedSecret = false,
    String? selectedLanguage,
    LoadStatus? generateStatus,
    String? generatedCode,
    bool clearGeneratedCode = false,
    String? generateError,
    bool clearGenerateError = false,
    bool? codeCopied,
  }) {
    return BackendExplorerState(
      isConnected: isConnected ?? this.isConnected,
      healthStatus: healthStatus ?? this.healthStatus,
      secretsStatus: secretsStatus ?? this.secretsStatus,
      secrets: secrets ?? this.secrets,
      secretsError:
          clearSecretsError ? null : (secretsError ?? this.secretsError),
      auditStatus: auditStatus ?? this.auditStatus,
      auditLogs: auditLogs ?? this.auditLogs,
      auditError: clearAuditError ? null : (auditError ?? this.auditError),
      lastAuditCount: lastAuditCount ?? this.lastAuditCount,
      activeTab: activeTab ?? this.activeTab,
      isPolling: isPolling ?? this.isPolling,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      selectedSecretId: clearSelectedSecret
          ? null
          : (selectedSecretId ?? this.selectedSecretId),
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      generateStatus: generateStatus ?? this.generateStatus,
      generatedCode: clearGeneratedCode
          ? null
          : (generatedCode ?? this.generatedCode),
      generateError: clearGenerateError
          ? null
          : (generateError ?? this.generateError),
      codeCopied: codeCopied ?? this.codeCopied,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class BackendExplorerNotifier
    extends StateNotifier<BackendExplorerState> {
  final SecretsApiDatasource _api;
  Timer? _pollTimer;

  // How often to auto-refresh while the screen is open
  static const Duration _pollInterval = Duration(seconds: 4);

  BackendExplorerNotifier(this._api) : super(const BackendExplorerState()) {
    checkHealthAndLoad();
  }

  // ── Tab ──────────────────────────────────────────────────────────────────

  void selectTab(ExplorerTab tab) {
    state = state.copyWith(activeTab: tab);
    if (tab == ExplorerTab.audit && state.auditStatus == LoadStatus.idle) {
      loadAuditLogs();
    }
  }

  // ── Polling control ───────────────────────────────────────────────────────

  /// Start the 4-second in-app polling loop.
  /// Call from the screen's [initState] / [didChangeDependencies].
  void startPolling() {
    if (_pollTimer?.isActive ?? false) return;
    state = state.copyWith(isPolling: true);
    _pollTimer = Timer.periodic(_pollInterval, (_) => _silentRefresh());
  }

  /// Stop polling (e.g. when the screen is disposed or backgrounded).
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (mounted) state = state.copyWith(isPolling: false);
  }

  /// Silent background refresh — no loading spinner, just diffs and notifies.
  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      // Refresh both secrets and audit in parallel
      final results = await Future.wait([
        _api.listSecrets(),
        _api.getAuditLogs(),
      ]);

      if (!mounted) return;

      final newSecrets = results[0] as List<StoredSecretItem>;
      final newAudit = results[1] as List<AuditLogItem>;
      final newAuditCount = newAudit.length;
      final prevCount = state.lastAuditCount ?? newAuditCount;

      // Detect newly stored secrets since last poll
      if (prevCount > 0 && newAuditCount > prevCount) {
        final delta = newAuditCount - prevCount;
        // Show in-app notification banner
        await NotificationService.showAuditUpdate(
          newCount: newAuditCount,
          prevCount: prevCount,
        );
        // If the newest operation is a store, call out the secret name
        if (newAudit.isNotEmpty) {
          final latest = newAudit.first;
          if (latest.operationType.contains('store')) {
            await NotificationService.showNewSecretStored(
              secretId: latest.secretId,
              serviceName: latest.serviceName,
            );
          }
        }
        // Keep background task baseline in sync
        await BackgroundSyncService.updateLastKnownCount(newAuditCount);

        // Print debug info (visible in flutter logs)
        // ignore: avoid_print
        print('[SecretLens] $delta new audit operation(s) detected');
      }

      state = state.copyWith(
        secrets: newSecrets,
        secretsStatus: LoadStatus.success,
        auditLogs: newAudit,
        auditStatus: LoadStatus.success,
        lastAuditCount: newAuditCount,
        lastRefreshed: DateTime.now(),
        selectedSecretId: state.selectedSecretId ??
            (newSecrets.isNotEmpty ? newSecrets.first.name : null),
      );
    } catch (_) {
      // Don't surface poll errors — just skip this tick
    }
  }

  // ── Health + initial load ─────────────────────────────────────────────────

  Future<void> checkHealthAndLoad() async {
    state = state.copyWith(healthStatus: LoadStatus.loading);
    final healthy = await _api.healthCheck();
    state = state.copyWith(
      isConnected: healthy,
      healthStatus: healthy ? LoadStatus.success : LoadStatus.error,
    );
    if (healthy) {
      await Future.wait([loadSecrets(), loadAuditLogs()]);
    }
  }

  // ── Secrets ───────────────────────────────────────────────────────────────

  Future<void> loadSecrets() async {
    state = state.copyWith(
      secretsStatus: LoadStatus.loading,
      clearSecretsError: true,
    );
    try {
      final list = await _api.listSecrets();
      state = state.copyWith(
        secretsStatus: LoadStatus.success,
        secrets: list,
        selectedSecretId:
            state.selectedSecretId ?? (list.isNotEmpty ? list.first.name : null),
      );
    } catch (e) {
      state = state.copyWith(
        secretsStatus: LoadStatus.error,
        secretsError: e.toString(),
      );
    }
  }

  // ── Audit ─────────────────────────────────────────────────────────────────

  Future<void> loadAuditLogs() async {
    state = state.copyWith(
      auditStatus: LoadStatus.loading,
      clearAuditError: true,
    );
    try {
      final logs = await _api.getAuditLogs();
      final count = logs.length;
      // Seed background task baseline on first load
      final stored = await BackgroundSyncService.getLastKnownCount();
      if (stored == 0 && count > 0) {
        await BackgroundSyncService.updateLastKnownCount(count);
      }
      state = state.copyWith(
        auditStatus: LoadStatus.success,
        auditLogs: logs,
        lastAuditCount: count,
      );
    } catch (e) {
      state = state.copyWith(
        auditStatus: LoadStatus.error,
        auditError: e.toString(),
      );
    }
  }

  // ── Generate code ─────────────────────────────────────────────────────────

  void selectSecret(String secretId) {
    state = state.copyWith(
      selectedSecretId: secretId,
      clearGeneratedCode: true,
      clearGenerateError: true,
    );
  }

  void selectLanguage(String language) {
    state = state.copyWith(
      selectedLanguage: language,
      clearGeneratedCode: true,
      clearGenerateError: true,
    );
  }

  Future<void> generateCode() async {
    final secretId = state.selectedSecretId;
    if (secretId == null) return;

    state = state.copyWith(
      generateStatus: LoadStatus.loading,
      clearGeneratedCode: true,
      clearGenerateError: true,
    );

    try {
      final result = await _api.generateCode(
        secretId: secretId,
        language: state.selectedLanguage,
      );
      state = state.copyWith(
        generateStatus: LoadStatus.success,
        generatedCode: result.code,
      );
    } catch (e) {
      state = state.copyWith(
        generateStatus: LoadStatus.error,
        generateError: e.toString(),
      );
    }
  }

  void markCodeCopied() async {
    state = state.copyWith(codeCopied: true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      state = state.copyWith(codeCopied: false);
    }
  }

  @override
  void dispose() {
    stopPolling();
    _api.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final backendExplorerProvider =
    StateNotifierProvider<BackendExplorerNotifier, BackendExplorerState>(
  (ref) => BackendExplorerNotifier(SecretsApiDatasource()),
);
