import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';
import '../../features/notifications/providers/notifications_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _index(String loc) {
    if (loc.startsWith('/dashboard'))     return 0;
    if (loc.startsWith('/gps'))           return 1;
    if (loc.startsWith('/trucks'))        return 2;
    if (loc.startsWith('/drivers'))       return 3;
    if (loc.startsWith('/transports'))    return 4;
    if (loc.startsWith('/operations'))    return 5;
    if (loc.startsWith('/documents'))     return 6;
    if (loc.startsWith('/notifications')) return 7;
    if (loc.startsWith('/profile'))       return 8;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc   = GoRouterState.of(context).matchedLocation;
    final badge = ref.watch(notificationBadgeProvider);
    final index = _index(loc);
    final user  = ref.watch(currentUserProvider);

    final items = [
      _NavData(icon: Icons.dashboard_outlined,      activeIcon: Icons.dashboard_rounded,       label: 'Accueil',      route: '/dashboard'),
      _NavData(icon: Icons.map_outlined,            activeIcon: Icons.map_rounded,             label: 'GPS',          route: '/gps'),
      _NavData(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping_rounded,  label: 'Camions',      route: '/trucks'),
      _NavData(icon: Icons.badge_outlined,          activeIcon: Icons.badge_rounded,           label: 'Conducteurs',  route: '/drivers'),
      _NavData(icon: Icons.route_outlined,          activeIcon: Icons.route_rounded,           label: 'Voyages',      route: '/transports'),
      _NavData(icon: Icons.receipt_long_outlined,   activeIcon: Icons.receipt_long_rounded,    label: 'Finance',      route: '/operations'),
      _NavData(icon: Icons.folder_outlined,         activeIcon: Icons.folder_rounded,          label: 'Documents',    route: '/documents'),
      _NavData(icon: Icons.notifications_outlined,  activeIcon: Icons.notifications_rounded,   label: 'Alertes',      route: '/notifications', badge: badge),
      _NavData(icon: Icons.person_outline_rounded,  activeIcon: Icons.person_rounded,          label: 'Profil',       route: '/profile'),
    ];

    // Sur desktop/tablette → navigation latérale élégante
    // Sur mobile → barre de navigation en bas (comportement original)
    final isWide = ResponsiveLayout.isWide(context);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _SideNav(
              items: items,
              currentIndex: index,
              onTap: (i) => context.go(items[i].route),
              userName: user?.name ?? 'FlotteCam',
              userRole: user?.role ?? '',
              userAvatar: user?.displayAvatar ?? '',
              isDesktop: ResponsiveLayout.isDesktop(context),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile : bottom nav bar originale
    return Scaffold(
      body: child,
      bottomNavigationBar: _ElegantNavBar(
        items: items,
        currentIndex: index,
        onTap: (i) => context.go(items[i].route),
      ),
    );
  }
}

class _NavData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final int badge;
  const _NavData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.badge = 0,
  });
}

// ── Navigation latérale (tablette/desktop) ────────────────────────────────────

class _SideNav extends StatelessWidget {
  final List<_NavData> items;
  final int currentIndex;
  final void Function(int) onTap;
  final String userName;
  final String userRole;
  final String userAvatar;
  final bool isDesktop;

  const _SideNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.userName,
    required this.userRole,
    required this.userAvatar,
    required this.isDesktop,
  });

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':   return 'Administrateur';
      case 'manager': return 'Manager';
      default:        return 'Utilisateur';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Desktop → sidebar large avec labels
    // Tablette → rail compact avec icônes seulement
    final width = isDesktop ? 220.0 : 72.0;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Logo + nom app ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 8,
                vertical: 20,
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.local_shipping_rounded,
                        color: Colors.white, size: 22),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'FlotteCam',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(color: Color(0xFF1E293B), height: 1),
            const SizedBox(height: 8),

            // ── Items de navigation ─────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 10 : 6,
                  vertical: 4,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item     = items[i];
                  final isActive = i == currentIndex;
                  return _SideNavTile(
                    item: item,
                    isActive: isActive,
                    isDesktop: isDesktop,
                    onTap: () => onTap(i),
                  );
                },
              ),
            ),

            // ── Profil utilisateur en bas ───────────────────────────────
            const Divider(color: Color(0xFF1E293B), height: 1),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 12 : 8,
                vertical: 12,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: userAvatar.isNotEmpty
                        ? NetworkImage(userAvatar)
                        : null,
                    backgroundColor: AppTheme.primary.withOpacity(0.3),
                    child: userAvatar.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 18)
                        : null,
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _roleLabel(userRole),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNavTile extends StatelessWidget {
  final _NavData item;
  final bool isActive;
  final bool isDesktop;
  final VoidCallback onTap;

  const _SideNavTile({
    required this.item,
    required this.isActive,
    required this.isDesktop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 12 : 8,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.35),
                      AppTheme.accent.withOpacity(0.15),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive ? item.activeIcon : item.icon,
                    size: 20,
                    color: isActive ? Colors.white : const Color(0xFF64748B),
                  ),
                  if (item.badge > 0)
                    Positioned(
                      top: -4, right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: AppTheme.errorGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          item.badge > 9 ? '9+' : '${item.badge}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (isDesktop) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ElegantNavBar extends StatelessWidget {
  final List<_NavData> items;
  final int currentIndex;
  final void Function(int) onTap;

  const _ElegantNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4FD8).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i    = e.key;
              final item = e.value;
              final isActive = i == currentIndex;
              return Expanded(
                child: _NavTile(
                  item: item,
                  isActive: isActive,
                  onTap: () => onTap(i),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavData item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Icône avec glow actif ─────────────────────────────────
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Glow pill derrière l'icône active
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: isActive ? 36 : 0,
                  height: isActive ? 24 : 0,
                  decoration: BoxDecoration(
                    gradient: isActive ? LinearGradient(
                      colors: [AppTheme.primary.withOpacity(0.55), AppTheme.accent.withOpacity(0.35)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ) : null,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isActive ? [
                      BoxShadow(color: AppTheme.primary.withOpacity(0.55), blurRadius: 10),
                    ] : [],
                  ),
                ),
                // Icône + badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isActive ? item.activeIcon : item.icon,
                      size: 19,
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                    ),
                    if (item.badge > 0)
                      Positioned(
                        top: -4, right: -7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            gradient: AppTheme.errorGradient,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [BoxShadow(color: AppTheme.error.withOpacity(0.5), blurRadius: 5)],
                          ),
                          child: Text(
                            item.badge > 9 ? '9+' : '${item.badge}',
                            style: const TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 3),
            // ── Label ─────────────────────────────────────────────────
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? Colors.white : const Color(0xFF475569),
                letterSpacing: isActive ? 0.2 : 0,
              ),
            ),
            const SizedBox(height: 3),
            // ── Barre indicateur ───────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isActive ? 14 : 0,
              height: 2,
              decoration: BoxDecoration(
                gradient: isActive ? const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                ) : null,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isActive
                    ? [BoxShadow(color: AppTheme.primary.withOpacity(0.7), blurRadius: 6)]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
