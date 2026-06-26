import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notifications_provider.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Alertes & Notifications',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3)),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Tout lire', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(notificationsProvider.notifier).refresh(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(onRetry: () => ref.read(notificationsProvider.notifier).refresh()),
        data: (notifications) {
          if (notifications.isEmpty) return const _EmptyState();

          final errors   = notifications.where((n) => n.type == 'error').toList();
          final warnings = notifications.where((n) => n.type == 'warning').toList();
          final infos    = notifications.where((n) => n.type != 'error' && n.type != 'warning').toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
            color: AppTheme.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (errors.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Urgent',
                    count: errors.length,
                    color: AppTheme.error,
                    icon: Icons.error_rounded,
                  ),
                  const SizedBox(height: 10),
                  ...errors.map((n) => _NotifCard(
                    notif: n,
                    index: notifications.indexOf(n),
                    onTap: () => _navigate(context, n),
                    onMarkRead: () => ref.read(notificationsProvider.notifier).markRead(notifications.indexOf(n)),
                  )),
                  const SizedBox(height: 20),
                ],
                if (warnings.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Attention',
                    count: warnings.length,
                    color: AppTheme.warning,
                    icon: Icons.warning_amber_rounded,
                  ),
                  const SizedBox(height: 10),
                  ...warnings.map((n) => _NotifCard(
                    notif: n,
                    index: notifications.indexOf(n),
                    onTap: () => _navigate(context, n),
                    onMarkRead: () => ref.read(notificationsProvider.notifier).markRead(notifications.indexOf(n)),
                  )),
                  const SizedBox(height: 20),
                ],
                if (infos.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Informations',
                    count: infos.length,
                    color: AppTheme.info,
                    icon: Icons.info_rounded,
                  ),
                  const SizedBox(height: 10),
                  ...infos.map((n) => _NotifCard(
                    notif: n,
                    index: notifications.indexOf(n),
                    onTap: () => _navigate(context, n),
                    onMarkRead: () => ref.read(notificationsProvider.notifier).markRead(notifications.indexOf(n)),
                  )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigate(BuildContext context, NotificationItem notif) {
    switch (notif.entity) {
      case 'truck':     context.push('/trucks'); break;
      case 'driver':    context.push('/drivers'); break;
      case 'transport': context.push('/transports/detail/${notif.id}'); break;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _SectionHeader({required this.label, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    ),
    const SizedBox(width: 10),
    Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15, letterSpacing: -0.2)),
    const SizedBox(width: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$count', style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 12)),
    ),
  ]);
}

class _NotifCard extends StatelessWidget {
  final NotificationItem notif;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  const _NotifCard({required this.notif, required this.index, required this.onTap, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final color = notif.type == 'error'
        ? AppTheme.error
        : notif.type == 'warning'
            ? AppTheme.warning
            : AppTheme.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: notif.isRead
            ? Border.all(color: const Color(0xFFF1F5F9))
            : Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: notif.isRead ? AppTheme.subtleShadow : [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconData(notif.icon), color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (!notif.isRead)
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(
                  notif.message,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      notif.entity.isNotEmpty ? notif.entity.toUpperCase() : 'SYSTÈME',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                    ),
                  ),
                  const Spacer(),
                  if (!notif.isRead)
                    GestureDetector(
                      onTap: onMarkRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(children: [
                          Icon(Icons.check_rounded, size: 14, color: AppTheme.success),
                          SizedBox(width: 4),
                          Text('Lu', style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  IconData _iconData(String icon) {
    switch (icon) {
      case 'security':  return Icons.security_rounded;
      case 'build':     return Icons.build_rounded;
      case 'badge':     return Icons.badge_rounded;
      case 'warning':   return Icons.warning_amber_rounded;
      case 'payments':  return Icons.payments_rounded;
      default:          return Icons.notifications_rounded;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.success.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.notifications_active_rounded, size: 64, color: AppTheme.success),
      ),
      const SizedBox(height: 20),
      const Text('Tout est en ordre !',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      const SizedBox(height: 8),
      const Text('Aucune alerte active pour le moment',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
    ]),
  );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, size: 64, color: AppTheme.error),
      const SizedBox(height: 16),
      const Text('Impossible de charger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Réessayer'),
      ),
    ]),
  );
}
