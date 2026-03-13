class AwsSecret {
  final String name;
  final String arn;
  final DateTime? createdDate;
  final DateTime? lastUpdated;
  final String service;
  final String environment;
  final String secretType;

  const AwsSecret({
    required this.name,
    required this.arn,
    this.createdDate,
    this.lastUpdated,
    required this.service,
    required this.environment,
    required this.secretType,
  });

  factory AwsSecret.fromJson(Map<String, dynamic> json) {
    String service = '';
    String environment = '';
    String secretType = '';

    final tags = json['tags'] as List<dynamic>? ?? [];
    for (final tag in tags) {
      final key = (tag['Key'] as String? ?? '').toLowerCase();
      final value = tag['Value'] as String? ?? '';
      if (key == 'service') service = value;
      if (key == 'environment') environment = value;
      if (key == 'secrettype') secretType = value;
    }

    return AwsSecret(
      name: json['name'] as String? ?? '',
      arn: json['arn'] as String? ?? '',
      createdDate: json['created_date'] != null
          ? DateTime.tryParse(json['created_date'] as String)
          : null,
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'] as String)
          : null,
      service: service,
      environment: environment,
      secretType: secretType,
    );
  }
}
