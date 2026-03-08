import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/commit_block/presentation/screens/commit_blocked_screen.dart';

void main() {
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
