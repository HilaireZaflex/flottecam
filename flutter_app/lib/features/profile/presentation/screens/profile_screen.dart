import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar avec avatar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 52,
                          backgroundImage: user?.displayAvatar != null
                              ? NetworkImage(user!.displayAvatar!) as ImageProvider
                              : null,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: user?.displayAvatar == null
                              ? Text(
                                  user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user?.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Pill(
                            label: user?.role.toUpperCase() ?? '',
                            color: Colors.white,
                            textColor: AppTheme.primary,
                          ),
                          if (user?.company != null) ...[
                            const SizedBox(width: 8),
                            _Pill(
                              label: user!.company!.name,
                              color: Colors.white.withOpacity(0.2),
                              textColor: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              collapseMode: CollapseMode.parallax,
            ),
            leading: const SizedBox(),
            title: const Text('Mon Profil',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
          ),

          // ── Contenu ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Société
                  if (user?.company != null) ...[
                    _SectionTitle(label: 'Ma Société'),
                    const SizedBox(height: 12),
                    _InfoCard(children: [
                      _InfoRow(
                        icon: Icons.apartment_rounded,
                        iconColor: AppTheme.primary,
                        label: 'Nom de la société',
                        value: user!.company!.name,
                      ),
                      const _Divider(),
                      _InfoRow(
                        icon: Icons.workspace_premium_rounded,
                        iconColor: AppTheme.warning,
                        label: 'Abonnement',
                        value: user.company!.subscriptionPlan.toUpperCase(),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Actif',
                              style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                  ],

                  // Compte
                  _SectionTitle(label: 'Mon Compte'),
                  const SizedBox(height: 12),
                  _InfoCard(children: [
                    if (user?.phone != null)
                      _InfoRow(
                        icon: Icons.phone_rounded,
                        iconColor: AppTheme.accent,
                        label: 'Téléphone',
                        value: user!.phone!,
                      ),
                    if (user?.phone != null) const _Divider(),
                    _InfoRow(
                      icon: Icons.shield_rounded,
                      iconColor: AppTheme.success,
                      label: 'Rôle',
                      value: user?.role.toUpperCase() ?? '',
                    ),
                    const _Divider(),
                    _InfoRow(
                      icon: Icons.verified_rounded,
                      iconColor: AppTheme.info,
                      label: 'Statut du compte',
                      value: (user?.isActive ?? false) ? 'Actif' : 'Inactif',
                      trailing: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: (user?.isActive ?? false) ? AppTheme.success : AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Actions
                  _SectionTitle(label: 'Paramètres'),
                  const SizedBox(height: 12),
                  _ActionCard(children: [
                    _ActionTile(
                      icon: Icons.edit_rounded,
                      iconColor: AppTheme.primary,
                      label: 'Modifier le profil',
                      onTap: () {},
                    ),
                    const _Divider(),
                    _ActionTile(
                      icon: Icons.lock_rounded,
                      iconColor: AppTheme.warning,
                      label: 'Changer le mot de passe',
                      onTap: () {},
                    ),
                    const _Divider(),
                    _ActionTile(
                      icon: Icons.notifications_rounded,
                      iconColor: AppTheme.accent,
                      label: 'Préférences de notifications',
                      onTap: () {},
                    ),
                    const _Divider(),
                    _ActionTile(
                      icon: Icons.help_rounded,
                      iconColor: AppTheme.info,
                      label: 'Aide & Support',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Déconnexion
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.subtleShadow,
                    ),
                    child: _ActionTile(
                      icon: Icons.logout_rounded,
                      iconColor: AppTheme.error,
                      label: 'Se déconnecter',
                      labelColor: AppTheme.error,
                      showChevron: false,
                      onTap: () => _confirmLogout(context, ref),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'FlotteCam v1.0.0',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.logout_rounded, color: AppTheme.error),
          SizedBox(width: 10),
          Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Composants ─────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Pill({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w700)),
  );
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: AppTheme.textPrimary,
      letterSpacing: -0.3,
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppTheme.subtleShadow,
    ),
    child: Column(children: children),
  );
}

class _ActionCard extends StatelessWidget {
  final List<Widget> children;
  const _ActionCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppTheme.subtleShadow,
    ),
    child: Column(children: children),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Widget? trailing;
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ]),
      ),
      if (trailing != null) trailing!,
    ]),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final bool showChevron;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: labelColor ?? AppTheme.textPrimary,
            ),
          ),
        ),
        if (showChevron)
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 22),
      ]),
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 58),
    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
  );
}
