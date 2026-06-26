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

    // Mobile : Floating Action Bar
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      body: Stack(
        children: [
          // Contenu principal avec padding en bas pour la floating bar
          Positioned.fill(
            bottom: 80,
            child: child,
          ),
          // Floating Navigation Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _FloatingNavBar(
              items: items,
              currentIndex: index,
              onTap: (i) => context.go(items[i].route),
            ),
          ),
        ],
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

// ── Floating Navigation Bar (mobile) ─────────────────────────────────────────
class _FloatingNavBar extends StatefulWidget {
  final List<_NavData> items;
  final int currentIndex;
  final void Function(int) onTap;

  const _FloatingNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<_FloatingNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _menuCtrl;
  late Animation<double> _menuAnim;
  bool _menuOpen = false;

  // 5 items principaux visibles dans la barre
  static const _mainCount = 5;

  @override
  void initState() {
    super.initState();
    _menuCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _menuAnim = CurvedAnimation(parent: _menuCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _menuCtrl.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
    _menuOpen ? _menuCtrl.forward() : _menuCtrl.reverse();
  }

  void _closeMenu() {
    setState(() => _menuOpen = false);
    _menuCtrl.reverse();
  }

  // Items principaux (5 premiers)
  List<_NavData> get _mainItems => widget.items.take(_mainCount).toList();
  // Items secondaires (le reste)
  List<_NavData> get _moreItems =>
      widget.items.skip(_mainCount).toList();

  // L'index actuel est-il dans les "plus" ?
  bool get _isMoreActive => widget.currentIndex >= _mainCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Menu "Plus" (panneau qui monte) ──────────────────────────
        AnimatedBuilder(
          animation: _menuAnim,
          builder: (context, _) {
            if (_menuAnim.value == 0) return const SizedBox.shrink();
            return FadeTransition(
              opacity: _menuAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(_menuAnim),
                child: _MoreMenu(
                  items: _moreItems,
                  startIndex: _mainCount,
                  currentIndex: widget.currentIndex,
                  onTap: (i) {
                    _closeMenu();
                    widget.onTap(i);
                  },
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // ── Barre flottante principale ────────────────────────────────
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1A2744)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B4FD8).withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 5 items principaux
              ..._mainItems.asMap().entries.map((e) {
                final i = e.key;
                final item = e.value;
                final isActive = i == widget.currentIndex && !_menuOpen;
                return Expanded(
                  child: _FloatingNavTile(
                    item: item,
                    isActive: isActive,
                    onTap: () {
                      _closeMenu();
                      widget.onTap(i);
                    },
                  ),
                );
              }),

              // Bouton "Plus"
              Expanded(
                child: _MoreButton(
                  isActive: _isMoreActive || _menuOpen,
                  isOpen: _menuOpen,
                  badge: _moreItems.fold(0, (sum, i) => sum + i.badge),
                  onTap: _toggleMenu,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tile de la barre flottante ────────────────────────────────────────────────
class _FloatingNavTile extends StatelessWidget {
  final _NavData item;
  final bool isActive;
  final VoidCallback onTap;

  const _FloatingNavTile({
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
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.5),
                    AppTheme.accent.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive
              ? [BoxShadow(
                  color: AppTheme.primary.withOpacity(0.5),
                  blurRadius: 12,
                )]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 22,
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                ),
                if (item.badge > 0)
                  Positioned(
                    top: -5, right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 6,
                        )],
                      ),
                      child: Text(
                        item.badge > 9 ? '9+' : '${item.badge}',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bouton "Plus" ─────────────────────────────────────────────────────────────
class _MoreButton extends StatelessWidget {
  final bool isActive;
  final bool isOpen;
  final int badge;
  final VoidCallback onTap;

  const _MoreButton({
    required this.isActive,
    required this.isOpen,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.5),
                    AppTheme.accent.withOpacity(0.3),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive
              ? [BoxShadow(
                  color: AppTheme.primary.withOpacity(0.5),
                  blurRadius: 12,
                )]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedRotation(
                  turns: isOpen ? 0.125 : 0, // Rotation 45° quand ouvert
                  duration: const Duration(milliseconds: 280),
                  child: Icon(
                    Icons.grid_view_rounded,
                    size: 22,
                    color: isActive ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    top: -5, right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Plus',
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Menu "Plus" (panneau qui monte) ──────────────────────────────────────────
class _MoreMenu extends StatelessWidget {
  final List<_NavData> items;
  final int startIndex;
  final int currentIndex;
  final void Function(int) onTap;

  const _MoreMenu({
    required this.items,
    required this.startIndex,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1A2744)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          // Items en grille 2 colonnes
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.2,
            physics: const NeverScrollableScrollPhysics(),
            children: items.asMap().entries.map((e) {
              final i = startIndex + e.key;
              final item = e.value;
              final isActive = i == currentIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: [
                              AppTheme.primary.withOpacity(0.5),
                              AppTheme.accent.withOpacity(0.3),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.06),
                              Colors.white.withOpacity(0.03),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    border: isActive
                        ? Border.all(color: AppTheme.primary.withOpacity(0.5))
                        : Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isActive ? item.activeIcon : item.icon,
                            size: 18,
                            color: isActive ? Colors.white : const Color(0xFF94A3B8),
                          ),
                          if (item.badge > 0)
                            Positioned(
                              top: -4, right: -6,
                              child: Container(
                                width: 14, height: 14,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    item.badge > 9 ? '9+' : '${item.badge}',
                                    style: const TextStyle(
                                      color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: isActive ? Colors.white : const Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
