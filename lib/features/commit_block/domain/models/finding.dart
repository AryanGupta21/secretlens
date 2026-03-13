enum Severity { critical, high, medium, low }

enum FixStatus { unfixed, inProgress, stored, failed }

extension SeverityExt on Severity {
  String get label {
    switch (this) {
      case Severity.critical:
        return 'CRITICAL';
      case Severity.high:
        return 'HIGH';
      case Severity.medium:
        return 'MEDIUM';
      case Severity.low:
        return 'LOW';
    }
  }

  int get colorValue {
    switch (this) {
      case Severity.critical:
        return 0xFFFF3B3B;
      case Severity.high:
        return 0xFFFF6B35;
      case Severity.medium:
        return 0xFFFFB800;
      case Severity.low:
        return 0xFF4D9FFF;
    }
  }
}

class Finding {
  final String id;
  final String secretType;
  final String file;
  final int line;
  final Severity severity;
  final String maskedValue;
  /// Actual secret value — used only for API submission, never displayed in UI.
  final String? rawValue;
  final FixStatus fixStatus;
  final String? storedSecretArn;
  final String? generatedCode;
  final String? language;

  const Finding({
    required this.id,
    required this.secretType,
    required this.file,
    required this.line,
    required this.severity,
    required this.maskedValue,
    this.rawValue,
    this.fixStatus = FixStatus.unfixed,
    this.storedSecretArn,
    this.generatedCode,
    this.language,
  });

  Finding copyWith({
    FixStatus? fixStatus,
    String? storedSecretArn,
    String? generatedCode,
  }) {
    return Finding(
      id: id,
      secretType: secretType,
      file: file,
      line: line,
      severity: severity,
      maskedValue: maskedValue,
      rawValue: rawValue,
      language: language,
      fixStatus: fixStatus ?? this.fixStatus,
      storedSecretArn: storedSecretArn ?? this.storedSecretArn,
      generatedCode: generatedCode ?? this.generatedCode,
    );
  }
}
