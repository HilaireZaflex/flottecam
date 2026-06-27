import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/update_service.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les données de localisation pour intl (DateFormat en français)
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('fr', null);

  // Vérifier les mises à jour automatiquement au démarrage (PWA uniquement)
  // Si nouvelle version → recharge automatiquement sans intervention utilisateur
  if (kIsWeb) {
    await UpdateService.checkAndUpdate();
  }

  runApp(const ProviderScope(child: FlotteCamApp()));
}

class FlotteCamApp extends ConsumerWidget {
  const FlotteCamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Sur le Web, le splash HTML s'affiche déjà — on retourne juste un fond uni
    // Sur mobile, on affiche le splash Flutter natif
    if (authState.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: kIsWeb ? AppTheme.primaryColor : Colors.white,
          body: kIsWeb
              ? const SizedBox.shrink() // Le splash HTML est déjà affiché
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo FlotteCam
                      _FlotteCamLogo(),
                      SizedBox(height: 24),
                      Text(
                        'FlotteCam',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Gestion de flotte professionnelle',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      SizedBox(height: 48),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'FlotteCam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}

/// Logo FlotteCam — camion + signal GPS
class _FlotteCamLogo extends StatelessWidget {
  const _FlotteCamLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 48),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
