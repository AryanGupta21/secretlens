import 'dart:convert';
import 'package:http/http.dart' as http;

class StoreSecretResult {
  final String secretArn;
  final String retrievalCode;

  const StoreSecretResult({
    required this.secretArn,
    required this.retrievalCode,
  });
}

/// Communicates with the cloud-rotation-engine deployed at Render.
/// Primary endpoint: POST /api/v1/secrets/store
/// Docs: https://code-gaurd.onrender.com/docs
class SecretsApiDatasource {
  static const String _baseUrl = 'https://code-gaurd.onrender.com';

  final http.Client _client;

  SecretsApiDatasource({http.Client? client})
      : _client = client ?? http.Client();

  /// Stores a secret in AWS Secrets Manager and returns the ARN + retrieval
  /// code snippet for the given [language].
  ///
  /// [serviceName] follows the convention `secretlens/{secretType}` — the
  /// engine prefixes it with `codeguard/` internally.
  ///
  /// [language] must be one of: python, javascript, go, java, php, cs.
  /// Shell scripts are mapped to python as the engine has no shell template.
  Future<StoreSecretResult> storeSecret({
    required String serviceName,
    required String secretValue,
    required String language,
    String environment = 'development',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/secrets/store');

    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'service_name': serviceName,
            'secret_value': secretValue,
            'language': _normaliseLanguage(language),
            'environment': environment,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return StoreSecretResult(
        secretArn: (data['secret_arn'] ?? data['arn'] ?? '') as String,
        retrievalCode:
            (data['retrieval_code'] ?? data['snippet'] ?? '') as String,
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: 'Store secret failed',
      body: response.body,
    );
  }

  /// Maps Flutter-side language labels to engine-accepted values.
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
        return 'cs';
      // shell/bash not supported by engine — fall back to python snippet
      default:
        return 'python';
    }
  }

  void dispose() => _client.close();
}

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
