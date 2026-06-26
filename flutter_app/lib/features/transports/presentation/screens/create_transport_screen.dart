import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/data/models/truck_model.dart';
import '../../../auth/data/models/driver_model.dart';
import '../../../trucks/providers/trucks_provider.dart';
import '../../../drivers/providers/drivers_provider.dart';
import '../../providers/transports_provider.dart';
import '../../../../core/theme/app_theme.dart';

class CreateTransportScreen extends ConsumerStatefulWidget {
  const CreateTransportScreen({super.key});

  @override
  ConsumerState<CreateTransportScreen> createState() => _CreateTransportScreenState();
}

class _CreateTransportScreenState extends ConsumerState<CreateTransportScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _originCtrl  = TextEditingController();
  final _destCtrl    = TextEditingController();
  final _cargoCtrl   = TextEditingController();
  final _weightCtrl  = TextEditingController();
  final _clientCtrl  = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _notesCtrl   = TextEditingController();

  TruckModel?  _selectedTruck;
  DriverModel? _selectedDriver;
  String       _priority    = 'normal';
  DateTime?    _departure;
  DateTime?    _arrival;
  bool         _isLoading   = false;

  @override
  void dispose() {
    _originCtrl.dispose(); _destCtrl.dispose(); _cargoCtrl.dispose();
    _weightCtrl.dispose(); _clientCtrl.dispose(); _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isDeparture) async {
    final now  = DateTime.now();
    final init = isDeparture ? (_departure ?? now) : (_arrival ?? (_departure?.add(const Duration(hours: 3)) ?? now));
    final date = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
    );
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => isDeparture ? _departure = dt : _arrival = dt);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTruck == null) {
      _showError('Veuillez sélectionner un camion');
      return;
    }
    if (_selectedDriver == null) {
      _showError('Veuillez sélectionner un chauffeur');
      return;
    }
    if (_departure == null) {
      _showError('Veuillez sélectionner la date de départ');
      return;
    }
    if (_arrival == null) {
      _showError('Veuillez sélectionner la date d\'arrivée');
      return;
    }
    if (_arrival!.isBefore(_departure!)) {
      _showError('L\'arrivée doit être après le départ');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final fmt = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
      await ref.read(transportsProvider('').notifier).createTransport({
        'truck_id':            _selectedTruck!.id,
        'driver_id':           _selectedDriver!.id,
        'origin':              _originCtrl.text.trim(),
        'destination':         _destCtrl.text.trim(),
        'cargo_type':          _cargoCtrl.text.trim(),
        if (_weightCtrl.text.isNotEmpty) 'cargo_weight': double.tryParse(_weightCtrl.text),
        'priority':            _priority,
        'scheduled_departure': fmt.format(_departure!),
        'scheduled_arrival':   fmt.format(_arrival!),
        if (_clientCtrl.text.isNotEmpty) 'client_name':  _clientCtrl.text.trim(),
        if (_phoneCtrl.text.isNotEmpty)  'client_phone': _phoneCtrl.text.trim(),
        if (_notesCtrl.text.isNotEmpty)  'notes':        _notesCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Transport créé avec succès'),
          backgroundColor: AppTheme.successColor,
        ));
        context.pop();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.errorColor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final trucksAsync  = ref.watch(trucksProvider(''));
    final driversAsync = ref.watch(driversProvider(''));
    final fmt          = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Nouveau Transport',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.textPrimary)),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _submit,
            icon: _isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                : const Icon(Icons.check_rounded, color: AppTheme.primaryColor),
            label: const Text('Créer', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Trajet ──────────────────────────────────────────────
            _SectionTitle(icon: Icons.route_rounded, title: 'Trajet'),
            const SizedBox(height: 14),
            _buildTextField(_originCtrl, 'Origine', Icons.location_on_rounded,
                hint: 'Ex: Paris, France'),
            const SizedBox(height: 14),
            _buildTextField(_destCtrl, 'Destination', Icons.flag_rounded,
                hint: 'Ex: Lyon, France'),
            const SizedBox(height: 24),

            // ── Véhicule & Chauffeur ─────────────────────────────────
            _SectionTitle(icon: Icons.local_shipping_rounded, title: 'Véhicule & Chauffeur'),
            const SizedBox(height: 14),

            // Camion
            trucksAsync.when(
              loading: () => const LinearProgressIndicator(color: AppTheme.primaryColor),
              error: (e, _) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.errorColor, fontSize: 12)),
              ),
              data: (trucks) {
                final available = trucks.where((t) => t.isAvailable).toList();
                return DropdownButtonFormField<TruckModel>(
                  value: _selectedTruck,
                  decoration: _inputDecoration('Camion', Icons.local_shipping_rounded),
                  hint: const Text('Sélectionner un camion'),
                  items: available.map((t) => DropdownMenuItem(
                    value: t,
                    child: Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.successColor, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Flexible(child: Text('${t.brand} ${t.model} — ${t.plateNumber}', overflow: TextOverflow.ellipsis)),
                    ]),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedTruck = v),
                  validator: (_) => _selectedTruck == null ? 'Requis' : null,
                );
              },
            ),
            const SizedBox(height: 14),

            // Chauffeur
            driversAsync.when(
              loading: () => const LinearProgressIndicator(color: AppTheme.primaryColor),
              error: (e, _) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.errorColor, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              data: (drivers) {
                final available = drivers.where((d) => d.isAvailable).toList();
                return DropdownButtonFormField<DriverModel>(
                  value: _selectedDriver,
                  decoration: _inputDecoration('Chauffeur', Icons.badge_rounded),
                  hint: const Text('Sélectionner un chauffeur'),
                  items: available.map((d) => DropdownMenuItem(
                    value: d,
                    child: Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.successColor, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(d.fullName),
                    ]),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedDriver = v),
                  validator: (_) => _selectedDriver == null ? 'Requis' : null,
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Cargaison ────────────────────────────────────────────
            _SectionTitle(icon: Icons.inventory_2_rounded, title: 'Cargaison'),
            const SizedBox(height: 14),
            _buildTextField(_cargoCtrl, 'Type de cargaison', Icons.category_rounded,
                hint: 'Ex: Produits alimentaires'),
            const SizedBox(height: 14),
            _buildTextField(_weightCtrl, 'Poids (tonnes)', Icons.scale_rounded,
                hint: 'Ex: 18.5', keyboardType: TextInputType.number, required: false),
            const SizedBox(height: 24),

            // ── Priorité ─────────────────────────────────────────────
            _SectionTitle(icon: Icons.flag_rounded, title: 'Priorité'),
            const SizedBox(height: 14),
            Row(children: [
              for (final p in ['low', 'normal', 'high', 'urgent'])
                Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _priority == p
                            ? AppTheme.priorityColor(p).withOpacity(0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _priority == p ? AppTheme.priorityColor(p) : Colors.grey[300]!,
                          width: _priority == p ? 2 : 1,
                        ),
                        boxShadow: _priority == p ? AppTheme.subtleShadow : null,
                      ),
                      child: Text(
                        _priorityLabel(p),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _priority == p ? FontWeight.bold : FontWeight.w500,
                          color: _priority == p ? AppTheme.priorityColor(p) : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                )),
            ]),
            const SizedBox(height: 24),

            // ── Dates ────────────────────────────────────────────────
            _SectionTitle(icon: Icons.schedule_rounded, title: 'Planification'),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _DateTile(
                label: 'Départ',
                value: _departure != null ? fmt.format(_departure!) : null,
                icon: Icons.flight_takeoff_rounded,
                color: AppTheme.primaryColor,
                onTap: () => _pickDate(true),
              )),
              const SizedBox(width: 14),
              Expanded(child: _DateTile(
                label: 'Arrivée',
                value: _arrival != null ? fmt.format(_arrival!) : null,
                icon: Icons.flight_land_rounded,
                color: AppTheme.successColor,
                onTap: () => _pickDate(false),
              )),
            ]),
            const SizedBox(height: 24),

            // ── Client ───────────────────────────────────────────────
            _SectionTitle(icon: Icons.business_rounded, title: 'Client (optionnel)'),
            const SizedBox(height: 14),
            _buildTextField(_clientCtrl, 'Nom du client', Icons.person_rounded,
                hint: 'Ex: Carrefour SA', required: false),
            const SizedBox(height: 14),
            _buildTextField(_phoneCtrl, 'Téléphone client', Icons.phone_rounded,
                hint: 'Ex: +33 1 23 45 67 89', required: false,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 24),

            // ── Notes ────────────────────────────────────────────────
            _SectionTitle(icon: Icons.note_rounded, title: 'Notes (optionnel)'),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: _inputDecoration('Notes', Icons.note_rounded)
                  .copyWith(hintText: 'Instructions spéciales, remarques...'),
            ),
            const SizedBox(height: 32),

            // Bouton créer
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add_circle_rounded),
              label: Text(_isLoading ? 'Création...' : 'Créer le transport'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon,
      {String? hint, TextInputType? keyboardType, bool required = true}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon).copyWith(hintText: hint),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
          : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorColor),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  String _priorityLabel(String p) {
    const labels = {'low': 'Faible', 'normal': 'Normal', 'high': 'Élevé', 'urgent': 'Urgent'};
    return labels[p] ?? p;
  }
}

// ── Widgets helpers ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 20, color: AppTheme.primaryColor),
    const SizedBox(width: 10),
    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
    const SizedBox(width: 10),
    Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
  ]);
}

class _DateTile extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _DateTile({required this.label, this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value != null ? color.withOpacity(0.4) : Colors.grey[300]!, width: value != null ? 2 : 1),
        boxShadow: value != null ? AppTheme.subtleShadow : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: value != null ? color : Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 6),
        Text(
          value ?? 'Sélectionner',
          style: TextStyle(
            fontSize: 13,
            fontWeight: value != null ? FontWeight.w700 : FontWeight.w400,
            color: value != null ? color : Colors.grey[400],
          ),
        ),
      ]),
    ),
  );
}
