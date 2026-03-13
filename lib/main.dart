import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/background_sync_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/commit_block/presentation/screens/commit_blocked_screen.dart';

/// Entry point.
/// Initialises notifications and the background WorkManager task
/// before the widget tree is mounted.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Set up local notifications channel + permissions
  await NotificationService.init();
  await NotificationService.requestPermission();

  // 2. Register the 15-min background audit-poll task
  //    (fires even when the app is fully closed on Android;
  //     relies on BGAppRefreshTask on iOS which the OS schedules)
  await BackgroundSyncService.init();

  runApp(
    const ProviderScope(
      child: SecretLensApp(),
    ),
  );
}

class SecretLensApp extends StatelessWidget {
  const SecretLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecretLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const CommitBlockedScreen(),
    );
  }
}
