import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

// ── Models ───────────────────────────────────────────────────────────────────

class EngineHealth {
  final String status;
  final String service;
  final String version;

  const EngineHealth({
    required this.status,
    required this.service,
    required this.version,
  });

  factory EngineHealth.fromJson(Map<String, dynamic> j) => EngineHealth(
        status: j['status']?.toString() ?? '',
        service: j['service']?.toString() ?? '',
        version: j['version']?.toString() ?? '',
      );

  bool get isHealthy => status == 'healthy' || status == 'ok';
}

class IngestResponse {
  final String documentId;
  final String filename;
  final int rulesExtracted;
  final String message;

  const IngestResponse({
    required this.documentId,
    required this.filename,
    required this.rulesExtracted,
    required this.message,
  });

  factory IngestResponse.fromJson(Map<String, dynamic> j) => IngestResponse(
        documentId: j['document_id']?.toString() ?? '',
        filename: j['filename']?.toString() ?? '',
        rulesExtracted: (j['rules_extracted'] as num?)?.toInt() ?? 0,
        message: j['message']?.toString() ?? '',
      );
}

class DocumentInfo {
  final int id;
  final String filename;
  final String fileType;
  final String ingestedAt;
  final bool rulesExtracted;
  final String? extractionError;
  final int ruleCount;

  const DocumentInfo({
    required this.id,
    required this.filename,
    required this.fileType,
    required this.ingestedAt,
    required this.rulesExtracted,
    this.extractionError,
    required this.ruleCount,
  });

  factory DocumentInfo.fromJson(Map<String, dynamic> j) => DocumentInfo(
        id: (j['id'] as num?)?.toInt() ?? 0,
        filename: j['filename']?.toString() ?? '',
        fileType: j['file_type']?.toString() ?? '',
        ingestedAt: j['ingested_at']?.toString() ?? '',
        rulesExtracted: j['rules_extracted'] == true,
        extractionError: j['extraction_error']?.toString(),
        ruleCount: (j['rule_count'] as num?)?.toInt() ?? 0,
      );
}

class ComplianceRule {
  final int id;
  final int documentId;
  final String ruleTitle;
  final String description;
  final String category;
  final String severity;
  final List<String> regexPatterns;
  final List<String> languages;
  final String remediation;
  final bool isActive;

  const ComplianceRule({
    required this.id,
    required this.documentId,
    required this.ruleTitle,
    required this.description,
    required this.category,
    required this.severity,
    required this.regexPatterns,
    required this.languages,
    required this.remediation,
    required this.isActive,
  });

  factory ComplianceRule.fromJson(Map<String, dynamic> j) => ComplianceRule(
        id: (j['id'] as num?)?.toInt() ?? 0,
        documentId: (j['document_id'] as num?)?.toInt() ?? 0,
        ruleTitle: j['rule_title']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        category: j['category']?.toString() ?? '',
        severity: j['severity']?.toString() ?? '',
        regexPatterns: (j['regex_patterns'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        languages: (j['languages'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        remediation: j['remediation']?.toString() ?? '',
        isActive: j['is_active'] == true || j['is_active'] == null,
      );
}

class FindingResult {
  final int ruleId;
  final String severity;
  final int lineNumber;
  final String message;
  final String remediation;

  const FindingResult({
    required this.ruleId,
    required this.severity,
    required this.lineNumber,
    required this.message,
    required this.remediation,
  });

  factory FindingResult.fromJson(Map<String, dynamic> j) => FindingResult(
        ruleId: (j['rule_id'] as num?)?.toInt() ?? 0,
        severity: j['severity']?.toString() ?? '',
        lineNumber: (j['line_number'] as num?)?.toInt() ?? 0,
        message: j['message']?.toString() ?? '',
        remediation: j['remediation']?.toString() ?? '',
      );
}

// ── Service ──────────────────────────────────────────────────────────────────

class ComplianceEngineService {
  static const _baseUrl = 'https://compliance-engine.onrender.com';

  final http.Client _client;

  ComplianceEngineService({http.Client? client})
      : _client = client ?? http.Client();

  Future<EngineHealth> healthCheck() async {
    final res = await _client
        .get(Uri.parse('$_baseUrl/health'),
            headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    _ok(res, 'healthCheck');
    return EngineHealth.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<IngestResponse> ingestDocument(
      Uint8List bytes, String filename) async {
    final req =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/ingest'));
    req.files.add(http.MultipartFile.fromBytes('file', bytes,
        filename: filename));
    final streamed =
        await req.send().timeout(const Duration(seconds: 120));
    final res = await http.Response.fromStream(streamed);
    _ok(res, 'ingestDocument');
    return IngestResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<DocumentInfo>> listDocuments() async {
    final res = await _client
        .get(Uri.parse('$_baseUrl/documents'),
            headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    _ok(res, 'listDocuments');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => DocumentInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ComplianceRule>> listRules({
    String? category,
    String? severity,
    String? language,
  }) async {
    final params = {
      if (category != null && category.isNotEmpty) 'category': category,
      if (severity != null && severity.isNotEmpty) 'severity': severity,
      if (language != null && language.isNotEmpty) 'language': language,
    };
    final uri = Uri.parse('$_baseUrl/rules')
        .replace(queryParameters: params.isEmpty ? null : params);
    final res = await _client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    _ok(res, 'listRules');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ComplianceRule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FindingResult>> validateCode(
      String filePath, String content) async {
    final res = await _client
        .post(
          Uri.parse('$_baseUrl/validate'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'files': [
              {'file_path': filePath, 'content': content}
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));
    _ok(res, 'validateCode');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final findings = data['findings'] as List<dynamic>? ?? [];
    return findings
        .map((e) => FindingResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _ok(http.Response res, String op) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$op failed (${res.statusCode}): ${res.body}');
    }
  }

  void dispose() => _client.close();
}
