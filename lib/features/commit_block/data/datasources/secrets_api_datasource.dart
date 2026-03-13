import 'dart:convert';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// Result models
// ─────────────────────────────────────────────────────────────────────────────

class StoreSecretResult {
  final String secretArn;
  final String retrievalCode;

  const StoreSecretResult({required this.secretArn, required this.retrievalCode});
}

class StoredSecretItem {
  final String name;
  final String arn;
  final DateTime? createdDate;
  final DateTime? lastUpdated;
  final String service;
  final String environment;
  final String secretType;

  const StoredSecretItem({
    required this.name,
    required this.arn,
    this.createdDate,
    this.lastUpdated,
    required this.service,
    required this.environment,
    required this.secretType,
  });

  factory StoredSecretItem.fromJson(Map<String, dynamic> json) {
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

    return StoredSecretItem(
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

class AuditLogItem {
  final String auditId;
  final String secretId;
  final String serviceName;
  final String environment;
  final String operationType;
  final String operationStatus;
  final String? codeLanguage;
  final bool codeGenerated;
  final String secretType;
  final String? versionId;
  final int? operationTimeMs;
  final String? errorMessage;
  final String? createdAt;

  const AuditLogItem({
    required this.auditId,
    required this.secretId,
    required this.serviceName,
    required this.environment,
    required this.operationType,
    required this.operationStatus,
    this.codeLanguage,
    required this.codeGenerated,
    required this.secretType,
    this.versionId,
    this.operationTimeMs,
    this.errorMessage,
    this.createdAt,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    return AuditLogItem(
      auditId: json['audit_id'] as String? ?? '',
      secretId: json['secret_id'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      environment: json['environment'] as String? ?? '',
      operationType: json['operation_type'] as String? ?? '',
      operationStatus: json['operation_status'] as String? ?? '',
      codeLanguage: json['code_language'] as String?,
      codeGenerated: json['code_generated'] as bool? ?? false,
      secretType: json['secret_type'] as String? ?? '',
      versionId: json['version_id'] as String?,
      operationTimeMs: json['operation_time_ms'] as int?,
      errorMessage: json['error_message'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class GenerateCodeResult {
  final String secretId;
  final String language;
  final String code;

  const GenerateCodeResult({
    required this.secretId,
    required this.language,
    required this.code,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Datasource — wraps https://code-gaurd.onrender.com
// OpenAPI spec: https://code-gaurd.onrender.com/openapi.json
// ─────────────────────────────────────────────────────────────────────────────

class SecretsApiDatasource {
  static const String _baseUrl = 'https://code-gaurd.onrender.com';

  final http.Client _client;

  SecretsApiDatasource({http.Client? client})
      : _client = client ?? http.Client();

  // ── Health ────────────────────────────────────────────────────────────────

  /// GET /health  →  { "status": "healthy", "service": "rotation-engine" }
  Future<bool> healthCheck() async {
    try {
      final res = await _client
          .get(Uri.parse('$_baseUrl/health'),
              headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['status'] as String?) == 'healthy';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Secrets list ──────────────────────────────────────────────────────────

  /// GET /api/v1/secrets  →  { "status", "count", "secrets": [...] }
  Future<List<StoredSecretItem>> listSecrets({String? serviceFilter}) async {
    final uri = Uri.parse('$_baseUrl/api/v1/secrets').replace(
      queryParameters: serviceFilter != null
          ? {'service_filter': serviceFilter}
          : null,
    );

    final res = await _client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    _assertOk(res, 'listSecrets');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = data['secrets'] as List<dynamic>? ?? [];
    return list
        .map((e) => StoredSecretItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Audit logs ────────────────────────────────────────────────────────────

  /// GET /api/v1/secrets-audit/all  →  { "total", "operations": [...] }
  Future<List<AuditLogItem>> getAuditLogs({int? limit}) async {
    final uri = Uri.parse('$_baseUrl/api/v1/secrets-audit/all').replace(
      queryParameters: limit != null ? {'limit': limit.toString()} : null,
    );

    final res = await _client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    _assertOk(res, 'getAuditLogs');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final ops = data['operations'] as List<dynamic>? ?? [];
    return ops
        .map((e) => AuditLogItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Generate code ─────────────────────────────────────────────────────────

  /// POST /api/v1/secrets/generate-code
  /// Body: { secret_id, language, region }
  Future<GenerateCodeResult> generateCode({
    required String secretId,
    required String language,
    String region = 'us-east-1',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/secrets/generate-code');

    final res = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'secret_id': secretId,
            'language': _normaliseLanguage(language),
            'region': region,
          }),
        )
        .timeout(const Duration(seconds: 30));

    _assertOk(res, 'generateCode');
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    return GenerateCodeResult(
      secretId: secretId,
      language: language,
      code: (data['code'] ??
              data['snippet'] ??
              data['retrieval_code'] ??
              data['generated_code'] ??
              '') as String,
    );
  }

  // ── Store + generate (used by fix flow) ───────────────────────────────────

  /// POST /api/v1/secrets/store-and-generate-code
  /// Body: { secret_id, secret_value, service_name, language, environment, description? }
  /// Response: { secret_arn?, arn?, code?, snippet?, version_id?, ... }
  Future<StoreSecretResult> storeAndGenerateCode({
    required String secretId,
    required String secretValue,
    required String serviceName,
    required String language,
    String environment = 'development',
    String? description,
  }) async {
    final uri =
        Uri.parse('$_baseUrl/api/v1/secrets/store-and-generate-code');

    final res = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'secret_id': secretId,
            'secret_value': secretValue,
            'service_name': serviceName,
            'language': _normaliseLanguage(language),
            'environment': environment,
            'description': description,
          }),
        )
        .timeout(const Duration(seconds: 30));

    _assertOk(res, 'storeAndGenerateCode');
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    return StoreSecretResult(
      secretArn: (data['secret_arn'] ??
              data['arn'] ??
              data['SecretARN'] ??
              '') as String,
      retrievalCode: (data['code'] ??
              data['snippet'] ??
              data['retrieval_code'] ??
              data['generated_code'] ??
              '') as String,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _assertOk(http.Response res, String op) {
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ApiException(
        statusCode: res.statusCode,
        message: '$op failed',
        body: res.body,
      );
    }
  }

  /// Maps Flutter language labels → engine-accepted values.
  /// Supported by engine: python, javascript, go, java, php, csharp
  String _normaliseLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'javascript':
        return 'javascript';
      case 'python':
        return 'python';
      case 'go':
        return 'go';
      case 'java':
        return 'java';
      case 'php':
        return 'php';
      case 'cs':
      case 'csharp':
        return 'csharp';
      // shell has no engine template — fall back to python
      default:
        return 'python';
    }
  }

  void dispose() => _client.close();
}

// ─────────────────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String body;

  const ApiException({
    required this.statusCode,
    required this.message,
    required this.body,
  });

  @override
  String toString() => 'ApiException($statusCode): $message\n$body';
}
