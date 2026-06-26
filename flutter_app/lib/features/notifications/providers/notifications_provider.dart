import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class NotificationItem {
  final String type;   // 'error' | 'warning' | 'info'
  final String icon;
  final String title;
  final String message;
  final String entity; // 'truck' | 'driver' | 'transport'
  final int id;
  bool isRead;

  NotificationItem({
    required this.type,
    required this.icon,
    required this.title,
    required this.message,
    required this.entity,
    required this.id,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    type:    json['type']    as String? ?? 'info',
    icon:    json['icon']    as String? ?? 'notifications',
    title:   json['title']   as String? ?? '',
    message: json['message'] as String? ?? '',
    entity:  json['entity']  as String? ?? '',
    id:      json['id']      as int? ?? 0,
  );
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<NotificationItem>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AsyncNotifier<List<NotificationItem>> {
  @override
  Future<List<NotificationItem>> build() async {
    return _fetch();
  }

  Future<List<NotificationItem>> _fetch() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/dashboard/alerts');
    final data = response.data as Map<String, dynamic>;
    return (data['alerts'] as List)
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch());
  }

  void markRead(int index) {
    final current = state.value ?? [];
    if (index < current.length) {
      current[index].isRead = true;
      state = AsyncData([...current]);
    }
  }

  void markAllRead() {
    final current = state.value ?? [];
    for (final n in current) n.isRead = true;
    state = AsyncData([...current]);
  }
}

// Badge count provider
final notificationBadgeProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
