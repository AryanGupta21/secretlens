import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/services/supabase_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? awsAccessKey;
  final String? supabaseUrl;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.awsAccessKey,
    this.supabaseUrl,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? awsAccessKey,
    String? supabaseUrl,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      awsAccessKey: awsAccessKey ?? this.awsAccessKey,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkExistingAuth();
  }

  Future<void> _checkExistingAuth() async {
    state = state.copyWith(isLoading: true);
    final creds = await SecureStorage.loadAll();
    if (creds['supabaseUrl'] != null &&
        creds['supabaseAnonKey'] != null &&
        creds['supabaseUrl']!.isNotEmpty &&
        creds['supabaseAnonKey']!.isNotEmpty) {
      try {
        await SupabaseService.initialize(
          url: creds['supabaseUrl']!,
          anonKey: creds['supabaseAnonKey']!,
        );
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          awsAccessKey: creds['awsAccessKey'],
          supabaseUrl: creds['supabaseUrl'],
        );
      } catch (_) {
        state = const AuthState(isLoading: false);
      }
    } else {
      state = const AuthState(isLoading: false);
    }
  }

  Future<void> login({
    required String awsAccessKey,
    required String awsSecretKey,
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (awsAccessKey.isEmpty ||
          awsSecretKey.isEmpty ||
          supabaseUrl.isEmpty ||
          supabaseAnonKey.isEmpty) {
        state = state.copyWith(
            isLoading: false, error: 'All fields are required');
        return;
      }

      await SupabaseService.initialize(
          url: supabaseUrl, anonKey: supabaseAnonKey);

      // Test Supabase connection
      await Supabase.instance.client
          .from('secret_incidents')
          .select('incident_id')
          .limit(1);

      await SecureStorage.saveAwsCredentials(
          accessKey: awsAccessKey, secretKey: awsSecretKey);
      await SecureStorage.saveSupabaseCredentials(
          url: supabaseUrl, anonKey: supabaseAnonKey);

      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        awsAccessKey: awsAccessKey,
        supabaseUrl: supabaseUrl,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Connection failed: ${e.toString().split('\n').first}',
      );
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
