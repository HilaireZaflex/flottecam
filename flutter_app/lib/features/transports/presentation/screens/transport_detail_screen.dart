import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/transports_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class TransportDetailScreen extends ConsumerWidget {
  final int transportId;
  const TransportDetailScreen({super.key, required this.transportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transportAsync = ref.watch(transportDetailProvider(transportId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Détail Transport',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryColor),
          onPressed: () => context.canPop() ? context.pop() : context.go('/transports'),
        ),
      ),
      body: transportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error:   (e, _) => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.errorColor.withOpacity(0.1)),
              child: const Icon(Icons.error_outline_rounded, size: 40, color: AppTheme.errorColor),
            ),
            const SizedBox(height: 16),
            Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        )),
        data: (transport) {
          final statusColor = AppTheme.statusColor(transport.status);
          final fmt = NumberFormat('#,###', 'fr_FR');
          return SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Hero Header gradient ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor.withOpacity(0.18), AppTheme.background],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Badge statut
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.4)),
                      ),
                      child: Row(children: [
                        Icon(_statusIcon(transport.status), size: 13, color: statusColor),
                        const SizedBox(width: 5),
                        Text(AppConstants.transportStatuses[transport.status] ?? transport.status,
                            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    const Spacer(),
                    Text('#${transport.id}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ]),
                  const SizedBox(height: 12),
                  Text(transport.reference,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 20),

                  // Trajet visuel amélioré
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(
                            color: AppTheme.successColor, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppTheme.successColor.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)],
                          )),
                          Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [AppTheme.successColor, AppTheme.errorColor],
                                    begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                borderRadius: BorderRadius.circular(2),
                              ))),
                          Container(width: 12, height: 12, decoration: BoxDecoration(
                            color: AppTheme.errorColor, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppTheme.errorColor.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)],
                          )),
                        ]),
                        const SizedBox(width: 16),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('DÉPART', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.successColor, letterSpacing: 1)),
                              const SizedBox(height: 3),
                              Text(transport.origin, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                            ]),
                            const SizedBox(height: 16),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('ARRIVÉE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.errorColor, letterSpacing: 1)),
                              const SizedBox(height: 3),
                              Text(transport.destination, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                            ]),
                          ],
                        )),
                      ]),
                    ),
                  ),

                  // Montant
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(children: [
                      const Icon(Icons.payments_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Montant', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('${fmt.format(transport.montantTransport ?? 0)} FCFA',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      ]),
                      const Spacer(),
                      _PaiementBadgeDetail(statut: transport.statutPaiement ?? 'non_paye'),
                    ]),
                  ),
                ]),
              ),

              // ── Sections détails ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(children: [

                  // Marchandise
                  _DetailSection(
                    title: 'Marchandise',
                    icon: Icons.inventory_2_rounded,
                    iconColor: Colors.orange,
                    child: Column(children: [
                      _InfoRowNew(icon: Icons.category_rounded, label: 'Type', value: transport.cargoType),
                      if (transport.cargoWeight != null) ...[
                        const SizedBox(height: 10),
                        _InfoRowNew(icon: Icons.scale_rounded, label: 'Poids', value: '${transport.cargoWeight} tonnes'),
                      ],
                      if (transport.clientName != null) ...[
                        const SizedBox(height: 10),
                        _InfoRowNew(icon: Icons.business_rounded, label: 'Client', value: transport.clientName!),
                      ],
                      if (transport.clientPhone != null) ...[
                        const SizedBox(height: 10),
                        _InfoRowNew(icon: Icons.phone_rounded, label: 'Téléphone', value: transport.clientPhone!),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // Véhicule & Chauffeur
                  _DetailSection(
                    title: 'Véhicule & Chauffeur',
                    icon: Icons.local_shipping_rounded,
                    iconColor: Colors.blueGrey,
                    child: Column(children: [
                      if (transport.truck != null)
                        _InfoRowNew(icon: Icons.directions_car_rounded, label: 'Camion',
                            value: '${transport.truck!.brand} ${transport.truck!.model} · ${transport.truck!.plateNumber}'),
                      if (transport.driver != null) ...[
                        const SizedBox(height: 10),
                        _InfoRowNew(icon: Icons.person_rounded, label: 'Chauffeur', value: transport.driver!.fullName),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // Horaires
                  _DetailSection(
                    title: 'Horaires',
                    icon: Icons.schedule_rounded,
                    iconColor: Colors.purple,
                    child: Column(children: [
                      if (transport.scheduledDeparture != null)
                        _InfoRowNew(icon: Icons.departure_board_rounded, label: 'Départ prévu', value: transport.scheduledDeparture!),
                      if (transport.scheduledArrival != null) ...[
                        const SizedBox(height: 10),
                        _InfoRowNew(icon: Icons.flight_land_rounded, label: 'Arrivée prévue', value: transport.scheduledArrival!),
                      ],
                      if (transport.actualDeparture != null) ...[
                        const SizedBox(height: 10),
                        _InfoRowNew(icon: Icons.play_circle_rounded, label: 'Départ réel', value: transport.actualDeparture!, color: AppTheme.successColor),
                      ],
                      if (transport.actualArrival != null) ...[
                        const SizedBox(height: 10),
                        _InfoRowNew(icon: Icons.check_circle_rounded, label: 'Arrivée réelle', value: transport.actualArrival!, color: AppTheme.successColor),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Actions ─────────────────────────────────────────────
                  if (transport.isPending)
                    _ActionButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'Démarrer le transport',
                      color: AppTheme.successColor,
                      onTap: () async {
                        await ref.read(transportsProvider('').notifier).updateStatus(transport.id, 'in_progress');
                        ref.invalidate(transportDetailProvider(transport.id));
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transport démarré ✅'), backgroundColor: AppTheme.successColor));
                      },
                    ),
                  if (transport.isInProgress) ...[
                    _ActionButton(
                      icon: Icons.check_circle_rounded,
                      label: 'Marquer comme terminé',
                      color: AppTheme.primaryColor,
                      onTap: () async {
                        await ref.read(transportsProvider('').notifier).updateStatus(transport.id, 'completed');
                        ref.invalidate(transportDetailProvider(transport.id));
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transport terminé ✅'), backgroundColor: AppTheme.successColor));
                      },
                    ),
                    const SizedBox(height: 12),
                    _ActionButton(
                      icon: Icons.payments_rounded,
                      label: 'Enregistrer le paiement',
                      color: AppTheme.warningColor,
                      outlined: true,
                      onTap: () => _showPaiementDialog(context, ref, transport.id),
                    ),
                  ],
                  if (transport.status == 'completed' && transport.statutPaiement != 'paye')
                    _ActionButton(
                      icon: Icons.payments_rounded,
                      label: 'Enregistrer le paiement',
                      color: AppTheme.successColor,
                      onTap: () => _showPaiementDialog(context, ref, transport.id),
                    ),
                  const SizedBox(height: 8),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }
}

void _showPaiementDialog(BuildContext context, WidgetRef ref, int transportId) {
  final montantCtrl = TextEditingController();
  String statutPaiement = 'paye';

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Enregistrer le paiement',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: statutPaiement,
              decoration: InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), 
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
              ),
              items: const [
                DropdownMenuItem(value: 'paye',    child: Text('Payé intégralement')),
                DropdownMenuItem(value: 'partiel', child: Text('Paiement partiel')),
              ],
              onChanged: (v) => setState(() => statutPaiement = v!),
            ),
            const SizedBox(height: 16),
            if (statutPaiement == 'partiel')
              TextField(
                controller: montantCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant reçu (FCFA)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final montantPaye = statutPaiement == 'partiel'
                  ? double.tryParse(montantCtrl.text) ?? 0
                  : null;
              await ref.read(transportsProvider('').notifier).updatePaiement(
                transportId, statutPaiement,
                montantPaye: montantPaye,
              );
              ref.invalidate(transportDetailProvider(transportId));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paiement enregistré ✅'), backgroundColor: AppTheme.successColor),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'in_progress': return Icons.play_circle_filled_rounded;
    case 'completed':   return Icons.check_circle_rounded;
    case 'cancelled':   return Icons.cancel_rounded;
    case 'delayed':     return Icons.warning_rounded;
    default:            return Icons.access_time_rounded;
  }
}

class _PaiementBadgeDetail extends StatelessWidget {
  final String statut;
  const _PaiementBadgeDetail({required this.statut});
  @override
  Widget build(BuildContext context) {
    Color color; String label; IconData icon;
    switch (statut) {
      case 'paye':    color = AppTheme.successColor; label = 'Payé';     icon = Icons.check_circle_rounded; break;
      case 'partiel': color = AppTheme.warningColor; label = 'Partiel';  icon = Icons.schedule_rounded; break;
      default:        color = AppTheme.errorColor;   label = 'Non payé'; icon = Icons.cancel_rounded; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  const _DetailSection({required this.title, required this.icon, required this.child, this.iconColor = AppTheme.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

class _InfoRowNew extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? color;
  const _InfoRowNew({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      width: 30, height: 30,
      decoration: BoxDecoration(color: (color ?? AppTheme.primaryColor).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: color ?? AppTheme.primaryColor),
    ),
    const SizedBox(width: 12),
    SizedBox(width: 90, child: Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
    )),
    Expanded(child: Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color ?? AppTheme.textPrimary)),
    )),
  ]);
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: Icon(icon),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onTap,
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          shadowColor: color.withOpacity(0.4),
        ),
        onPressed: onTap,
      ),
    );
  }
}
