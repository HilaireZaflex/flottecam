import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

// Provider pour le rapport mensuel
final rapportMensuelProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, month) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/reports/monthly', params: {'month': month});
  return response.data as Map<String, dynamic>;
});

class RapportMensuelScreen extends ConsumerStatefulWidget {
  const RapportMensuelScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RapportMensuelScreen> createState() => _RapportMensuelScreenState();
}

class _RapportMensuelScreenState extends ConsumerState<RapportMensuelScreen> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
    });
  }

  String _getMonthString() => selectedDate.toString().substring(0, 7); // YYYY-MM

  @override
  Widget build(BuildContext context) {
    final monthString = _getMonthString();
    final rapportAsync = ref.watch(rapportMensuelProvider(monthString));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Rapport Mensuel', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          // Bouton télécharger PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.errorColor),
            tooltip: 'Télécharger PDF',
            onPressed: () => _downloadPdf(context, ref),
          ),
          rapportAsync.when(
            data: (rapport) => IconButton(
              icon: const Icon(Icons.share_rounded, color: AppTheme.textPrimary),
              onPressed: () => _shareReport(context, rapport),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: rapportAsync.when(
        data: (rapport) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Sélecteur de mois ──────────────────────────────────────────
            _MonthPicker(
              selectedDate: selectedDate,
              onPrevious: _previousMonth,
              onNext: _nextMonth,
            ),
            const SizedBox(height: 20),

            // ── Carte Finances ────────────────────────────────────────────
            _FinancesCard(statsOps: rapport['financials'] as Map<String, dynamic>),
            const SizedBox(height: 16),

            // ── Carte Transports ──────────────────────────────────────────
            _TransportsCard(statsTransports: rapport['transports'] as Map<String, dynamic>),
            const SizedBox(height: 16),

            // ── Top Camions Rentables ─────────────────────────────────────
            if ((rapport['top_trucks'] as List).isNotEmpty) ...[
              _SectionTitle(title: 'Top Camions Rentables'),
              const SizedBox(height: 8),
              ...(rapport['top_trucks'] as List).asMap().entries.map((entry) {
                return _TopTruckCard(
                  rank: entry.key + 1,
                  truck: entry.value as Map<String, dynamic>,
                );
              }).toList(),
              const SizedBox(height: 16),
            ],

            // ── Dépenses par Catégorie ────────────────────────────────────
            _SectionTitle(title: 'Dépenses par Catégorie'),
            const SizedBox(height: 8),
            ...(rapport['categories'] as List).map((cat) {
              return _DepensesCategorieLine(categorie: cat as Map<String, dynamic>);
            }).toList(),
            const SizedBox(height: 16),

            // ── Alertes Actives ───────────────────────────────────────────
            if ((rapport['alerts'] as List).isNotEmpty) ...[
              _SectionTitle(title: 'Alertes Actives'),
              const SizedBox(height: 8),
              ...(rapport['alerts'] as List).map((alert) {
                return _AlertCard(alert: alert as Map<String, dynamic>);
              }).toList(),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text('Erreur: $err', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context, WidgetRef ref) async {
    final month = DateFormat('yyyy-MM').format(selectedDate);
    final api   = ref.read(apiClientProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.white),
            SizedBox(width: 12),
            Text('Génération du PDF en cours...'),
          ],
        ),
        backgroundColor: Colors.red[700],
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );

    try {
      // Télécharger le PDF via l'API avec le token
      await api.get('/reports/monthly/pdf', params: {'month': month});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF généré avec succès !'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur PDF: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _shareReport(BuildContext context, Map<String, dynamic> rapport) {
    final statsOps = rapport['financials'] as Map<String, dynamic>;
    final statsTransports = rapport['transports'] as Map<String, dynamic>;
    final monthLabel = rapport['month_label'] as String;

    final text = '''
Rapport Mensuel - $monthLabel

📊 FINANCES
Recettes: ${NumberFormat('#,##0', 'fr_FR').format(statsOps['recettes'])} FCFA
Dépenses: ${NumberFormat('#,##0', 'fr_FR').format(statsOps['depenses'])} FCFA
Bénéfice: ${NumberFormat('#,##0', 'fr_FR').format(statsOps['benefice'])} FCFA

🚚 TRANSPORTS
Total: ${statsTransports['total']}
Payés: ${statsTransports['paye']}
Non payés: ${statsTransports['non_paye']}
Montant total: ${NumberFormat('#,##0', 'fr_FR').format(statsTransports['montant_total'])} FCFA
''';

    // Copier dans le presse-papiers
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapport copié dans le presse-papiers')),
      );
    });
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────

class _MonthPicker extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthPicker({
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.primary, size: 28),
              onPressed: onPrevious,
            ),
            Text(
              DateFormat('MMMM yyyy', 'fr_FR').format(selectedDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.primary, size: 28),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancesCard extends StatelessWidget {
  final Map<String, dynamic> statsOps;

  const _FinancesCard({required this.statsOps});

  @override
  Widget build(BuildContext context) {
    final recettes = (statsOps['total_recettes'] as num).toDouble();
    final depenses = (statsOps['depenses'] as num).toDouble();
    final benefice = (statsOps['benefice'] as num).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💰 Finances', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            _FinancesRow(
              label: 'Recettes',
              amount: recettes,
              color: AppTheme.successColor,
              icon: Icons.arrow_downward_rounded,
            ),
            const SizedBox(height: 12),
            _FinancesRow(
              label: 'Dépenses',
              amount: depenses,
              color: AppTheme.errorColor,
              icon: Icons.arrow_upward_rounded,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0)), bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: _FinancesRow(
                label: 'Bénéfice',
                amount: benefice,
                color: benefice >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                isBold: true,
                icon: benefice >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancesRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isBold;
  final IconData? icon;

  const _FinancesRow({
    required this.label,
    required this.amount,
    required this.color,
    this.isBold = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.w700 : FontWeight.w600, color: AppTheme.textPrimary),
          ),
        ]),
        Text(
          '${NumberFormat('#,##0', 'fr_FR').format(amount)} FCFA',
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TransportsCard extends StatelessWidget {
  final Map<String, dynamic> statsTransports;

  const _TransportsCard({required this.statsTransports});

  @override
  Widget build(BuildContext context) {
    final total = (statsTransports['total'] as num).toInt();
    final payes = (statsTransports['paye'] as num).toInt();
    final nonPayes = (statsTransports['non_paye'] as num).toInt();
    final montantTotal = (statsTransports['montant_total'] as num).toDouble();
    final montantPaye = (statsTransports['montant_paye'] as num).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🚚 Transports', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBox(label: 'Total', value: total.toString(), color: AppTheme.info, icon: Icons.local_shipping_rounded),
                _StatBox(label: 'Payés', value: payes.toString(), color: AppTheme.successColor, icon: Icons.check_circle_rounded),
                _StatBox(label: 'Non payés', value: nonPayes.toString(), color: AppTheme.warningColor, icon: Icons.schedule_rounded),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0)), bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Montant total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    Text(
                      '${NumberFormat('#,##0', 'fr_FR').format(montantTotal)} FCFA',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Montant payé', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    Text(
                      '${NumberFormat('#,##0', 'fr_FR').format(montantPaye)} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const _StatBox({required this.label, required this.value, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null)
              Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _TopTruckCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> truck;

  const _TopTruckCard({required this.rank, required this.truck});

  @override
  Widget build(BuildContext context) {
    final rankColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];
    final rankColor = rank <= 3 ? rankColors[rank - 1] : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: rankColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : rank.toString(),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      truck['plate_number'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${truck['nb_transports']} transports',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.local_shipping_rounded, color: rankColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepensesCategorieLine extends StatelessWidget {
  final Map<String, dynamic> categorie;

  const _DepensesCategorieLine({required this.categorie});

  @override
  Widget build(BuildContext context) {
    final label = categorie['categorie'] as String;
    final percentage = (categorie['percentage'] as num).toInt();
    final total = (categorie['total'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Text(
                '${NumberFormat('#,##0', 'fr_FR').format(total)} FCFA',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.warningColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFFEF3C7),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.warningColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$percentage%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.warningColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _alertTitle(String type) {
  switch (type) {
    case 'error':   return '🔴 Alerte critique';
    case 'warning': return '⚠️ Avertissement';
    default:        return 'ℹ️ Information';
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final type    = (alert['type']    as String?) ?? 'info';
    final title   = (alert['title']   as String?) ?? _alertTitle(type);
    final message = (alert['message'] as String?) ?? '';

    final color = type == 'error'
        ? AppTheme.errorColor
        : type == 'warning'
            ? AppTheme.warningColor
            : AppTheme.info;

    final icon = type == 'error' ? Icons.error_rounded : type == 'warning' ? Icons.warning_rounded : Icons.info_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.subtleShadow,
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Icon(icon, color: color, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
