import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: DriverApp()));
}

class DriverApp extends ConsumerWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'FlotteCam Chauffeur',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: authState.when(
        loading: () => const Scaffold(
          backgroundColor: Color(0xFF1B4FD8),
          body: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_shipping_rounded, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text('FlotteCam', style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('Espace Chauffeur', style: TextStyle(
                color: Colors.white70, fontSize: 14)),
              SizedBox(height: 32),
              CircularProgressIndicator(color: Colors.white),
            ],
          )),
        ),
        error: (_, __) => const LoginScreen(),
        data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}
