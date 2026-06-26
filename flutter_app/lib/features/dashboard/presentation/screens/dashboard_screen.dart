import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../transports/providers/transports_provider.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user        = ref.watch(currentUserProvider);
    final statsAsync  = ref.watch(dashboardStatsProvider);
    final alertsAsync = ref.watch(dashboardAlertsProvider);
    final chartAsync  = ref.watch(dashboardChartProvider);
    final trucksOnMissionAsync = ref.watch(trucksOnMissionProvider);
    final fmt         = NumberFormat('#,###', 'fr_FR');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(dashboardAlertsProvider);
          ref.invalidate(dashboardChartProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── AppBar gradient ─────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: AppTheme.primary,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1B4FD8), Color(0xFF1338A0), Color(0xFF0E7490)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(children: [
                    Positioned(top: -40, right: -20, child: Container(
                      width: 150, height: 150,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05)),
                    )),
                    Positioned(bottom: -30, left: -20, child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05)),
                    )),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Bonjour, ${user?.name.split(' ').first ?? 'Admin'} 👋',
                                style: const TextStyle(color: Colors.white, fontSize: 20,
                                    fontWeight: FontWeight.bold, letterSpacing: -0.3)),
                            const SizedBox(height: 4),
                            Text(user?.company?.name ?? 'Fleet SaaS',
                                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                          ])),
                          alertsAsync.when(
                            data: (alerts) => GestureDetector(
                              onTap: () => context.go('/notifications'),
                              child: Stack(children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: const Icon(Icons.notifications_outlined,
                                      color: Colors.white, size: 22),
                                ),
                                if (alerts.isNotEmpty)
                                  Positioned(top: 4, right: 4, child: Container(
                                    width: 16, height: 16,
                                    decoration: const BoxDecoration(
                                        color: AppTheme.error, shape: BoxShape.circle),
                                    child: Center(child: Text('${alerts.length}',
                                        style: const TextStyle(color: Colors.white,
                                            fontSize: 9, fontWeight: FontWeight.bold))),
                                  )),
                              ]),
                            ),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: statsAsync.when(
                loading: () => const _LoadingDashboard(),
                error: (e, _) => _ErrorWidget(message: '$e',
                    onRetry: () => ref.invalidate(dashboardStatsProvider)),
                data: (stats) {
                  final trucks     = stats['trucks']     as Map<String, dynamic>? ?? {};
                  final drivers    = stats['drivers']    as Map<String, dynamic>? ?? {};
                  final transports = stats['transports'] as Map<String, dynamic>? ?? {};
                  final financials = stats['financials'] as Map<String, dynamic>? ?? {};

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      // ── Bilan financier ───────────────────────────────
                      _SectionTitle(title: '💰 Bilan Financier'),
                      const SizedBox(height: 10),
                      _FinanceCard(
                        recettes: (financials['total_recettes'] as num?)?.toDouble() ?? 0,
                        depenses: (financials['total_depenses'] as num?)?.toDouble() ?? 0,
                        benefice: (financials['benefice'] as num?)?.toDouble() ?? 0,
                        fmt: fmt,
                      ),
                      const SizedBox(height: 20),

                      // ── Stats clés ────────────────────────────────────
                      _SectionTitle(title: '📊 Vue d\'ensemble'),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _StatCard(
                          label: 'Camions',
                          value: '${trucks['total'] ?? 0}',
                          subtitle: '${trucks['available'] ?? 0} dispo',
                          icon: Icons.local_shipping,
                          gradient: AppTheme.primaryGradient,
                          onTap: () => context.go('/trucks'),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(
                          label: 'Chauffeurs',
                          value: '${drivers['total'] ?? 0}',
                          subtitle: '${drivers['available'] ?? 0} dispo',
                          icon: Icons.badge,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF9F67FA)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          onTap: () => context.go('/drivers'),
                        )),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _StatCard(
                          label: 'Transports',
                          value: '${transports['total'] ?? 0}',
                          subtitle: '${transports['active'] ?? 0} en cours',
                          icon: Icons.route,
                          gradient: AppTheme.successGradient,
                          onTap: () => context.go('/transports'),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(
                          label: 'Non payés',
                          value: '${transports['non_paye'] ?? 0}',
                          subtitle: '${fmt.format((transports['montant_non_paye'] as num?)?.toDouble() ?? 0)} F',
                          icon: Icons.payment_outlined,
                          gradient: AppTheme.warningGradient,
                          onTap: () => context.go('/transports'),
                        )),
                      ]),
                      const SizedBox(height: 20),

                      // ── Camions en voyage ──────────────────────────────
                      _SectionTitle(title: '🚛 Camions en voyage'),
                      const SizedBox(height: 10),
                      trucksOnMissionAsync.when(
                        data: (trucks) => trucks.isEmpty
                          ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE8EEFF)),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Row(children: [
                              const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 20),
                              const SizedBox(width: 12),
                              const Expanded(child: Text('Tous les camions sont disponibles ✓',
                                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500))),
                            ]),
                          )
                          : SizedBox(
                            height: 140,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: trucks.length,
                              itemBuilder: (context, idx) {
                                final truck = trucks[idx];
                                // Vrais champs de l'API
                                final plaque = truck['plate_number']?.toString() ?? 'N/A';
                                final brand  = truck['brand']?.toString() ?? '';
                                final activeTransport = truck['active_transport'] as Map<String, dynamic>?;
                                final origine     = activeTransport?['origin']?.toString() ?? '—';
                                final destination = activeTransport?['destination']?.toString() ?? '—';
                                final departureRaw = activeTransport?['actual_departure'] as String?
                                    ?? activeTransport?['scheduled_departure'] as String?;
                                String departureTime = '—';
                                if (departureRaw != null) {
                                  try {
                                    final dt = DateTime.parse(departureRaw).toLocal();
                                    departureTime = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} à ${dt.hour.toString().padLeft(2,'0')}h${dt.minute.toString().padLeft(2,'0')}';
                                  } catch (_) {}
                                }
                                return Padding(
                                  padding: EdgeInsets.only(right: idx == trucks.length - 1 ? 0 : 12),
                                  child: Container(
                                    width: 220,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.warning, width: 1.5),
                                      boxShadow: AppTheme.cardShadow,
                                    ),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                      // Plaque + marque
                                      Row(children: [
                                        Container(width: 8, height: 8,
                                          decoration: const BoxDecoration(color: Color(0xFFEA580C), shape: BoxShape.circle)),
                                        const SizedBox(width: 6),
                                        Text(plaque, style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                                      ]),
                                      if (brand.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(brand, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                      ],
                                      const SizedBox(height: 10),
                                      // Itinéraire
                                      Row(children: [
                                        const Icon(Icons.trip_origin, size: 10, color: AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(origine,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                          overflow: TextOverflow.ellipsis)),
                                      ]),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Column(children: [
                                          Container(width: 1, height: 10, color: const Color(0xFFEA580C)),
                                        ]),
                                      ),
                                      Row(children: [
                                        const Icon(Icons.location_on_rounded, size: 10, color: Color(0xFFEA580C)),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(destination,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEA580C)),
                                          overflow: TextOverflow.ellipsis)),
                                      ]),
                                      const SizedBox(height: 8),
                                      // Date départ
                                      Row(children: [
                                        const Icon(Icons.access_time, size: 10, color: AppTheme.textHint),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(departureTime,
                                          style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                                          overflow: TextOverflow.ellipsis)),
                                      ]),
                                    ]),
                                  ),
                                );
                              },
                            ),
                          ),
                        loading: () => Container(
                          height: 100,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(color: AppTheme.primary),
                        ),
                        error: (_, __) => Container(
                          height: 100,
                          alignment: Alignment.center,
                          child: const Text('Erreur lors du chargement', style: TextStyle(color: AppTheme.error)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Statuts camions ───────────────────────────────
                      _SectionTitle(title: '🚛 Statuts Camions'),
                      const SizedBox(height: 10),
                      _TruckStatusCard(trucks: trucks),
                      const SizedBox(height: 20),

                      // ── Graphique mensuel ─────────────────────────────
                      chartAsync.when(
                        data: (chartData) => chartData.isNotEmpty ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _SectionTitle(title: '📈 Évolution Mensuelle'),
                          const SizedBox(height: 10),
                          _ChartCard(chartData: chartData),
                          const SizedBox(height: 20),
                        ]) : const SizedBox(),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),

                      // ── Alertes ───────────────────────────────────────
                      alertsAsync.when(
                        data: (alerts) => alerts.isEmpty ? const SizedBox() : Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _SectionTitle(title: '🔔 Alertes (${alerts.length})'),
                          const SizedBox(height: 8),
                          ...alerts.take(3).map((a) => _AlertCard(alert: a)),
                          if (alerts.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: () => context.go('/notifications'),
                                  child: Text('Voir toutes les ${alerts.length} alertes',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                        ]),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),

                      // ── Actions rapides ───────────────────────────────
                      _SectionTitle(title: '⚡ Actions Rapides'),
                      const SizedBox(height: 10),
                      _QuickActionsGrid(),
                      const SizedBox(height: 32),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary, letterSpacing: -0.2));
}

class _FinanceCard extends StatelessWidget {
  final double recettes, depenses, benefice;
  final NumberFormat fmt;
  const _FinanceCard({required this.recettes, required this.depenses,
      required this.benefice, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4FD8), Color(0xFF0E7490)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(children: [
          Expanded(child: _FinStat(label: 'Recettes', value: fmt.format(recettes),
              color: const Color(0xFF6EE7B7))),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          Expanded(child: _FinStat(label: 'Dépenses', value: fmt.format(depenses),
              color: const Color(0xFFFCA5A5))),
        ]),
        const SizedBox(height: 16),
        Container(height: 1, color: Colors.white.withOpacity(0.15)),
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.trending_up, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text('Bénéfice Net', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text('${fmt.format(benefice)} FCFA',
              style: TextStyle(
                color: benefice >= 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                fontSize: 18, fontWeight: FontWeight.bold,
              )),
        ]),
      ]),
    );
  }
}

class _FinStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _FinStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 16,
        fontWeight: FontWeight.bold), textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11),
        textAlign: TextAlign.center),
  ]);
}

class _StatCard extends StatelessWidget {
  final String label, value, subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback? onTap;
  const _StatCard({required this.label, required this.value, required this.subtitle,
      required this.icon, required this.gradient, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 4),
          )],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 12),
          ]),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white,
              fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
        ]),
      ),
    );
  }
}

class _TruckStatusCard extends StatelessWidget {
  final Map<String, dynamic> trucks;
  const _TruckStatusCard({required this.trucks});

  @override
  Widget build(BuildContext context) {
    final total = (trucks['total'] as num?)?.toInt() ?? 1;
    final statuses = [
      ('Disponibles', trucks['available'] ?? 0, AppTheme.success, Icons.check_circle_outline),
      ('En mission',  trucks['on_mission'] ?? 0, AppTheme.primary, Icons.local_shipping_outlined),
      ('Maintenance', trucks['maintenance'] ?? 0, AppTheme.warning, Icons.build_outlined),
      ('Hors service',trucks['out_of_service'] ?? 0, AppTheme.error, Icons.cancel_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEFF)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(children: [
        ...statuses.map((s) {
          final count = (s.$2 as num).toInt();
          final pct   = total > 0 ? count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Icon(s.$4, color: s.$3, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(s.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: s.$3)),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: s.$3.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(s.$3),
                    minHeight: 6,
                  ),
                ),
              ])),
            ]),
          );
        }),
      ]),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final List<Map<String, dynamic>> chartData;
  const _ChartCard({required this.chartData});

  @override
  Widget build(BuildContext context) {
    final spots = chartData.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), (e.value['recettes'] as num?)?.toDouble() ?? 0)).toList();
    final spots2 = chartData.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), (e.value['depenses'] as num?)?.toDouble() ?? 0)).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEFF)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Row(children: [
            _Legend(color: AppTheme.success, label: 'Recettes'),
            const SizedBox(width: 16),
            _Legend(color: AppTheme.error, label: 'Dépenses'),
          ]),
        ),
        Expanded(
          child: LineChart(LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 22, interval: 1,
                getTitlesWidget: (v, m) {
                  final i = v.toInt();
                  if (i < 0 || i >= chartData.length) return const SizedBox();
                  final month = chartData[i]['month']?.toString() ?? '';
                  return Text(month.length >= 7 ? month.substring(5) : month,
                      style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary));
                },
              )),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              _chartLine(spots,  AppTheme.success),
              _chartLine(spots2, AppTheme.error),
            ],
          )),
        ),
      ]),
    );
  }

  LineChartBarData _chartLine(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots,
    isCurved: true,
    color: color,
    barWidth: 2.5,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: true,
      color: color.withOpacity(0.08),
    ),
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 12, height: 3, decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
  ]);
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final type = alert['type'] as String? ?? 'info';
    final Color color = type == 'error' ? AppTheme.error : type == 'warning' ? AppTheme.warning : AppTheme.info;
    final IconData icon = type == 'error' ? Icons.error_outline : type == 'warning' ? Icons.warning_amber_outlined : Icons.info_outline;
    final Color bgColor = type == 'error' 
      ? const Color(0xFFFEE2E2) 
      : type == 'warning' 
        ? const Color(0xFFFEF3C7) 
        : color.withOpacity(0.06);
    final Color borderColor = type == 'error' 
      ? const Color(0xFFFCA5A5) 
      : type == 'warning' 
        ? const Color(0xFFFCD34D) 
        : color.withOpacity(0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(
          alert['message']?.toString() ?? '',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
        )),
      ]),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Nouveau transport', Icons.add_road, AppTheme.primary, '/transports/new'),
      ('Ajouter camion',    Icons.local_shipping, const Color(0xFF7C3AED), '/trucks'),
      ('Ajouter chauffeur', Icons.person_add,     AppTheme.success,  '/drivers'),
      ('Rapport mensuel',   Icons.assessment,     AppTheme.warning,  '/operations/rapport'),
      ('Rentabilité',       Icons.bar_chart,      const Color(0xFF0891B2), '/operations/rentabilite'),
      ('Dettes clients',    Icons.people_outline, AppTheme.error,    '/operations/dettes'),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: actions.map((a) => GestureDetector(
        onTap: () => context.push(a.$4),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: a.$3.withOpacity(0.2)),
            boxShadow: [BoxShadow(
              color: a.$3.withOpacity(0.08),
              blurRadius: 8, offset: const Offset(0, 2),
            )],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: a.$3.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(a.$2, color: a.$3, size: 22),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(a.$1, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ),
          ]),
        ),
      )).toList(),
    );
  }
}

class _LoadingDashboard extends StatelessWidget {
  const _LoadingDashboard();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(32),
    child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
  );
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_outlined, size: 56, color: AppTheme.textHint),
      const SizedBox(height: 16),
      Text('Connexion impossible', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      Text(message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Réessayer'),
      ),
    ]),
  );
}
