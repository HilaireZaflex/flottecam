import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../auth/auth_provider.dart';

// Provider liste dépenses du chauffeur
final driverExpensesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return [];
  final truckId = user['current_truck_id'];
  if (truckId == null) return [];
  final api = ref.read(apiClientProvider);
  try {
    final res = await api.get('/operations', params: {
      'truck_id': '$truckId',
      'per_page': '50',
      'type_operation': 'depense',
    });
    final data = res.data;
    // L'API retourne {"operations": [...]} ou {"data": [...]}
    List items = [];
    if (data is Map) {
      items = data['operations'] ?? data['data'] ?? [];
    } else if (data is List) {
      items = data;
    }
    return items.cast<Map<String, dynamic>>();
  } catch (_) {
    return [];
  }
});

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});
  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(driverExpensesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mes Dépenses'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _showAddExpenseSheet(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajouter'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF1B4FD8)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseSheet(context),
        backgroundColor: const Color(0xFF1B4FD8),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle dépense', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (expenses) {
          if (expenses.isEmpty) return const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.receipt_long_rounded, size: 64, color: Color(0xFFCBD5E1)),
              SizedBox(height: 16),
              Text('Aucune dépense enregistrée',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
              SizedBox(height: 8),
              Text('Appuyez sur + pour ajouter une dépense',
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
            ]),
          );

          final total = expenses.fold<double>(0, (sum, e) =>
            sum + ((e['quantite'] as num? ?? 1) * (e['prix_unitaire'] as num? ?? 0)));

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(driverExpensesProvider),
            child: Column(children: [
              // Total
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4FD8), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Total dépenses', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(NumberFormat('#,###').format(total.toInt()) + ' FCFA',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  ]),
                  const Spacer(),
                  Text('${expenses.length} op.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ),
              // Liste
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: expenses.length,
                  itemBuilder: (ctx, i) => _ExpenseCard(expense: expenses[i]),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddExpenseSheet(onSaved: () {
        ref.invalidate(driverExpensesProvider);
        Navigator.pop(ctx);
      }),
    );
  }
}

// ── Card dépense ─────────────────────────────────────────────────────────────
class _ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  const _ExpenseCard({required this.expense});

  static const _icons = {
    'carburant':   Icons.local_gas_station_rounded,
    'peage':       Icons.toll_rounded,
    'reparation':  Icons.build_rounded,
    'repas':       Icons.restaurant_rounded,
    'parking':     Icons.local_parking_rounded,
    'pneumatique': Icons.tire_repair_rounded,
    'autre':       Icons.more_horiz_rounded,
  };

  static const _colors = {
    'carburant':   Color(0xFFEA580C),
    'peage':       Color(0xFFD97706),
    'reparation':  Color(0xFFDC2626),
    'repas':       Color(0xFF16A34A),
    'parking':     Color(0xFF2563EB),
    'pneumatique': Color(0xFF0891B2),
    'autre':       Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) {
    final categorie   = expense['categorie'] as String? ?? 'autre';
    final description = expense['description'] as String? ?? categorie;
    final quantite    = (expense['quantite'] as num?)?.toDouble() ?? 1;
    final prix        = (expense['prix_unitaire'] as num?)?.toDouble() ?? 0;
    final total       = (quantite * prix).toInt();
    final date        = expense['date'] as String? ?? '';
    final hasPhoto    = expense['photo_url'] != null;
    final color       = _colors[categorie] ?? const Color(0xFF6B7280);
    final icon        = _icons[categorie] ?? Icons.receipt_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Row(children: [
            Text(categorie.toUpperCase(),
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
            if (date.isNotEmpty) ...[
              const Text(' · ', style: TextStyle(color: Color(0xFF94A3B8))),
              Text(date.substring(0, 10), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
            if (hasPhoto) ...[
              const Text(' · ', style: TextStyle(color: Color(0xFF94A3B8))),
              const Icon(Icons.photo_camera_rounded, size: 11, color: Color(0xFF94A3B8)),
            ],
          ]),
        ])),
        Text(NumberFormat('#,###').format(total) + ' F',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}

// ── Sheet ajout dépense ───────────────────────────────────────────────────────
class _AddExpenseSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _AddExpenseSheet({required this.onSaved});
  @override
  ConsumerState<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<_AddExpenseSheet> {
  final _descCtrl  = TextEditingController();
  final _montantCtrl = TextEditingController();
  String _categorie = 'carburant';
  File? _photo;
  bool _loading = false;

  final _categories = [
    ('carburant',   'Carburant',   Icons.local_gas_station_rounded),
    ('peage',       'Péage',       Icons.toll_rounded),
    ('reparation',  'Réparation',  Icons.build_rounded),
    ('repas',       'Repas',       Icons.restaurant_rounded),
    ('parking',     'Parking',     Icons.local_parking_rounded),
    ('pneumatique', 'Pneumatique', Icons.tire_repair_rounded),
    ('autre',       'Autre',       Icons.more_horiz_rounded),
  ];

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _save() async {
    if (_montantCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(authProvider).value!;
      final driverId = user['driver_id'] as int?;
      final truckId  = user['current_truck_id'] as int?;
      final api = ref.read(apiClientProvider);

      // Envoyer avec ou sans photo
      if (_photo != null) {
        final formData = FormData.fromMap({
          'type_operation': 'depense',
          'categorie':      _categorie,
          'description':    _descCtrl.text.isEmpty ? _categorie : _descCtrl.text,
          'quantite':       '1',
          'prix_unitaire':  _montantCtrl.text,
          'date':           DateTime.now().toIso8601String().substring(0, 10),
          if (driverId != null) 'driver_id': '$driverId',
          if (truckId  != null) 'truck_id':  '$truckId',
          'photo': await MultipartFile.fromFile(_photo!.path, filename: 'depense.jpg'),
        });
        final dio = Dio(BaseOptions(
          baseUrl: 'http://127.0.0.1:8000/api',
          headers: {'Accept': 'application/json'},
        ));
        final storage = const FlutterSecureStorage();
        final token = await storage.read(key: 'driver_token');
        if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
        await dio.post('/operations', data: formData,
          options: Options(contentType: 'multipart/form-data'));
      } else {
        await api.post('/operations', data: {
          'type_operation': 'depense',
          'categorie':      _categorie,
          'designation':    _descCtrl.text.isEmpty ? _categorie : _descCtrl.text,
          'quantite':       1,
          'prix_unitaire':  double.tryParse(_montantCtrl.text) ?? 0,
          'date':           DateTime.now().toIso8601String().substring(0, 10),
          if (truckId  != null) 'truck_id':  truckId,
        });
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20, left: 20, right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Text('Nouvelle Dépense',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        const SizedBox(height: 20),

        // Catégories
        const Text('Catégorie', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final (key, label, icon) = _categories[i];
              final selected = _categorie == key;
              return GestureDetector(
                onTap: () => setState(() => _categorie = key),
                child: Container(
                  width: 72,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF1B4FD8) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? const Color(0xFF1B4FD8) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(icon, size: 20, color: selected ? Colors.white : const Color(0xFF64748B)),
                    const SizedBox(height: 4),
                    Text(label, style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF64748B)),
                      textAlign: TextAlign.center),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Description
        TextField(
          controller: _descCtrl,
          decoration: InputDecoration(
            labelText: 'Description (optionnel)',
            hintText: 'Ex: Plein carburant à Ségou',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true, fillColor: const Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 12),

        // Montant
        TextField(
          controller: _montantCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Montant (FCFA) *',
            prefixIcon: const Icon(Icons.payments_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true, fillColor: const Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 16),

        // Photo
        GestureDetector(
          onTap: _pickPhoto,
          child: Container(
            width: double.infinity,
            height: _photo != null ? 150 : 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
            ),
            child: _photo != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(children: [
                    Image.file(_photo!, width: double.infinity, height: 150, fit: BoxFit.cover),
                    Positioned(top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _photo = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ]),
                )
              : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.photo_camera_rounded, color: Color(0xFF94A3B8), size: 28),
                  SizedBox(height: 6),
                  Text('Prendre une photo du reçu', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ]),
          ),
        ),
        const SizedBox(height: 20),

        // Bouton sauvegarder
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_rounded),
            label: Text(_loading ? 'Enregistrement...' : 'Enregistrer la dépense',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4FD8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ])),
    );
  }
}
