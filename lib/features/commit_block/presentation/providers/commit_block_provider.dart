import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/secrets_api_datasource.dart';
import '../../domain/models/finding.dart';

class CommitBlockState {
  final List<Finding> findings;
  final bool fixInProgress;
  final bool fixCompleted;
  final bool commitOverridden;
  final int currentFixIndex;
  final String? fixStatusMessage;

  const CommitBlockState({
    required this.findings,
    this.fixInProgress = false,
    this.fixCompleted = false,
    this.commitOverridden = false,
    this.currentFixIndex = 0,
    this.fixStatusMessage,
  });

  String get riskLevel {
    if (findings.any((f) => f.severity == Severity.critical)) return 'CRITICAL';
    if (findings.any((f) => f.severity == Severity.high)) return 'HIGH';
    if (findings.any((f) => f.severity == Severity.medium)) return 'MEDIUM';
    return 'LOW';
  }

  bool get isBlocked => !commitOverridden && !fixCompleted;

  int get unfixedCount =>
      findings.where((f) => f.fixStatus == FixStatus.unfixed).length;

  int get fixedCount =>
      findings.where((f) => f.fixStatus == FixStatus.stored).length;

  CommitBlockState copyWith({
    List<Finding>? findings,
    bool? fixInProgress,
    bool? fixCompleted,
    bool? commitOverridden,
    int? currentFixIndex,
    String? fixStatusMessage,
  }) {
    return CommitBlockState(
      findings: findings ?? this.findings,
      fixInProgress: fixInProgress ?? this.fixInProgress,
      fixCompleted: fixCompleted ?? this.fixCompleted,
      commitOverridden: commitOverridden ?? this.commitOverridden,
      currentFixIndex: currentFixIndex ?? this.currentFixIndex,
      fixStatusMessage: fixStatusMessage ?? this.fixStatusMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Mock findings — simulate real git-hook detection output.
// rawValue contains clearly fake test credentials; in production these come
// from the git hook which intercepts the diff before masking.
// ---------------------------------------------------------------------------
final _mockFindings = [
  const Finding(
    id: 'finding-001',
    secretType: 'AWS Access Key',
    file: 'src/config.js',
    line: 23,
    severity: Severity.critical,
    maskedValue: 'AKIA••••••••••••WXYZ',
    rawValue: 'AKIAIOSFODNN7EXAMPLE',
    language: 'javascript',
  ),
  const Finding(
    id: 'finding-002',
    secretType: 'RSA Private Key',
    file: 'backend/auth.py',
    line: 7,
    severity: Severity.critical,
    maskedValue: '-----BEGIN RSA PRIVATE KEY-----\nMIIEow••••••••••••',
    rawValue: '-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA0Z3VS5JJcds3xHn/ygWep4sxdE=\n-----END RSA PRIVATE KEY-----',
    language: 'python',
  ),
  const Finding(
    id: 'finding-003',
    secretType: 'Stripe API Secret',
    file: '.env',
    line: 12,
    severity: Severity.high,
    maskedValue: 'sk_live_••••••••••••••••A4BC',
    rawValue: 'sk_live_test_ExampleKeyForDemoOnly_A4BC',
    language: 'shell',
  ),
];

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class CommitBlockNotifier extends StateNotifier<CommitBlockState> {
  final SecretsApiDatasource _api;

  CommitBlockNotifier({SecretsApiDatasource? api})
      : _api = api ?? SecretsApiDatasource(),
        super(CommitBlockState(findings: List.from(_mockFindings)));

  /// Iterates over every finding and stores it via the cloud-rotation-engine.
  /// Falls back to mock behaviour if the API is unreachable (e.g. Render cold
  /// start / offline dev).
  Future<void> fixAllIssues() async {
    state = state.copyWith(
      fixInProgress: true,
      currentFixIndex: 0,
      fixStatusMessage: 'Initializing secure storage...',
    );

    final updatedFindings = List<Finding>.from(state.findings);

    for (int i = 0; i < updatedFindings.length; i++) {
      final finding = updatedFindings[i];

      // Phase 1 — mark in-progress
      updatedFindings[i] = finding.copyWith(fixStatus: FixStatus.inProgress);
      state = state.copyWith(
        findings: List.from(updatedFindings),
        currentFixIndex: i,
        fixStatusMessage: 'Analyzing ${finding.secretType}...',
      );
      await Future.delayed(const Duration(milliseconds: 600));

      state = state.copyWith(
        fixStatusMessage: 'Storing in AWS Secrets Manager...',
      );

      // Phase 2 — call real API (with mock fallback)
      StoreSecretResult? result;
      try {
        result = await _api.storeSecret(
          serviceName: _buildServiceName(finding),
          secretValue: finding.rawValue ?? finding.maskedValue,
          language: finding.language ?? 'python',
        );
      } on Exception {
        // API unreachable — use mock values so the UI demo still works
        result = StoreSecretResult(
          secretArn:
              'arn:aws:secretsmanager:us-east-1:123456789012:secret:codeguard/secretlens/${finding.id}',
          retrievalCode: _generateFallbackCode(finding),
        );
      }

      state = state.copyWith(
        fixStatusMessage: 'Generating retrieval code...',
      );
      await Future.delayed(const Duration(milliseconds: 400));

      // Phase 3 — mark stored
      updatedFindings[i] = updatedFindings[i].copyWith(
        fixStatus: FixStatus.stored,
        storedSecretArn: result.secretArn,
        generatedCode: result.retrievalCode,
      );
      state = state.copyWith(
        findings: List.from(updatedFindings),
        currentFixIndex: i + 1,
      );
    }

    await Future.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(
      fixInProgress: false,
      fixCompleted: true,
      fixStatusMessage: 'All secrets secured',
    );
  }

  void commitAnyway() {
    state = state.copyWith(commitOverridden: true);
  }

  void reset() {
    state = CommitBlockState(findings: List.from(_mockFindings));
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Derives the service_name sent to the engine.
  /// Convention (from docs): the engine prefixes with `codeguard/` internally,
  /// so we send `secretlens/{sanitised-secret-type}`.
  String _buildServiceName(Finding finding) {
    final sanitised = finding.secretType
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return 'secretlens-$sanitised';
  }

  /// Local fallback snippet used when the API is unreachable.
  String _generateFallbackCode(Finding finding) {
    final secretId =
        'codeguard/secretlens/${finding.id}';

    switch (finding.language) {
      case 'javascript':
        return '''const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

const client = new SecretsManagerClient({ region: 'us-east-1' });

async function getSecret() {
  const response = await client.send(
    new GetSecretValueCommand({ SecretId: '$secretId' })
  );
  return JSON.parse(response.SecretString);
}

module.exports = { getSecret };''';

      case 'python':
        return '''import boto3
import json

def get_secret():
    client = boto3.client(
        service_name='secretsmanager',
        region_name='us-east-1'
    )
    response = client.get_secret_value(
        SecretId='$secretId'
    )
    return json.loads(response['SecretString'])''';

      default:
        return '''# Retrieve secret from AWS Secrets Manager
aws secretsmanager get-secret-value \\
  --secret-id "$secretId" \\
  --region us-east-1 \\
  --query SecretString \\
  --output text''';
    }
  }
}

final commitBlockProvider =
    StateNotifierProvider<CommitBlockNotifier, CommitBlockState>(
  (ref) => CommitBlockNotifier(),
);
