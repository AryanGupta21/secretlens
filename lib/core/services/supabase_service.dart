import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/secret_incident.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    if (_initialized) return;
    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _initialized = true;
    } catch (_) {
      // Already initialized or failed — mark as initialized to avoid repeated calls
      _initialized = true;
    }
  }

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<SecretIncident>> getSecretIncidents({
    String? riskFilter,
    String? statusFilter,
    int limit = 100,
  }) async {
    dynamic query;

    if (riskFilter != null && riskFilter != 'all') {
      query = _client
          .from('secret_incidents')
          .select()
          .eq('risk_level', riskFilter)
          .order('detected_at', ascending: false)
          .limit(limit);
    } else {
      query = _client
          .from('secret_incidents')
          .select()
          .order('detected_at', ascending: false)
          .limit(limit);
    }

    final response = await query;
    return (response as List)
        .map((e) => SecretIncident.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, int>> getIncidentStats() async {
    final response = await _client
        .from('secret_incidents')
        .select('risk_level, remediation_status');
    final items = response as List;
    final stats = <String, int>{
      'total':    items.length,
      'critical': 0,
      'high':     0,
      'medium':   0,
      'low':      0,
      'pending':  0,
      'resolved': 0,
      'skipped':  0,
      'failed':   0,
    };
    for (final item in items) {
      final rl = item['risk_level'] as String? ?? '';
      final rs = item['remediation_status'] as String? ?? '';
      if (stats.containsKey(rl)) stats[rl] = (stats[rl] ?? 0) + 1;
      if (stats.containsKey(rs)) stats[rs] = (stats[rs] ?? 0) + 1;
    }
    return stats;
  }
}
