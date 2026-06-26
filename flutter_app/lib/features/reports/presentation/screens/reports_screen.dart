import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/reports_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    // Démarrer sur le mois précédent (qui a probablement des données)
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month - 1);
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

  Future<void> _downloadPdf(BuildContext context) async {
    final monthString = _getMonthString();
    final pdfUrl = '${AppConstants.baseUrl}/reports/monthly/pdf?month=$monthString';

    try {
      if (await canLaunchUrl(Uri.parse(pdfUrl))) {
        await launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('URL: $pdfUrl'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthString = _getMonthString();
    final reportAsync = ref.watch(monthlyReportProvider(monthString));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Rapports',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppTheme.primary),
            tooltip: 'Télécharger PDF',
            onPressed: () => _downloadPdf(context),
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) => ListView(
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
            _FinancesCard(financials: report['financials'] as Map<String, dynamic>),
            const SizedBox(height: 16),

            // ── Carte Transports ──────────────────────────────────────────
            _TransportsCard(transports: report['transports'] as Map<String, dynamic>),
            const SizedBox(height: 16),

            // ── Top Camions ──────────────────────────────────────────────
            if ((report['top_trucks'] as List).isNotEmpty) ...[
              const _SectionTitle(title: 'Top Camions du Mois'),
              const SizedBox(height: 8),
              ...(report['top_trucks'] as List).asMap().entries.map((entry) {
                return _TopTruckCard(
                  rank: entry.key + 1,
                  truck: entry.value as Map<String, dynamic>,
                );
              }),
              const SizedBox(height: 16),
            ],

            // ── Dépenses par Catégorie ────────────────────────────────────
            _DepensesCategoriesCard(categories: report['categories'] as List),
            const SizedBox(height: 16),

            // ── Alertes ───────────────────────────────────────────────────
            if ((report['alerts'] as List).isNotEmpty) ...[
              const _SectionTitle(title: 'Alertes'),
              const SizedBox(height: 8),
              ...(report['alerts'] as List).map((alert) {
                return _AlertCard(alert: alert as Map<String, dynamic>);
              }),
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
    final monthLabel = DateFormat('MMMM yyyy', 'fr_FR').format(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.primary),
            onPressed: onPrevious,
          ),
          Text(
            monthLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppTheme.primary),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _FinancesCard extends StatelessWidget {
  final Map<String, dynamic> financials;

  const _FinancesCard({required this.financials});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'fr_FR');

    final recettes = (financials['recettes'] as num).toInt();
    final montantTransports = (financials['montant_transports'] as num).toInt();
    final totalRecettes = (financials['total_recettes'] as num).toInt();
    final depenses = (financials['depenses'] as num).toInt();
    final benefice = (financials['benefice'] as num).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Finances',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _FinanceRow(
            label: 'Recettes',
            amount: formatter.format(recettes),
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 12),
          _FinanceRow(
            label: 'Transports',
            amount: formatter.format(montantTransports),
            color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          _FinanceRow(
            label: 'Total Recettes',
            amount: formatter.format(totalRecettes),
            color: AppTheme.successColor,
            isBold: true,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _FinanceRow(
            label: 'Dépenses',
            amount: formatter.format(depenses),
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          _FinanceRow(
            label: 'Bénéfice',
            amount: formatter.format(benefice),
            color: AppTheme.successColor,
            isBold: true,
            fontSize: 18,
          ),
        ],
      ),
    );
  }
}

class _FinanceRow extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool isBold;
  final double fontSize;

  const _FinanceRow({
    required this.label,
    required this.amount,
    required this.color,
    this.isBold = false,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          '$amount FCFA',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TransportsCard extends StatelessWidget {
  final Map<String, dynamic> transports;

  const _TransportsCard({required this.transports});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'fr_FR');

    final total = (transports['total'] as num).toInt();
    final paye = (transports['paye'] as num).toInt();
    final nonPaye = (transports['non_paye'] as num).toInt();
    final montantTotal = (transports['montant_total'] as num).toInt();
    final montantPaye = (transports['montant_paye'] as num).toInt();
    final montantNonPaye = (transports['montant_non_paye'] as num).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transports',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBox(
                label: 'Total',
                value: '$total',
                color: AppTheme.primary,
              ),
              _StatBox(
                label: 'Payés',
                value: '$paye',
                color: AppTheme.successColor,
              ),
              _StatBox(
                label: 'Non payés',
                value: '$nonPaye',
                color: AppTheme.warningColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _FinanceRow(
            label: 'Montant Total',
            amount: formatter.format(montantTotal),
            color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          _FinanceRow(
            label: 'Montant Payé',
            amount: formatter.format(montantPaye),
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 12),
          _FinanceRow(
            label: 'Montant Non Payé',
            amount: formatter.format(montantNonPaye),
            color: AppTheme.warningColor,
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTruckCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> truck;

  const _TopTruckCard({
    required this.rank,
    required this.truck,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    final plateNumber = truck['plate_number'] as String;
    final nbTransports = (truck['nb_transports'] as num).toInt();
    final montant = (truck['montant'] as num).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plateNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$nbTransports transports',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${formatter.format(montant)} FCFA',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card unique contenant toutes les catégories de dépenses ─────────────────
class _DepensesCategoriesCard extends StatelessWidget {
  final List categories;
  const _DepensesCategoriesCard({required this.categories});

  static Color _color(String label) {
    switch (label.toLowerCase()) {
      case 'carburant':   return const Color(0xFFEA580C);
      case 'salaire':     return const Color(0xFF2563EB);
      case 'assurance':   return const Color(0xFF7C3AED);
      case 'reparation':  return const Color(0xFFDC2626);
      case 'pneumatique': return const Color(0xFF0891B2);
      case 'entretien':   return const Color(0xFF16A34A);
      case 'peage':       return const Color(0xFFD97706);
      default:            return const Color(0xFF6B7280);
    }
  }

  static IconData _icon(String label) {
    switch (label.toLowerCase()) {
      case 'carburant':   return Icons.local_gas_station_rounded;
      case 'salaire':     return Icons.people_rounded;
      case 'assurance':   return Icons.security_rounded;
      case 'reparation':  return Icons.build_rounded;
      case 'pneumatique': return Icons.tire_repair_rounded;
      case 'entretien':   return Icons.handyman_rounded;
      case 'peage':       return Icons.toll_rounded;
      default:            return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'fr_FR');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            const Icon(Icons.pie_chart_rounded, color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text('Dépenses par Catégorie (${categories.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ]),
          const SizedBox(height: 14),
          if (categories.isEmpty)
            const Row(children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary, size: 16),
              SizedBox(width: 8),
              Text('Aucune dépense ce mois', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ])
          else
            _CategoriesList(categories: categories, formatter: formatter),
        ],
      ),
    );
  }
}

// ── Liste des catégories de dépenses ─────────────────────────────────────────
class _CategoriesList extends StatelessWidget {
  final List categories;
  final NumberFormat formatter;
  const _CategoriesList({required this.categories, required this.formatter});

  static Color _color(String label) {
    switch (label.toLowerCase()) {
      case 'carburant':   return const Color(0xFFEA580C);
      case 'salaire':     return const Color(0xFF2563EB);
      case 'assurance':   return const Color(0xFF7C3AED);
      case 'reparation':  return const Color(0xFFDC2626);
      case 'pneumatique': return const Color(0xFF0891B2);
      case 'entretien':   return const Color(0xFF16A34A);
      case 'peage':       return const Color(0xFFD97706);
      default:            return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];
    for (int i = 0; i < categories.length; i++) {
      final item  = categories[i] as Map<String, dynamic>;
      final label = (item['categorie'] as String?) ?? '—';
      final total = (item['total'] as num?)?.toInt() ?? 0;
      final pct   = ((item['percentage'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 100.0);
      final color = _color(label);
      final name  = label.isNotEmpty ? '${label[0].toUpperCase()}${label.substring(1)}' : label;

      items.add(Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(name,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
          Text('${pct.toStringAsFixed(0)}%  ',
            style: TextStyle(fontSize: 12, color: color)),
          Text('${formatter.format(total)} F',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ]),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final type = alert['type'] as String? ?? 'info';
    final message = alert['message'] as String? ?? '';

    final color = _getAlertColor(type);
    final icon = _getAlertIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(String type) {
    switch (type) {
      case 'error':
        return AppTheme.errorColor;
      case 'warning':
        return AppTheme.warningColor;
      case 'success':
        return AppTheme.successColor;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'error':
        return Icons.error_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
