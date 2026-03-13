import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum RiskLevel { critical, high, medium, low }

enum RemediationStatus { pending, resolved, skipped, failed }

class SecretIncident {
  final String incidentId;
  final String scanId;
  final String repoName;
  final String filePath;
  final int lineNumber;
  final String secretType;
  final String secretHash;
  final RiskLevel riskLevel;
  final String detectedBy;
  final DateTime detectedAt;
  final RemediationStatus remediationStatus;
  final DateTime? remediationDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SecretIncident({
    required this.incidentId,
    required this.scanId,
    required this.repoName,
    required this.filePath,
    required this.lineNumber,
    required this.secretType,
    required this.secretHash,
    required this.riskLevel,
    required this.detectedBy,
    required this.detectedAt,
    required this.remediationStatus,
    this.remediationDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SecretIncident.fromJson(Map<String, dynamic> json) {
    RiskLevel parseRisk(String? v) {
      switch (v?.toLowerCase()) {
        case 'critical': return RiskLevel.critical;
        case 'high':     return RiskLevel.high;
        case 'medium':   return RiskLevel.medium;
        default:         return RiskLevel.low;
      }
    }

    RemediationStatus parseStatus(String? v) {
      switch (v?.toLowerCase()) {
        case 'resolved': return RemediationStatus.resolved;
        case 'skipped':  return RemediationStatus.skipped;
        case 'failed':   return RemediationStatus.failed;
        default:         return RemediationStatus.pending;
      }
    }

    return SecretIncident(
      incidentId:        json['incident_id'] as String? ?? '',
      scanId:            json['scan_id'] as String? ?? '',
      repoName:          json['repo_name'] as String? ?? '',
      filePath:          json['file_path'] as String? ?? '',
      lineNumber:        (json['line_number'] as int?) ?? 0,
      secretType:        json['secret_type'] as String? ?? '',
      secretHash:        json['secret_hash'] as String? ?? '',
      riskLevel:         parseRisk(json['risk_level'] as String?),
      detectedBy:        json['detected_by'] as String? ?? '',
      detectedAt:        DateTime.tryParse(json['detected_at'] as String? ?? '') ?? DateTime.now(),
      remediationStatus: parseStatus(json['remediation_status'] as String?),
      remediationDate:   json['remediation_date'] != null
          ? DateTime.tryParse(json['remediation_date'] as String)
          : null,
      createdAt:  DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt:  DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Color toRiskColor() {
    switch (riskLevel) {
      case RiskLevel.critical: return AppColors.critical;
      case RiskLevel.high:     return AppColors.high;
      case RiskLevel.medium:   return AppColors.medium;
      case RiskLevel.low:      return AppColors.low;
    }
  }

  Color toRiskDimColor() {
    switch (riskLevel) {
      case RiskLevel.critical: return AppColors.criticalDim;
      case RiskLevel.high:     return AppColors.highDim;
      case RiskLevel.medium:   return AppColors.warningDim;
      case RiskLevel.low:      return AppColors.lowDim;
    }
  }

  String get riskLabel {
    switch (riskLevel) {
      case RiskLevel.critical: return 'CRITICAL';
      case RiskLevel.high:     return 'HIGH';
      case RiskLevel.medium:   return 'MEDIUM';
      case RiskLevel.low:      return 'LOW';
    }
  }

  String get statusLabel {
    switch (remediationStatus) {
      case RemediationStatus.pending:  return 'PENDING';
      case RemediationStatus.resolved: return 'RESOLVED';
      case RemediationStatus.skipped:  return 'SKIPPED';
      case RemediationStatus.failed:   return 'FAILED';
    }
  }

  Color get statusColor {
    switch (remediationStatus) {
      case RemediationStatus.pending:  return AppColors.warning;
      case RemediationStatus.resolved: return AppColors.success;
      case RemediationStatus.skipped:  return AppColors.textSecondary;
      case RemediationStatus.failed:   return AppColors.critical;
    }
  }
}
