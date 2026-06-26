import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class ImportExcelScreen extends ConsumerStatefulWidget {
  const ImportExcelScreen({super.key});

  @override
  ConsumerState<ImportExcelScreen> createState() => _ImportExcelScreenState();
}

class _ImportExcelScreenState extends ConsumerState<ImportExcelScreen> {
  bool _isLoading       = false;
  bool _isDownloading   = false;
  String? _resultMessage;
  bool _success         = false;
  int _imported         = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Excel / CSV')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Instructions ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 8),
                Text('Format du fichier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              const SizedBox(height: 12),
              const Text('Votre fichier Excel/CSV doit contenir ces colonnes :', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              _ColumnRow('date',           'Date de l\'opération (ex: 2026-03-25)', required: true),
              _ColumnRow('designation',    'Description de l\'opération', required: true),
              _ColumnRow('quantite',       'Quantité (défaut: 1)'),
              _ColumnRow('prix_unitaire',  'Prix unitaire en FCFA', required: true),
              _ColumnRow('type_operation', '"recette" ou "depense"', required: true),
              _ColumnRow('categorie',      'Ex: carburant, entretien, transport…', required: true),
              _ColumnRow('plaque_camion',  'Immatriculation du camion (optionnel)'),
              _ColumnRow('notes',          'Remarques libres (optionnel)'),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Télécharger template ──────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: _isDownloading ? null : _downloadTemplate,
            icon: _isDownloading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_outlined),
            label: const Text('Télécharger le modèle CSV'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 12),

          // ── Bouton import ─────────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickAndImport,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.upload_file),
            label: Text(_isLoading ? 'Import en cours...' : 'Choisir un fichier Excel / CSV'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),

          // ── Résultat ─────────────────────────────────────────────────────
          if (_resultMessage != null) Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _success ? AppTheme.successColor.withOpacity(0.08) : AppTheme.errorColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _success ? AppTheme.successColor.withOpacity(0.3) : AppTheme.errorColor.withOpacity(0.3),
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(
                  _success ? Icons.check_circle_outline : Icons.error_outline,
                  color: _success ? AppTheme.successColor : AppTheme.errorColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _success ? 'Import réussi !' : 'Erreur d\'import',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _success ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Text(_resultMessage!, style: const TextStyle(fontSize: 13)),
              if (_success && _imported > 0) ...[
                const SizedBox(height: 8),
                Text('$_imported opération${_imported > 1 ? 's' : ''} importée${_imported > 1 ? 's' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ]),
          ),
          const SizedBox(height: 24),

          // ── Catégories disponibles ────────────────────────────────────────
          const Text('Catégories disponibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          _CatSection('Dépenses', AppTheme.errorColor, ['carburant', 'entretien', 'reparation', 'salaire', 'peage', 'pneumatique', 'assurance', 'autre']),
          const SizedBox(height: 8),
          _CatSection('Recettes', AppTheme.successColor, ['transport', 'client', 'remboursement', 'autre']),
        ]),
      ),
    );
  }

  Future<void> _pickAndImport() async {
    final picker = ImagePicker();
    final file = await picker.pickMedia();
    if (file == null) return;

    setState(() { _isLoading = true; _resultMessage = null; });
    try {
      final api = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
      });
      final response = await api.post('/import/operations', data: formData);
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _success = data['success'] == true;
        _imported = data['imported'] as int? ?? 0;
        _resultMessage = data['message'] as String? ?? 'Import terminé.';
      });
    } catch (e) {
      setState(() { _success = false; _resultMessage = 'Erreur : $e'; });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadTemplate() async {
    setState(() => _isDownloading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/import/template');
      // Afficher le contenu CSV
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Modèle CSV'),
            content: SingleChildScrollView(
              child: SelectableText(response.data.toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.errorColor,
        ));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }
}

// ── Widgets helpers ────────────────────────────────────────────────────────────

class _ColumnRow extends StatelessWidget {
  final String name;
  final String desc;
  final bool required;
  const _ColumnRow(this.name, this.desc, {this.required = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: required ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: required ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey[300]!),
        ),
        child: Text(name, style: TextStyle(
          fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600,
          color: required ? AppTheme.primaryColor : Colors.grey[700],
        )),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
    ]),
  );
}

class _CatSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> cats;
  const _CatSection(this.title, this.color, this.cats);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    const SizedBox(height: 4),
    Wrap(spacing: 6, runSpacing: 4, children: cats.map((c) => Chip(
      label: Text(c, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withOpacity(0.08),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.all(0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    )).toList()),
  ]);
}
