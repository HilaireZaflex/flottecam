import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/data/models/driver_model.dart';
import '../../../auth/data/models/transport_model.dart';
import '../../../auth/data/models/document_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/drivers_provider.dart';
import 'drivers_screen.dart' show showDriverFormSheet;

// ── Providers ─────────────────────────────────────────────────────────────

final driverDetailProvider = FutureProvider.family<DriverModel, int>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final r = await api.get('/drivers/$id');
  return DriverModel.fromJson((r.data as Map<String, dynamic>)['driver'] as Map<String, dynamic>);
});

final driverTransportsProvider = FutureProvider.family<List<TransportModel>, int>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final r = await api.get('/transports', params: {'driver_id': id, 'per_page': 50});
  final data = r.data as Map<String, dynamic>;
  return (data['data'] as List).map((e) => TransportModel.fromJson(e as Map<String,dynamic>)).toList();
});

final driverDocumentsProvider = FutureProvider.family<List<DocumentModel>, int>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final r = await api.get('/documents', params: {'driver_id': id});
  final data = r.data;
  final list = (data is Map ? (data['documents'] ?? data['data'] ?? []) : data) as List;
  return list.map((e) => DocumentModel.fromJson(e as Map<String,dynamic>)).toList();
});

// ── Screen ────────────────────────────────────────────────────────────────

class DriverDetailScreen extends ConsumerStatefulWidget {
  final int driverId;
  const DriverDetailScreen({super.key, required this.driverId});

  @override
  ConsumerState<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends ConsumerState<DriverDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le chauffeur'),
        content: const Text('Cette action est irréversible. Confirmer ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(driversProvider('').notifier).deleteDriver(widget.driverId);
      if (context.mounted) context.go('/drivers');
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverAsync = ref.watch(driverDetailProvider(widget.driverId));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Détail Chauffeur',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        actions: [
          if (driverAsync.hasValue) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppTheme.primary),
              tooltip: 'Modifier',
              onPressed: () => showDriverFormSheet(context, ref, driver: driverAsync.value),
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: AppTheme.error),
              tooltip: 'Supprimer',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.info_rounded, size: 20), text: 'Infos'),
            Tab(icon: Icon(Icons.local_shipping_rounded, size: 20), text: 'Camion'),
            Tab(icon: Icon(Icons.route_rounded, size: 20), text: 'Voyages'),
            Tab(icon: Icon(Icons.description_rounded, size: 20), text: 'Docs'),
          ],
        ),
      ),
      body: driverAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
              ),
              const SizedBox(height: 16),
              const Text('Une erreur est survenue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.refresh(driverDetailProvider(widget.driverId)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        data: (driver) => TabBarView(
          controller: _tabController,
          children: [
            _InfoTab(driver: driver),
            _TruckTab(driver: driver),
            _TransportsTab(driverId: widget.driverId),
            _DocumentsTab(driverId: widget.driverId),
          ],
        ),
      ),
    );
  }
}

// ── Onglet 1: Infos ───────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final DriverModel driver;
  const _InfoTab({required this.driver});

  @override
  Widget build(BuildContext context) {
    final isLicenseExpired = _isDateExpired(driver.licenseExpiry);
    final isLicenseExpiringSoon = _isDateExpiringSoon(driver.licenseExpiry);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar et nom header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    _getInitials(driver.firstName, driver.lastName),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  driver.fullName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                _StatusBadge(status: driver.status),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact section
          _InfoSection(
            title: 'Contact',
            icon: Icons.contact_mail_rounded,
            children: [
              _InfoRow(label: 'Téléphone', value: driver.phone, icon: Icons.phone_rounded),
              if (driver.email != null)
                _InfoRow(label: 'Email', value: driver.email!, icon: Icons.email_rounded),
            ],
          ),
          const SizedBox(height: 20),

          // Permis section
          _InfoSection(
            title: 'Permis de conduire',
            icon: Icons.badge_rounded,
            children: [
              _InfoRow(label: 'N° Permis', value: driver.licenseNumber, icon: Icons.badge_rounded),
              _InfoRow(label: 'Type', value: driver.licenseType, icon: Icons.credit_card_rounded),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: 10),
                        Text('Expiration', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          _formatDate(driver.licenseExpiry),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(width: 12),
                        if (isLicenseExpired)
                          _ExpiryBadge(label: 'Expiré', color: AppTheme.error)
                        else if (isLicenseExpiringSoon)
                          _ExpiryBadge(label: 'Expire bientôt', color: AppTheme.warning)
                        else
                          _ExpiryBadge(label: 'Valide', color: AppTheme.success),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Infos personnelles section
          _InfoSection(
            title: 'Infos personnelles',
            icon: Icons.person_rounded,
            children: [
              if (driver.dateOfBirth != null)
                _InfoRow(label: 'Date de naissance', value: _formatDate(driver.dateOfBirth!), icon: Icons.cake_rounded),
              if (driver.address != null)
                _InfoRow(label: 'Adresse', value: driver.address!, icon: Icons.home_rounded),
              if (driver.city != null)
                _InfoRow(label: 'Ville', value: driver.city!, icon: Icons.location_city_rounded),
              if (driver.country != null)
                _InfoRow(label: 'Pays', value: driver.country!, icon: Icons.public_rounded),
            ],
          ),
          const SizedBox(height: 20),

          // Notes section
          if (driver.notes != null && driver.notes!.isNotEmpty)
            _InfoSection(
              title: 'Notes',
              icon: Icons.note_rounded,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 1),
                  ),
                  child: Text(
                    driver.notes!,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.5),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _getInitials(String firstName, String lastName) {
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  bool _isDateExpired(String date) {
    try {
      return DateTime.parse(date).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool _isDateExpiringSoon(String date) {
    try {
      final expiry = DateTime.parse(date);
      final daysUntilExpiry = expiry.difference(DateTime.now()).inDays;
      return daysUntilExpiry > 0 && daysUntilExpiry <= 30;
    } catch (_) {
      return false;
    }
  }
}

// ── Onglet 2: Camion assigné ──────────────────────────────────────────────
class _TruckTab extends ConsumerWidget {
  final DriverModel driver;
  const _TruckTab({required this.driver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final truck = driver.truck;

    if (truck == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping_rounded, size: 56, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun camion assigné',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Assignez un camion pour commencer',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_rounded),
              label: const Text('Assigner un camion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _assignTruck(context, ref),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Truck card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête camion with gradient
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.local_shipping_rounded, color: AppTheme.accent, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              truck['plate_number'] ?? '—',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${truck['brand'] ?? ''} ${truck['model'] ?? ''}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new_rounded, color: AppTheme.primary),
                        tooltip: 'Voir détail camion',
                        onPressed: () => context.push('/trucks/${truck['id']}'),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Truck info rows
                  _InfoRow(icon: Icons.confirmation_number_rounded, label: 'Immatriculation', value: truck['plate_number'] ?? '—'),
                  _InfoRow(icon: Icons.person_rounded, label: 'Propriétaire', value: truck['proprietaire'] ?? '—'),
                  _InfoRow(icon: Icons.phone_rounded, label: 'Tél propriétaire', value: truck['telephone_proprietaire'] ?? '—'),
                  _InfoRow(icon: Icons.location_city_rounded, label: 'Ville actuelle', value: truck['ville_actuelle'] ?? '—'),
                  _InfoRow(icon: Icons.speed_rounded, label: 'Kilométrage', value: '${truck['mileage'] ?? 0} km'),
                  _InfoRow(icon: Icons.local_gas_station_rounded, label: 'Carburant', value: truck['fuel_type'] ?? '—'),
                  // Status badge
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.circle_rounded, size: 12, color: AppTheme.statusColor(truck['status'] ?? 'available')),
                        const SizedBox(width: 10),
                        Text('Statut : ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.statusColor(truck['status'] ?? 'available').withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.statusColor(truck['status'] ?? 'available').withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            truck['status'] ?? '—',
                            style: TextStyle(
                              color: AppTheme.statusColor(truck['status'] ?? 'available'),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Changer de camion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _assignTruck(context, ref),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.link_off_rounded),
              label: const Text('Retirer ce camion'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final api = ref.read(apiClientProvider);
                await api.patch('/drivers/${driver.id}', data: {'current_truck_id': null});
                ref.invalidate(driverDetailProvider(driver.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camion retiré ✅'), backgroundColor: AppTheme.success),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _assignTruck(BuildContext context, WidgetRef ref) async {
    final api = ref.read(apiClientProvider);
    final resp = await api.get('/trucks', params: {'status': 'available'});
    final trucks = ((resp.data['data'] ?? []) as List);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(children: [
        const Padding(padding: EdgeInsets.all(16),
            child: Text('Sélectionner un camion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        ...trucks.map((t) => ListTile(
          leading: const Icon(Icons.local_shipping, color: Colors.orange),
          title: Text(t['plate_number'] ?? ''),
          subtitle: Text('${t['brand'] ?? ''} ${t['model'] ?? ''}'),
          onTap: () async {
            Navigator.pop(context);
            await api.patch('/drivers/${driver.id}', data: {'current_truck_id': t['id']});
            ref.invalidate(driverDetailProvider(driver.id));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Camion assigné ✅'), backgroundColor: Colors.green),
              );
            }
          },
        )),
      ]),
    );
  }
}


// ── Onglet 2: Transports ──────────────────────────────────────────────────

class _TransportsTab extends ConsumerWidget {
  final int driverId;
  const _TransportsTab({required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transportsAsync = ref.watch(driverTransportsProvider(driverId));

    return transportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
            ),
            const SizedBox(height: 16),
            const Text('Une erreur est survenue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(driverTransportsProvider(driverId)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      data: (transports) {
        if (transports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.route_rounded, size: 48, color: AppTheme.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Aucun transport',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Les transports effectués apparaîtront ici',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          backgroundColor: Colors.white,
          color: AppTheme.primary,
          onRefresh: () => ref.refresh(driverTransportsProvider(driverId).future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: transports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _TransportCard(transport: transports[i]),
          ),
        );
      },
    );
  }
}

class _TransportCard extends StatelessWidget {
  final TransportModel transport;
  const _TransportCard({required this.transport});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with reference and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transport.reference,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                  ),
                ),
                _StatusBadge(status: transport.status),
              ],
            ),
            const SizedBox(height: 12),
            // Route info
            Row(
              children: [
                Icon(Icons.route_rounded, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Itinéraire',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      Text(
                        '${transport.origin} → ${transport.destination}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Date and truck info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (transport.scheduledDeparture != null)
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Départ: ${_formatDate(transport.scheduledDeparture!)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                if (transport.truck != null)
                  Row(
                    children: [
                      Icon(Icons.local_shipping_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        transport.truck!.plateNumber,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
}

// ── Onglet 3: Documents ───────────────────────────────────────────────────

class _DocumentsTab extends ConsumerWidget {
  final int driverId;
  const _DocumentsTab({required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(driverDocumentsProvider(driverId));

    return documentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
            ),
            const SizedBox(height: 16),
            const Text('Une erreur est survenue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(driverDocumentsProvider(driverId)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      data: (documents) {
        // Filtrer les documents du chauffeur
        final driverDocs = documents.where((d) => d.documentableType.contains('Driver')).toList();

        if (driverDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.description_rounded, size: 48, color: AppTheme.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Aucun document',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Les documents apparaîtront ici',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // Trier : expirés en premier, puis bientôt, puis valides
        final sorted = [...driverDocs]..sort((a, b) {
          const order = {'expired': 0, 'expiring_soon': 1, 'valid': 2, 'permanent': 3};
          return (order[a.status] ?? 4).compareTo(order[b.status] ?? 4);
        });

        return RefreshIndicator(
          backgroundColor: Colors.white,
          color: AppTheme.primary,
          onRefresh: () => ref.refresh(driverDocumentsProvider(driverId).future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _DocumentCard(doc: sorted[i]),
          ),
        );
      },
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentModel doc;
  const _DocumentCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (doc.status) {
      case 'expired':
        statusColor = AppTheme.error;
        statusIcon = Icons.error_rounded;
        statusLabel = 'Expiré';
        break;
      case 'expiring_soon':
        statusColor = AppTheme.warning;
        statusIcon = Icons.warning_amber_rounded;
        statusLabel = 'Expire bientôt';
        break;
      case 'permanent':
        statusColor = AppTheme.accent;
        statusIcon = Icons.all_inclusive_rounded;
        statusLabel = 'Permanent';
        break;
      default:
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Valide';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Document icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_docIcon(doc.type), color: statusColor, size: 24),
            ),
            const SizedBox(width: 12),
            // Document info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doc.typeLabel,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  if (doc.expiryDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Expire : ${_formatDate(doc.expiryDate!)}',
                      style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Status badge
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _docIcon(String type) {
    switch (type) {
      case 'assurance':
        return Icons.security;
      case 'carte_grise':
        return Icons.article_outlined;
      case 'visite_technique':
        return Icons.build_circle_outlined;
      case 'vignette':
        return Icons.local_offer_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
}

// ── Widgets utilitaires ───────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    final label = _statusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    const labels = {
      'available': 'Disponible',
      'on_mission': 'En mission',
      'maintenance': 'Maintenance',
      'out_of_service': 'Hors service',
      'on_leave': 'En congé',
      'inactive': 'Inactif',
      'pending': 'En attente',
      'in_progress': 'En cours',
      'completed': 'Complété',
      'cancelled': 'Annulé',
      'delayed': 'Retardé',
    };
    return labels[status] ?? status;
  }
}

class _ExpiryBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ExpiryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final IconData? icon;
  const _InfoSection({required this.title, required this.children, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppTheme.primary),
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  const _InfoRow({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
          ],
          Text(
            '$label ',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
