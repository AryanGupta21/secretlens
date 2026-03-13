import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAwsAccessKey   = 'aws_access_key';
  static const _keyAwsSecretKey   = 'aws_secret_key';
  static const _keySupabaseUrl    = 'supabase_url';
  static const _keySupabaseAnonKey = 'supabase_anon_key';

  static Future<void> saveAwsCredentials({
    required String accessKey,
    required String secretKey,
  }) async {
    await _storage.write(key: _keyAwsAccessKey, value: accessKey);
    await _storage.write(key: _keyAwsSecretKey, value: secretKey);
  }

  static Future<void> saveSupabaseCredentials({
    required String url,
    required String anonKey,
  }) async {
    await _storage.write(key: _keySupabaseUrl, value: url);
    await _storage.write(key: _keySupabaseAnonKey, value: anonKey);
  }

  static Future<Map<String, String?>> loadAll() async {
    return {
      'awsAccessKey':    await _storage.read(key: _keyAwsAccessKey),
      'awsSecretKey':    await _storage.read(key: _keyAwsSecretKey),
      'supabaseUrl':     await _storage.read(key: _keySupabaseUrl),
      'supabaseAnonKey': await _storage.read(key: _keySupabaseAnonKey),
    };
  }

  static Future<bool> hasCredentials() async {
    final all = await loadAll();
    return all.values.every((v) => v != null && v.isNotEmpty);
  }

  static Future<void> clearAll() async => _storage.deleteAll();
}
