
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/pin_screen.dart';
import '../../features/auth/presentation/screens/create_pin_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/gps/presentation/screens/gps_map_screen.dart';
import '../../features/gps/presentation/screens/truck_tracking_screen.dart';
import '../../features/trucks/presentation/screens/trucks_screen.dart';
import '../../features/trucks/presentation/screens/truck_detail_screen.dart';
import '../../features/drivers/presentation/screens/drivers_screen.dart';
import '../../features/drivers/presentation/screens/driver_detail_screen.dart';
import '../../features/transports/presentation/screens/transports_screen.dart';
import '../../features/transports/presentation/screens/transport_detail_screen.dart';
import '../../features/transports/presentation/screens/create_transport_screen.dart';
import '../../features/operations/presentation/screens/operations_screen.dart';
import '../../features/operations/presentation/screens/rentabilite_screen.dart';
import '../../features/operations/presentation/screens/import_excel_screen.dart';
import '../../features/operations/presentation/screens/dettes_clients_screen.dart';
import '../../features/operations/presentation/screens/rapport_mensuel_screen.dart';
import '../../features/documents/presentation/screens/documents_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../widgets/main_scaffold.dart';
import '../services/pin_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      if (authState.isLoading) return null;

      final isLoggedIn = authState.hasValue && authState.value != null;
      final loc        = state.matchedLocation;
      final isAuthRoute = ['/login', '/register', '/pin', '/create-pin']
          .contains(loc);

      // Non connecté → login
      if (!isLoggedIn && !isAuthRoute) return '/login';

      // Connecté + route auth → vérifier PIN
      if (isLoggedIn && (loc == '/login' || loc == '/register')) {
        final pinSvc  = ref.read(pinServiceProvider);
        final hasPin  = await pinSvc.hasPin();
        return hasPin ? '/pin' : '/create-pin';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login',      builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/pin',        builder: (_, __) => const PinScreen()),
      GoRoute(path: '/create-pin', builder: (_, __) => const CreatePinScreen()),

      // ── Routes sans navbar (détail / création) ──────────────────────────────
      GoRoute(
        path: '/trucks/detail/:id',
        builder: (_, state) => TruckDetailScreen(truckId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/trucks/tracking/:id',
        builder: (_, state) {
          final plateNumber = state.extra as String? ?? 'N/A';
          return TruckTrackingScreen(
            truckId: int.parse(state.pathParameters['id']!),
            plateNumber: plateNumber,
          );
        },
      ),
      GoRoute(
        path: '/drivers/detail/:id',
        builder: (_, state) => DriverDetailScreen(driverId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/transports/new', builder: (_, __) => const CreateTransportScreen()),
      GoRoute(
        path: '/transports/detail/:id',
        builder: (_, state) => TransportDetailScreen(transportId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/operations/rentabilite', builder: (_, __) => const RentabiliteScreen()),
      GoRoute(path: '/operations/import',      builder: (_, __) => const ImportExcelScreen()),
      GoRoute(path: '/operations/dettes',      builder: (_, __) => const DettesClientsScreen()),
      GoRoute(path: '/operations/rapport',     builder: (_, __) => const RapportMensuelScreen()),

      // ── Shell avec navbar ────────────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/dashboard',     builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/gps',           builder: (_, __) => const GpsMapScreen()),
          GoRoute(path: '/trucks',        builder: (_, __) => const TrucksScreen()),
          GoRoute(path: '/drivers',       builder: (_, __) => const DriversScreen()),
          GoRoute(path: '/transports',    builder: (_, __) => const TransportsScreen()),
          GoRoute(path: '/operations',    builder: (_, __) => const OperationsScreen()),
          GoRoute(path: '/documents',     builder: (_, __) => const DocumentsScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/reports',       builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/profile',       builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
