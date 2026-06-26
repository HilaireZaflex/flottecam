import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/drivers_provider.dart';
import '../../../auth/data/models/driver_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

/// Fonction publique pour ouvrir le formulaire chauffeur depuis n'importe quel écran
void showDriverFormSheet(BuildContext context, WidgetRef ref, {DriverModel? driver}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _DriverFormSheet(
      driver: driver,
      onSave: (data) async {
        if (driver == null) {
          await ref.read(driversProvider('').notifier).createDriver(data);
        } else {
          await ref.read(driversProvider('').notifier).updateDriver(driver.id, data);
        }
      },
    ),
  );
}

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});
  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(driversProvider(_search));
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Conducteurs',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
              tooltip: 'Ajouter un conducteur',
              onPressed: () => _showDriverDialog(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher un conducteur...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          // Drivers list
          Expanded(
            child: driversAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Une erreur est survenue',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$e',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (drivers) => drivers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              size: 48,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucun conducteur trouvé',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _search.isEmpty
                                ? 'Commencez par ajouter un conducteur'
                                : 'Aucun résultat pour "$_search"',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      backgroundColor: Colors.white,
                      color: AppTheme.primary,
                      onRefresh: () async => ref.invalidate(driversProvider(_search)),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: drivers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _DriverCard(
                          driver: drivers[i],
                          onDelete: () => _confirmDelete(context, drivers[i]),
                          onEdit: () => _showDriverDialog(context, driver: drivers[i]),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDriverDialog(BuildContext context, {DriverModel? driver}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DriverFormSheet(
        driver: driver,
        onSave: (data) async {
          if (driver == null) {
            await ref.read(driversProvider(_search).notifier).createDriver(data);
          } else {
            await ref.read(driversProvider(_search).notifier).updateDriver(driver.id, data);
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, DriverModel driver) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le conducteur'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${driver.fullName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(driversProvider(_search).notifier).deleteDriver(driver.id);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final DriverModel driver;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _DriverCard({required this.driver, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(driver.status);
    final statusLabel = AppConstants.driverStatuses[driver.status] ?? driver.status;
    final initials = '${driver.firstName[0]}${driver.lastName.isNotEmpty ? driver.lastName[0] : ''}'.toUpperCase();

    return GestureDetector(
      onTap: () => context.push('/drivers/detail/${driver.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            // ── Header coloré ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withOpacity(0.13), statusColor.withOpacity(0.04)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  // Avatar avec initiales
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [BoxShadow(color: statusColor.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: driver.avatar != null
                        ? ClipOval(child: Image.network(driver.avatar!, fit: BoxFit.cover))
                        : Center(
                            child: Text(initials,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withOpacity(0.4)),
                          ),
                          child: Text(statusLabel,
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  // Menu actions
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppTheme.textSecondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(children: const [
                            Icon(Icons.edit_rounded, size: 18, color: AppTheme.primary),
                            SizedBox(width: 10),
                            Text('Modifier', style: TextStyle(fontWeight: FontWeight.w600)),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.error),
                            const SizedBox(width: 10),
                            Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.error)),
                          ]),
                        ),
                      ],
                      onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                    ),
                  ),
                ],
              ),
            ),
            // ── Infos conducteur ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoChip(icon: Icons.badge_outlined, label: 'Permis', value: driver.licenseNumber),
                  if (driver.phone.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoChip(icon: Icons.phone_rounded, label: 'Tél', value: driver.phone),
                  ],
                  if (driver.licenseType.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoChip(icon: Icons.credit_card_rounded, label: 'Type', value: 'Permis ${driver.licenseType}'),
                  ],
                ],
              ),
            ),
            // ── Footer: voir détails ───────────────────────────────
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Voir le profil', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        const SizedBox(width: 10),
        Text('$label : ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _DriverFormSheet extends StatefulWidget {
  final DriverModel? driver;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _DriverFormSheet({this.driver, required this.onSave});
  @override
  State<_DriverFormSheet> createState() => _DriverFormSheetState();
}

class _DriverFormSheetState extends State<_DriverFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  final _licenseCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _licExpCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _licTypCtrl = TextEditingController();
  String _status = 'available';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    if (widget.driver != null) {
      _firstNameCtrl.text = widget.driver!.firstName;
      _lastNameCtrl.text = widget.driver!.lastName;
      _licenseCtrl.text = widget.driver!.licenseNumber;
      _phoneCtrl.text = widget.driver!.phone;
      _addressCtrl.text = widget.driver!.address ?? '';
      _licExpCtrl.text = widget.driver!.licenseExpiry;
      _notesCtrl.text = widget.driver!.notes ?? '';
      _licTypCtrl.text = widget.driver!.licenseType;
      _status = widget.driver!.status;
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _licenseCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _licExpCtrl.dispose();
    _notesCtrl.dispose();
    _licTypCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                widget.driver == null ? 'Ajouter un conducteur' : 'Modifier le conducteur',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 24),

              // Form fields
              _buildTextField(
                controller: _firstNameCtrl,
                label: 'Prénom',
                icon: Icons.person_rounded,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _lastNameCtrl,
                label: 'Nom',
                icon: Icons.person_rounded,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _licenseCtrl,
                label: 'Numéro de permis',
                icon: Icons.badge_rounded,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _licTypCtrl,
                label: 'Type de permis (ex: B, C, D)',
                icon: Icons.credit_card_rounded,
              ),
              const SizedBox(height: 14),
              _buildDateField(
                controller: _licExpCtrl,
                label: 'Expiration permis',
                icon: Icons.calendar_today_rounded,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _phoneCtrl,
                label: 'Téléphone',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _addressCtrl,
                label: 'Adresse',
                icon: Icons.home_rounded,
              ),
              const SizedBox(height: 14),
              _buildStatusDropdown(),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _notesCtrl,
                label: 'Notes',
                icon: Icons.note_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(widget.driver == null ? Icons.add_rounded : Icons.save_rounded),
                  label: Text(widget.driver == null ? 'Ajouter' : 'Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2040),
        );
        if (date != null) {
          controller.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: InputDecoration(
        labelText: 'Statut',
        prefixIcon: const Icon(Icons.info_rounded, color: AppTheme.primary, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: AppConstants.driverStatuses.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: (v) => setState(() => _status = v!),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final data = {
        'first_name': _firstNameCtrl.text,
        'last_name': _lastNameCtrl.text,
        'license_number': _licenseCtrl.text,
        'phone': _phoneCtrl.text,
        'status': _status,
        'license_type': _licTypCtrl.text,
        'license_expiry': _licExpCtrl.text,
      };
      if (_addressCtrl.text.isNotEmpty) data['address'] = _addressCtrl.text;
      if (_notesCtrl.text.isNotEmpty) data['notes'] = _notesCtrl.text;
      await widget.onSave(data);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
