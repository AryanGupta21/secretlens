import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// Mock findings that simulate real detection results
final _mockFindings = [
  const Finding(
    id: 'finding-001',
    secretType: 'AWS Access Key',
    file: 'src/config.js',
    line: 23,
    severity: Severity.critical,
    maskedValue: 'AKIA••••••••••••WXYZ',
    language: 'javascript',
  ),
  const Finding(
    id: 'finding-002',
    secretType: 'RSA Private Key',
    file: 'backend/auth.py',
    line: 7,
    severity: Severity.critical,
    maskedValue: '-----BEGIN RSA PRIVATE KEY-----\nMIIEow••••••••••••',
    language: 'python',
  ),
  const Finding(
    id: 'finding-003',
    secretType: 'Stripe API Secret',
    file: '.env',
    line: 12,
    severity: Severity.high,
    maskedValue: 'sk_live_••••••••••••••••A4BC',
    language: 'shell',
  ),
];

class CommitBlockNotifier extends StateNotifier<CommitBlockState> {
  CommitBlockNotifier()
      : super(CommitBlockState(findings: List.from(_mockFindings)));

  Future<void> fixAllIssues() async {
    state = state.copyWith(
      fixInProgress: true,
      currentFixIndex: 0,
      fixStatusMessage: 'Initializing secure storage...',
    );

    final updatedFindings = List<Finding>.from(state.findings);

    for (int i = 0; i < updatedFindings.length; i++) {
      // Mark as in-progress
      updatedFindings[i] =
          updatedFindings[i].copyWith(fixStatus: FixStatus.inProgress);
      state = state.copyWith(
        findings: List.from(updatedFindings),
        currentFixIndex: i,
        fixStatusMessage: 'Analyzing ${updatedFindings[i].secretType}...',
      );
      await Future.delayed(const Duration(milliseconds: 800));

      state = state.copyWith(
        fixStatusMessage:
            'Storing in AWS Secrets Manager...',
      );
      await Future.delayed(const Duration(milliseconds: 1000));

      state = state.copyWith(
        fixStatusMessage: 'Generating retrieval code...',
      );
      await Future.delayed(const Duration(milliseconds: 600));

      // Mark as stored with ARN and generated code
      updatedFindings[i] = updatedFindings[i].copyWith(
        fixStatus: FixStatus.stored,
        storedSecretArn:
            'arn:aws:secretsmanager:us-east-1:123456789012:secret:secretlens/${updatedFindings[i].id}',
        generatedCode: _generateRetrievalCode(updatedFindings[i]),
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

  String _generateRetrievalCode(Finding finding) {
    final secretId =
        'secretlens/${finding.id}';

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
