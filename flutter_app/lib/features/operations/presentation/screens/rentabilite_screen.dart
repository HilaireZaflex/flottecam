import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/operations_provider.dart';
import '../../../../core/theme/app_theme.dart';

// Helper pour parser les valeurs numériques (String ou num) retournées par MySQL
double _parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

class RentabiliteScreen extends ConsumerWidget {
  const RentabiliteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentaAsync  = ref.watch(rentabiliteParCamionProvider);
    final catAsync    = ref.watch(depensesParCategorieProvider);
    final dettesAsync = ref.watch(clientDettesProvider);
    final fmt         = NumberFormat('#,##0', 'fr_FR');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Rentabilité & Analyses',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.assessment_rounded, color: AppTheme.primary, size: 18),
            ),
            tooltip: 'Rapport Mensuel',
            onPressed: () => context.push('/operations/rapport'),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people_rounded, color: AppTheme.warning, size: 18),
            ),
            tooltip: 'Dettes Clients',
            onPressed: () => context.push('/operations/dettes'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: () {
              ref.invalidate(rentabiliteParCamionProvider);
              ref.invalidate(depensesParCategorieProvider);
              ref.invalidate(clientDettesProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          ref.invalidate(rentabiliteParCamionProvider);
          ref.invalidate(depensesParCategorieProvider);
          ref.invalidate(clientDettesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [

            // ── Section 1 : Rentabilité par camion ──────────────────────────
            _SectionHeader(icon: Icons.local_shipping_rounded, title: 'Rentabilité par camion', color: AppTheme.primary),
            const SizedBox(height: 12),
            rentaAsync.when(
              loading: () => const _LoadingCard(),
              error:   (e, _) => _ErrorCard(message: '$e'),
              data:    (trucks) {
                if (trucks.isEmpty) return const _EmptyCard(label: 'Aucun camion trouvé');
                return Column(
                  children: trucks.map((t) => _TruckRentaCard(truck: t, fmt: fmt)).toList(),
                );
              },
            ),
            const SizedBox(height: 28),

            // ── Section 2 : Dépenses par catégorie ──────────────────────────
            _SectionHeader(icon: Icons.pie_chart_rounded, title: 'Dépenses par catégorie', color: AppTheme.error),
            const SizedBox(height: 12),
            catAsync.when(
              loading: () => const _LoadingCard(),
              error:   (e, _) => _ErrorCard(message: '$e'),
              data:    (categories) {
                if (categories.isEmpty) return const _EmptyCard(label: 'Aucune dépense enregistrée');
                return _DepensesChart(categories: categories, fmt: fmt);
              },
            ),
            const SizedBox(height: 28),

            // ── Section 3 : Dettes clients ───────────────────────────────────
            _SectionHeader(icon: Icons.people_rounded, title: 'Dettes clients', color: AppTheme.warning),
            const SizedBox(height: 12),
            dettesAsync.when(
              loading: () => const _LoadingCard(),
              error:   (e, _) => _ErrorCard(message: '$e'),
              data:    (dettes) {
                if (dettes.isEmpty) return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.subtleShadow,
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.success),
                    SizedBox(width: 12),
                    Text('Aucune dette client en cours 🎉',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  ]),
                );
                return Column(
                  children: dettes.map((d) => _DetteCard(dette: d, fmt: fmt)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets de base ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    ),
    const SizedBox(width: 10),
    Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color, letterSpacing: -0.3)),
    const SizedBox(width: 10),
    Expanded(child: Divider(color: color.withOpacity(0.2), thickness: 1.5)),
  ]);
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => Container(
    height: 80,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.subtleShadow),
    child: const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5)),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.error.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.error.withOpacity(0.2)),
    ),
    child: Row(children: [
      const Icon(Icons.error_rounded, color: AppTheme.error, size: 22),
      const SizedBox(width: 10),
      Expanded(child: Text(message, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
    ]),
  );
}

class _EmptyCard extends StatelessWidget {
  final String label;
  const _EmptyCard({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppTheme.subtleShadow,
    ),
    child: Center(child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14))),
  );
}

// ── Truck Rentabilité Card ─────────────────────────────────────────────────────

class _TruckRentaCard extends StatelessWidget {
  final Map<String, dynamic> truck;
  final NumberFormat fmt;
  const _TruckRentaCard({required this.truck, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final info     = truck['truck'] as Map<String, dynamic>;
    final recettes = _parseDouble(truck['recettes']);
    final depenses = _parseDouble(truck['depenses']);
    final benefice = _parseDouble(truck['benefice']);
    final rentable = truck['rentable'] as bool;
    final nbTrans  = (truck['nb_transports'] as num?)?.toInt() ?? 0;
    final pct      = recettes > 0 ? (depenses / recettes * 100).clamp(0.0, 100.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header coloré
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: rentable ? AppTheme.successGradient : AppTheme.errorGradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${info['brand']} ${info['model']}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white, letterSpacing: -0.2)),
              Text(info['plate_number'] as String,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                '${benefice >= 0 ? '+' : ''}${fmt.format(benefice)} F',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
              ),
              Text('$nbTrans transport${nbTrans > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
            ]),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            // Barre ratio
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Ratio dépenses/recettes', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const Spacer(),
                  Text('${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: pct > 80 ? AppTheme.error : pct > 60 ? AppTheme.warning : AppTheme.success,
                      )),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation(
                      pct > 80 ? AppTheme.error : pct > 60 ? AppTheme.warning : AppTheme.success,
                    ),
                  ),
                ),
              ])),
            ]),
            const SizedBox(height: 14),
            // Stats
            Row(children: [
              Expanded(child: _StatBox(label: 'Recettes', value: '${fmt.format(recettes)} F', color: AppTheme.success, icon: Icons.trending_up_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _StatBox(label: 'Dépenses', value: '${fmt.format(depenses)} F', color: AppTheme.error, icon: Icons.trending_down_rounded)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (rentable ? AppTheme.success : AppTheme.error).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  Icon(rentable ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
                      color: rentable ? AppTheme.success : AppTheme.error, size: 18),
                  const SizedBox(height: 4),
                  Text(rentable ? 'Rentable' : 'Déficit',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: rentable ? AppTheme.success : AppTheme.error)),
                ]),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatBox({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
    ]),
  );
}

// ── Dépenses par catégorie ─────────────────────────────────────────────────────

class _DepensesChart extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final NumberFormat fmt;
  const _DepensesChart({required this.categories, required this.fmt});

  static const _colors = [
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFF59E0B),
    Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFF8B5CF6),
    Color(0xFFEC4899), Color(0xFF6B7280),
  ];

  @override
  Widget build(BuildContext context) {
    // FIX: utiliser _parseDouble pour éviter le crash sur String
    final total = categories.fold<double>(0, (s, c) => s + _parseDouble(c['total']));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            const Icon(Icons.pie_chart_rounded, color: AppTheme.error, size: 18),
            const SizedBox(width: 8),
            Text('Total: ${fmt.format(total)} FCFA',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
          ]),
        ),
        // Graphique
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 200,
            child: PieChart(PieChartData(
              sections: categories.asMap().entries.map((e) {
                final val = _parseDouble(e.value['total']); // FIX: _parseDouble
                final pct = total > 0 ? val / total * 100 : 0.0;
                return PieChartSectionData(
                  value: pct,
                  color: _colors[e.key % _colors.length],
                  title: '${pct.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  radius: 85,
                );
              }).toList(),
              sectionsSpace: 3,
              centerSpaceRadius: 35,
            )),
          ),
        ),
        // Légende
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(color: Color(0xFFF1F5F9), height: 1),
        ),
        ...categories.asMap().entries.map((e) {
          final color  = _colors[e.key % _colors.length];
          final total2 = _parseDouble(e.value['total']); // FIX: _parseDouble
          final count  = (e.value['count'] as num?)?.toInt() ?? 0;
          final pct    = total > 0 ? total2 / total * 100 : 0.0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(children: [
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.value['categorie'] as String? ?? 'Autre',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('$count op.', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Text('${fmt.format(total2)} F',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ]),
          );
        }),
        const SizedBox(height: 4),
      ]),
    );
  }
}

// ── Dette Client Card ──────────────────────────────────────────────────────────

class _DetteCard extends StatelessWidget {
  final Map<String, dynamic> dette;
  final NumberFormat fmt;
  const _DetteCard({required this.dette, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final resteAPayer = _parseDouble(dette['reste_a_payer']);
    final totalDu     = _parseDouble(dette['total_du']);
    final nbTrans     = (dette['nb_transports'] as num?)?.toInt() ?? 0;
    final pctPaye     = totalDu > 0 ? ((totalDu - resteAPayer) / totalDu).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
        border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_rounded, color: AppTheme.warning, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dette['client_name'] as String? ?? 'Client',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
              if (dette['client_phone'] != null)
                Row(children: [
                  const Icon(Icons.phone_rounded, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(dette['client_phone'] as String,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${fmt.format(resteAPayer)} F',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.error, fontSize: 16)),
              Text('reste à payer', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ]),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Progression du paiement', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                Text('${(pctPaye * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.success)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pctPaye,
                  minHeight: 8,
                  backgroundColor: AppTheme.warning.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.success),
                ),
              ),
            ])),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$nbTrans transport${nbTrans > 1 ? 's' : ''} non soldé${nbTrans > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.warning),
              ),
            ),
            const Spacer(),
            Text('Total dû: ${fmt.format(totalDu)} F',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ]),
        ]),
      ),
    );
  }
}
