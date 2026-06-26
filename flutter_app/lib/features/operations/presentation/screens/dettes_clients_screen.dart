import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import '../../providers/operations_provider.dart';
import '../../../../core/theme/app_theme.dart';


double _parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

class DettesClientsScreen extends ConsumerWidget {
  const DettesClientsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dettesAsync = ref.watch(clientDettesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettes Clients'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: dettesAsync.when(
        data: (dettes) {
          if (dettes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Aucune dette client 🎉',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.successColor),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tous les clients sont à jour',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Calcul du total global
          double totalGlobal = 0;
          for (var dette in dettes) {
            totalGlobal += _parseDouble(dette['reste_a_payer']);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(clientDettesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // En-tête avec total global
                Card(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total des dettes',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${NumberFormat('#,##0', 'fr_FR').format(totalGlobal)} FCFA',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Liste des dettes clients
                ...dettes.map((dette) {
                  return _DetteClientCard(dette: dette);
                }).toList(),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
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

// ── Carte de dette client ──────────────────────────────────────────────────

class _DetteClientCard extends StatelessWidget {
  final Map<String, dynamic> dette;

  const _DetteClientCard({required this.dette});

  @override
  Widget build(BuildContext context) {
    final montantTotal = _parseDouble(dette['montant_total']);
    final montantPaye = _parseDouble(dette['montant_paye']);
    final resteAPayer = _parseDouble(dette['reste_a_payer']);
    final transportsNonSoldes = dette['transports_non_soldes'] as int? ?? 0;
    final nomClient = dette['nom_client'] as String? ?? 'Client';
    final telephone = dette['telephone'] as String?;

    final progressValue = montantTotal > 0 ? montantPaye / montantTotal : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : Nom et téléphone
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomClient,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (telephone != null && telephone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          telephone,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$transportsNonSoldes transport${transportsNonSoldes > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.warningColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Barre de progression
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progression', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '${(progressValue * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 6,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Montants
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Montant dû', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '${NumberFormat('#,##0', 'fr_FR').format(montantTotal)} FCFA',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Reste à payer', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '${NumberFormat('#,##0', 'fr_FR').format(resteAPayer)} FCFA',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bouton Voir transports
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Voir transports',
                  style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
