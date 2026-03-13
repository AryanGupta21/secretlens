import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../commit_block/data/datasources/secrets_api_datasource.dart';

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

  final ExplorerTab activeTab;

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
    this.activeTab = ExplorerTab.secrets,
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
    ExplorerTab? activeTab,
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
      activeTab: activeTab ?? this.activeTab,
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

  BackendExplorerNotifier(this._api) : super(const BackendExplorerState()) {
    // Auto-run health check and load secrets on creation
    checkHealthAndLoad();
  }

  // ── Tab ──────────────────────────────────────────────────────────────────

  void selectTab(ExplorerTab tab) {
    state = state.copyWith(activeTab: tab);
    if (tab == ExplorerTab.audit &&
        state.auditStatus == LoadStatus.idle) {
      loadAuditLogs();
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
      await loadSecrets();
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
        // Pre-select first secret for generate tab
        selectedSecretId: state.selectedSecretId ?? (list.isNotEmpty ? list.first.name : null),
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
      state = state.copyWith(
        auditStatus: LoadStatus.success,
        auditLogs: logs,
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
