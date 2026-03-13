import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/secret_incident.dart';

enum LoadStatus { idle, loading, success, error }

class AuditsState {
  final LoadStatus status;
  final List<SecretIncident> incidents;
  final Map<String, int> stats;
  final String? error;
  final String riskFilter;
  final String statusFilter;
  final DateTime? lastRefreshed;

  const AuditsState({
    this.status = LoadStatus.idle,
    this.incidents = const [],
    this.stats = const {},
    this.error,
    this.riskFilter = 'all',
    this.statusFilter = 'all',
    this.lastRefreshed,
  });

  AuditsState copyWith({
    LoadStatus? status,
    List<SecretIncident>? incidents,
    Map<String, int>? stats,
    String? error,
    String? riskFilter,
    String? statusFilter,
    DateTime? lastRefreshed,
  }) {
    return AuditsState(
      status:        status        ?? this.status,
      incidents:     incidents     ?? this.incidents,
      stats:         stats         ?? this.stats,
      error:         error,
      riskFilter:    riskFilter    ?? this.riskFilter,
      statusFilter:  statusFilter  ?? this.statusFilter,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
    );
  }

  List<SecretIncident> get filteredIncidents {
    return incidents.where((i) {
      final riskOk   = riskFilter   == 'all' || i.riskLevel.name   == riskFilter;
      final statusOk = statusFilter == 'all' || i.remediationStatus.name == statusFilter;
      return riskOk && statusOk;
    }).toList();
  }
}

class AuditsNotifier extends StateNotifier<AuditsState> {
  AuditsNotifier() : super(const AuditsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(status: LoadStatus.loading);
    try {
      final incidents = await SupabaseService.getSecretIncidents();
      final stats     = await SupabaseService.getIncidentStats();
      state = state.copyWith(
        status:        LoadStatus.success,
        incidents:     incidents,
        stats:         stats,
        lastRefreshed: DateTime.now(),
        error:         null,
      );
    } catch (e) {
      state = state.copyWith(
          status: LoadStatus.error, error: e.toString());
    }
  }

  void setRiskFilter(String filter) =>
      state = state.copyWith(riskFilter: filter);

  void setStatusFilter(String filter) =>
      state = state.copyWith(statusFilter: filter);
}

final auditsProvider =
    StateNotifierProvider<AuditsNotifier, AuditsState>(
        (ref) => AuditsNotifier());
