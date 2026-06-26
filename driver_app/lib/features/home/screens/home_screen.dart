import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_provider.dart';
import '../../trips/screens/trips_screen.dart';
import '../../expenses/screens/expenses_screen.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  final _pages = const [
    _DashboardPage(),
    TripsScreen(),
    ExpensesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: const Color(0xFF1B4FD8).withOpacity(0.1),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route_rounded), label: 'Voyages'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Dépenses'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}

class _DashboardPage extends ConsumerWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final name = '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}'.trim();
    final tripsAsync = ref.watch(myTripsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(slivers: [
        // AppBar
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          backgroundColor: const Color(0xFF1B4FD8),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1B4FD8), Color(0xFF3B82F6)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bonjour, ${name.isEmpty ? 'Chauffeur' : name.split(' ').first} 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Bienvenue sur FlotteCam',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ]),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildListDelegate([
            // Stats voyages
            tripsAsync.when(
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
              data: (trips) {
                final total     = trips.length;
                final enCours   = trips.where((t) => t['status'] == 'in_progress').length;
                final termines  = trips.where((t) => t['status'] == 'completed').length;

                return Column(children: [
                  Row(children: [
                    _StatCard(label: 'Total voyages', value: '$total',
                      icon: Icons.route_rounded, color: const Color(0xFF1B4FD8)),
                    const SizedBox(width: 12),
                    _StatCard(label: 'En cours', value: '$enCours',
                      icon: Icons.local_shipping_rounded, color: const Color(0xFFEA580C)),
                    const SizedBox(width: 12),
                    _StatCard(label: 'Terminés', value: '$termines',
                      icon: Icons.check_circle_rounded, color: const Color(0xFF16A34A)),
                  ]),
                  const SizedBox(height: 20),

                  // Voyage actif
                  if (enCours > 0) ...[
                    const _SectionTitle(title: '🚛 Voyage en cours'),
                    const SizedBox(height: 8),
                    ...trips.where((t) => t['status'] == 'in_progress').map((t) =>
                      _ActiveTripCard(trip: t)),
                    const SizedBox(height: 16),
                  ],

                  // Derniers voyages
                  const _SectionTitle(title: '📋 Derniers voyages'),
                  const SizedBox(height: 8),
                  if (trips.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Aucun voyage', style: TextStyle(color: Color(0xFF94A3B8))),
                    ))
                  else
                    ...trips.take(3).map((t) => _RecentTripRow(trip: t)),
                ]);
              },
            ),
          ])),
        ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _ActiveTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _ActiveTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final origin      = trip['origin']      as String? ?? '—';
    final destination = trip['destination'] as String? ?? '—';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1917),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Icon(Icons.local_shipping_rounded, color: Color(0xFFFBBF24), size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$origin → $destination',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 2),
          const Text('En cours', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 12)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B7280)),
      ]),
    );
  }
}

class _RecentTripRow extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _RecentTripRow({required this.trip});

  @override
  Widget build(BuildContext context) {
    final origin      = trip['origin']      as String? ?? '—';
    final destination = trip['destination'] as String? ?? '—';
    final status      = trip['status']      as String? ?? '';
    final color = status == 'completed' ? const Color(0xFF16A34A)
                : status == 'in_progress' ? const Color(0xFFEA580C)
                : const Color(0xFF94A3B8);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text('$origin → $destination',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)));
}
