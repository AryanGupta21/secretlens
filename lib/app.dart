import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';

class SecretLensApp extends ConsumerWidget {
  const SecretLensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const Scaffold(
          backgroundColor: Color(0xFF060B18),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF4D9FFF)),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'SecretLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}
