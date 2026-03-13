import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ComplianceStatus { pass, fail, warning, pending }

class ComplianceCheck {
  final String id;
  final String category;
  final String title;
  final String description;
  final ComplianceStatus status;
  final String severity;
  final DateTime lastChecked;

  const ComplianceCheck({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    required this.severity,
    required this.lastChecked,
  });
}

class ComplianceState {
  final List<ComplianceCheck> checks;
  final int passCount;
  final int failCount;
  final int warningCount;
  final String categoryFilter;

  const ComplianceState({
    required this.checks,
    required this.passCount,
    required this.failCount,
    required this.warningCount,
    this.categoryFilter = 'ALL',
  });

  double get score =>
      checks.isEmpty ? 0.0 : passCount / checks.length;

  List<ComplianceCheck> get filteredChecks {
    if (categoryFilter == 'ALL') return checks;
    return checks
        .where((c) => c.category.toUpperCase() == categoryFilter)
        .toList();
  }

  ComplianceState copyWith({
    List<ComplianceCheck>? checks,
    int? passCount,
    int? failCount,
    int? warningCount,
    String? categoryFilter,
  }) {
    return ComplianceState(
      checks:         checks         ?? this.checks,
      passCount:      passCount      ?? this.passCount,
      failCount:      failCount      ?? this.failCount,
      warningCount:   warningCount   ?? this.warningCount,
      categoryFilter: categoryFilter ?? this.categoryFilter,
    );
  }
}

class ComplianceNotifier extends StateNotifier<ComplianceState> {
  ComplianceNotifier() : super(_buildMockState());

  static ComplianceState _buildMockState() {
    final now = DateTime.now();
    final checks = [
      ComplianceCheck(
        id: 'c1',
        category: 'IAM',
        title: 'IAM Policy Review',
        description: 'All IAM policies follow least-privilege principle',
        status: ComplianceStatus.pass,
        severity: 'high',
        lastChecked: now.subtract(const Duration(hours: 2)),
      ),
      ComplianceCheck(
        id: 'c2',
        category: 'SECRETS',
        title: 'Secret Rotation Policy',
        description: 'Secrets rotated within 90-day window',
        status: ComplianceStatus.warning,
        severity: 'critical',
        lastChecked: now.subtract(const Duration(hours: 1)),
      ),
      ComplianceCheck(
        id: 'c3',
        category: 'LOGGING',
        title: 'CloudTrail Logging',
        description: 'AWS CloudTrail enabled for all regions',
        status: ComplianceStatus.pass,
        severity: 'high',
        lastChecked: now.subtract(const Duration(minutes: 30)),
      ),
      ComplianceCheck(
        id: 'c4',
        category: 'ENCRYPTION',
        title: 'Encryption at Rest',
        description:
            'All S3 buckets and RDS instances use KMS encryption',
        status: ComplianceStatus.pass,
        severity: 'critical',
        lastChecked: now.subtract(const Duration(hours: 3)),
      ),
      ComplianceCheck(
        id: 'c5',
        category: 'ACCESS',
        title: 'MFA Enforcement',
        description:
            'Multi-factor authentication enforced for all IAM users',
        status: ComplianceStatus.fail,
        severity: 'critical',
        lastChecked: now.subtract(const Duration(hours: 5)),
      ),
      ComplianceCheck(
        id: 'c6',
        category: 'NETWORK',
        title: 'VPC Security Groups',
        description:
            'No security groups allow unrestricted inbound access',
        status: ComplianceStatus.warning,
        severity: 'high',
        lastChecked: now.subtract(const Duration(hours: 4)),
      ),
      ComplianceCheck(
        id: 'c7',
        category: 'SECRETS',
        title: 'Hardcoded Secrets Scan',
        description:
            'No hardcoded credentials detected in repositories',
        status: ComplianceStatus.fail,
        severity: 'critical',
        lastChecked: now.subtract(const Duration(minutes: 15)),
      ),
      ComplianceCheck(
        id: 'c8',
        category: 'IAM',
        title: 'Root Account Usage',
        description: 'AWS root account not used for daily operations',
        status: ComplianceStatus.pass,
        severity: 'critical',
        lastChecked: now.subtract(const Duration(hours: 6)),
      ),
    ];

    final pass    = checks.where((c) => c.status == ComplianceStatus.pass).length;
    final fail    = checks.where((c) => c.status == ComplianceStatus.fail).length;
    final warning = checks.where((c) => c.status == ComplianceStatus.warning).length;

    return ComplianceState(
      checks:       checks,
      passCount:    pass,
      failCount:    fail,
      warningCount: warning,
    );
  }

  void setCategoryFilter(String category) {
    state = state.copyWith(categoryFilter: category);
  }
}

final complianceProvider =
    StateNotifierProvider<ComplianceNotifier, ComplianceState>(
        (ref) => ComplianceNotifier());
