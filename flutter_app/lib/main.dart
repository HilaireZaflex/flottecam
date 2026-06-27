import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/update_service.dart';
import 'core/services/pin_service.dart';
import 'core/services/web_lock_service.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('fr', null);
  if (kIsWeb) await UpdateService.checkAndUpdate();
  runApp(const ProviderScope(child: FlotteCamApp()));
}

class FlotteCamApp extends ConsumerStatefulWidget {
  const FlotteCamApp({super.key});

  @override
  ConsumerState<FlotteCamApp> createState() => _FlotteCamAppState();
}

class _FlotteCamAppState extends ConsumerState<FlotteCamApp>
    with WidgetsBindingObserver {
  // Timestamp quand l'app est passée en arrière-plan
  DateTime? _pausedAt;
  // Délai avant de demander le PIN (30 secondes)
  static const _lockDelay = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialiser le bridge JS → Flutter pour le verrouillage PIN sur iOS PWA
    if (kIsWeb) {
      WebLockService.init(() async {
        final authState = ref.read(authStateProvider);
        final isLoggedIn = authState.hasValue && authState.value != null;
        if (!isLoggedIn) return;
        final pinSvc = ref.read(pinServiceProvider);
        final hasPin = await pinSvc.hasPin();
        if (hasPin && mounted) {
          ref.read(appRouterProvider).go('/pin');
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (kIsWeb) WebLockService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App en arrière-plan → noter l'heure
        _pausedAt = DateTime.now();
        break;

      case AppLifecycleState.resumed:
        // App revenue au premier plan
        _onAppResumed();
        break;

      default:
        break;
    }
  }

  Future<void> _onAppResumed() async {
    final authState = ref.read(authStateProvider);
    final isLoggedIn = authState.hasValue && authState.value != null;
    if (!isLoggedIn) return;

    // Vérifier si l'app a été en arrière-plan assez longtemps
    final pausedAt = _pausedAt;
    if (pausedAt != null) {
      final elapsed = DateTime.now().difference(pausedAt);
      if (elapsed >= _lockDelay) {
        // Assez longtemps → demander le PIN + vérifier mises à jour
        final pinSvc = ref.read(pinServiceProvider);
        final hasPin = await pinSvc.hasPin();
        if (hasPin && mounted) {
          // Sur web → vérifier aussi les mises à jour
          if (kIsWeb) await UpdateService.checkAndUpdate();
          // Naviguer vers l'écran PIN
          ref.read(appRouterProvider).go('/pin');
        }
      }
    }
    _pausedAt = null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: kIsWeb ? AppTheme.primaryColor : Colors.white,
          body: kIsWeb
              ? const SizedBox.shrink()
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FlotteCamLogo(),
                      SizedBox(height: 24),
                      Text('FlotteCam',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor, letterSpacing: -0.5)),
                      SizedBox(height: 6),
                      Text('Gestion de flotte professionnelle',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                      SizedBox(height: 48),
                      SizedBox(width: 32, height: 32,
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryColor, strokeWidth: 3)),
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
