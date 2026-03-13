import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/compliance_engine_service.dart';

export '../../../../core/services/compliance_engine_service.dart'
    show DocumentInfo, ComplianceRule, FindingResult, IngestResponse, EngineHealth;

// ── Enums ─────────────────────────────────────────────────────────────────────

enum EngineStatus { unknown, online, offline }

// ── State ─────────────────────────────────────────────────────────────────────

class ComplianceState {
  final EngineStatus engineStatus;
  final String engineVersion;

  // Documents
  final List<DocumentInfo> documents;
  final bool loadingDocuments;

  // Rules
  final List<ComplianceRule> rules;
  final bool loadingRules;
  final String severityFilter;
  final String categoryRuleFilter;

  // Upload
  final bool uploading;
  final IngestResponse? lastIngest;
  final String? uploadError;

  // Validate
  final bool validating;
  final List<FindingResult> findings;
  final bool validationRan;
  final String? validateError;

  const ComplianceState({
    this.engineStatus = EngineStatus.unknown,
    this.engineVersion = '',
    this.documents = const [],
    this.loadingDocuments = false,
    this.rules = const [],
    this.loadingRules = false,
    this.severityFilter = 'ALL',
    this.categoryRuleFilter = 'ALL',
    this.uploading = false,
    this.lastIngest,
    this.uploadError,
    this.validating = false,
    this.findings = const [],
    this.validationRan = false,
    this.validateError,
  });

  List<ComplianceRule> get filteredRules {
    return rules.where((r) {
      final bySev = severityFilter == 'ALL' ||
          r.severity.toUpperCase() == severityFilter;
      final byCat = categoryRuleFilter == 'ALL' ||
          r.category.toUpperCase() == categoryRuleFilter;
      return bySev && byCat;
    }).toList();
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ComplianceNotifier extends StateNotifier<ComplianceState> {
  final ComplianceEngineService _service;

  ComplianceNotifier(this._service) : super(const ComplianceState()) {
    _init();
  }

  Future<void> _init() async {
    await Future.wait([healthCheck(), loadDocuments(), loadRules()]);
  }

  Future<void> healthCheck() async {
    try {
      final health = await _service.healthCheck();
      state = ComplianceState(
        engineStatus: health.isHealthy ? EngineStatus.online : EngineStatus.offline,
        engineVersion: health.version,
        documents: state.documents,
        loadingDocuments: state.loadingDocuments,
        rules: state.rules,
        loadingRules: state.loadingRules,
        severityFilter: state.severityFilter,
        categoryRuleFilter: state.categoryRuleFilter,
        uploading: state.uploading,
        lastIngest: state.lastIngest,
        uploadError: state.uploadError,
        validating: state.validating,
        findings: state.findings,
        validationRan: state.validationRan,
        validateError: state.validateError,
      );
    } catch (_) {
      state = ComplianceState(
        engineStatus: EngineStatus.offline,
        engineVersion: state.engineVersion,
        documents: state.documents,
        loadingDocuments: state.loadingDocuments,
        rules: state.rules,
        loadingRules: state.loadingRules,
        severityFilter: state.severityFilter,
        categoryRuleFilter: state.categoryRuleFilter,
        uploading: state.uploading,
        lastIngest: state.lastIngest,
        uploadError: state.uploadError,
        validating: state.validating,
        findings: state.findings,
        validationRan: state.validationRan,
        validateError: state.validateError,
      );
    }
  }

  Future<void> loadDocuments() async {
    state = ComplianceState(
      engineStatus: state.engineStatus,
      engineVersion: state.engineVersion,
      documents: state.documents,
      loadingDocuments: true,
      rules: state.rules,
      loadingRules: state.loadingRules,
      severityFilter: state.severityFilter,
      categoryRuleFilter: state.categoryRuleFilter,
      uploading: state.uploading,
      lastIngest: state.lastIngest,
      validating: state.validating,
      findings: state.findings,
      validationRan: state.validationRan,
      validateError: state.validateError,
    );
    try {
      final docs = await _service.listDocuments();
      state = ComplianceState(
        engineStatus: state.engineStatus,
        engineVersion: state.engineVersion,
        documents: docs,
        loadingDocuments: false,
        rules: state.rules,
        loadingRules: state.loadingRules,
        severityFilter: state.severityFilter,
        categoryRuleFilter: state.categoryRuleFilter,
        uploading: state.uploading,
        lastIngest: state.lastIngest,
        uploadError: state.uploadError,
        validating: state.validating,
        findings: state.findings,
        validationRan: state.validationRan,
        validateError: state.validateError,
      );
    } catch (_) {
      state = ComplianceState(
        engineStatus: state.engineStatus,
        engineVersion: state.engineVersion,
        documents: state.documents,
        loadingDocuments: false,
        rules: state.rules,
        loadingRules: state.loadingRules,
        severityFilter: state.severityFilter,
        categoryRuleFilter: state.categoryRuleFilter,
        uploading: state.uploading,
        lastIngest: state.lastIngest,
        uploadError: state.uploadError,
        validating: state.validating,
        findings: state.findings,
        validationRan: state.validationRan,
        validateError: state.validateError,
      );
    }
  }

  Future<void> loadRules() async {
    state = ComplianceState(
      engineStatus: state.engineStatus,
      engineVersion: state.engineVersion,
      documents: state.documents,
      loadingDocuments: state.loadingDocuments,
      rules: state.rules,
      loadingRules: true,
      severityFilter: state.severityFilter,
      categoryRuleFilter: state.categoryRuleFilter,
      uploading: state.uploading,
      lastIngest: state.lastIngest,
      uploadError: state.uploadError,
      validating: state.validating,
      findings: state.findings,
      validationRan: state.validationRan,
      validateError: state.validateError,
    );
    try {
      final rules = await _service.listRules();
      state = ComplianceState(
        engineStatus: state.engineStatus,
        engineVersion: state.engineVersion,
        documents: state.documents,
        loadingDocuments: state.loadingDocuments,
        rules: rules,
        loadingRules: false,
        severityFilter: state.severityFilter,
        categoryRuleFilter: state.categoryRuleFilter,
        uploading: state.uploading,
        lastIngest: state.lastIngest,
        uploadError: state.uploadError,
        validating: state.validating,
        findings: state.findings,
        validationRan: state.validationRan,
        validateError: state.validateError,
      );
    } catch (_) {
      state = ComplianceState(
        engineStatus: state.engineStatus,
        engineVersion: state.engineVersion,
        documents: state.documents,
        loadingDocuments: state.loadingDocuments,
        rules: state.rules,
        loadingRules: false,
        severityFilter: state.severityFilter,
        categoryRuleFilter: state.categoryRuleFilter,
        uploading: state.uploading,
        lastIngest: state.lastIngest,
        uploadError: state.uploadError,
        validating: state.validating,
        findings: state.findings,
        validationRan: state.validationRan,
        validateError: state.validateError,
      );
    }
  }

  Future<void> ingestDocument(Uint8List bytes, String filename) async {
    state = ComplianceState(
      engineStatus: state.engineStatus,
      engineVersion: state.engineVersion,
      documents: state.documents,
      loadingDocuments: state.loadingDocuments,
      rules: state.rules,
      loadingRules: state.loadingRules,
      severityFilter: state.severityFilter,
      categoryRuleFilter: state.categoryRuleFilter,
      uploading: true,
      // clear previous result/error
      validating: state.validating,
      findings: state.findings,
      validationRan: state.validationRan,
      validateError: state.validateError,
    );
    try {
      final result = await _service.ingestDocument(bytes, filename);
      state = ComplianceState(
        engineStatus: state.engineStatus,
        engineVersion: state.engineVersion,
        documents: state.documents,
        loadingDocuments: state.loadingDocuments,
        rules: state.rules,
        loadingRules: state.loadingRules,
        severityFilter: state.severityFilter,
        categoryRuleFilter: state.categoryRuleFilter,
        uploading: false,
        lastIngest: result,
        validating: state.validating,
        findings: state.findings,
        validationRan: state.validationRan,
        validateError: state.validateError,
      );
      await Future.wait([loadDocuments(), loadRules()]);
    } catch (e) {
      state = ComplianceState(
        engineStatus: state.engineStatus,
        engineVersion: state.engineVersion,
        documents: state.documents,
        loadingDocuments: state.loadingDocuments,
        rules: state.rules,
        loadingRules: state.loadingRules,
        severityFilter: state.severityFilter,
        categoryRuleFilter: state.categoryRuleFilter,
        uploading: false,
        uploadError: e.toString().replaceAll('Exception: ', ''),
        validating: state.validating,
        findings: state.findings,
        validationRan: state.validationRan,
        validateError: state.validateError,
      );
    }
  }

  Future<void> validateCode(String filePath, String content) async {
    state = ComplianceState(
      engineStatus: state.engineStatus,
      engineVersion: state.engineVersion,
      documents: state.documents,
      loadingDocuments: state.loadingDocuments,
      rules: state.rules,
      loadingRules: state.loadingRules,
      severityFilter: state.severityFilter,
      categoryRuleFilter: state.categoryRuleFilter,
      uploading: state.uploading,
      lastIngest: state.lastIngest,
      uploadError: state.uploadError,
      validating: true,
      findings: const [],
      validationRan: false,
    );
    try {
      final findings = await _service.validateCode(filePath, content);
      state = ComplianceState(
        engineStatus: state.engineStatus,
        engineVersion: state.engineVersion,
        documents: state.documents,
        loadingDocuments: state.loadingDocuments,
        rules: state.rules,
        loadingRules: state.loadingRules,
        severityFilter: state.severityFilter,
        categoryRuleFilter: state.categoryRuleFilter,
        uploading: state.uploading,
        lastIngest: state.lastIngest,
        uploadError: state.uploadError,
        validating: false,
        findings: findings,
        validationRan: true,
      );
    } catch (e) {
      state = ComplianceState(
        engineStatus: state.engineStatus,
        engineVersion: state.engineVersion,
        documents: state.documents,
        loadingDocuments: state.loadingDocuments,
        rules: state.rules,
        loadingRules: state.loadingRules,
        severityFilter: state.severityFilter,
        categoryRuleFilter: state.categoryRuleFilter,
        uploading: state.uploading,
        lastIngest: state.lastIngest,
        uploadError: state.uploadError,
        validating: false,
        findings: const [],
        validationRan: true,
        validateError: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setSeverityFilter(String f) {
    state = ComplianceState(
      engineStatus: state.engineStatus,
      engineVersion: state.engineVersion,
      documents: state.documents,
      loadingDocuments: state.loadingDocuments,
      rules: state.rules,
      loadingRules: state.loadingRules,
      severityFilter: f,
      categoryRuleFilter: state.categoryRuleFilter,
      uploading: state.uploading,
      lastIngest: state.lastIngest,
      uploadError: state.uploadError,
      validating: state.validating,
      findings: state.findings,
      validationRan: state.validationRan,
      validateError: state.validateError,
    );
  }

  void setCategoryRuleFilter(String f) {
    state = ComplianceState(
      engineStatus: state.engineStatus,
      engineVersion: state.engineVersion,
      documents: state.documents,
      loadingDocuments: state.loadingDocuments,
      rules: state.rules,
      loadingRules: state.loadingRules,
      severityFilter: state.severityFilter,
      categoryRuleFilter: f,
      uploading: state.uploading,
      lastIngest: state.lastIngest,
      uploadError: state.uploadError,
      validating: state.validating,
      findings: state.findings,
      validationRan: state.validationRan,
      validateError: state.validateError,
    );
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final complianceEngineServiceProvider =
    Provider((_) => ComplianceEngineService());

final complianceProvider =
    StateNotifierProvider<ComplianceNotifier, ComplianceState>(
  (ref) => ComplianceNotifier(ref.watch(complianceEngineServiceProvider)),
);
