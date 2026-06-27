import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/pin_service.dart';
import '../../../../features/auth/providers/auth_provider.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String? _error;
  int _remainingAttempts = PinService.maxAttempts;
  bool _checking = false;
  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _loadAttempts();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAttempts() async {
    final r = await ref.read(pinServiceProvider).remainingAttempts();
    if (mounted) setState(() => _remainingAttempts = r);
  }

  void _onKey(String digit) {
    if (_checking) return;
    setState(() {
      _error = null;
      if (_pin.length < 4) _pin += digit;
    });
    if (_pin.length == 4) _verify();
  }

  void _onDelete() {
    if (_checking) return;
    setState(() {
      _error = null;
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verify() async {
    setState(() => _checking = true);

    final result = await ref.read(pinServiceProvider).verifyPin(_pin);

    if (!mounted) return;

    if (result.isSuccess) {
      // ✅ PIN correct → vérifier mise à jour puis aller au dashboard
      context.go('/dashboard');
    } else if (result.isTooManyAttempts) {
      // ❌ Trop de tentatives → retour login classique
      await ref.read(authStateProvider.notifier).logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trop de tentatives — reconnectez-vous'),
          backgroundColor: Color(0xFFEF4444),
        ));
        context.go('/login');
      }
    } else {
      // ❌ PIN incorrect
      _shakeCtrl.forward(from: 0);
      setState(() {
        _error = 'Code incorrect — ${result.remainingAttempts} essai${result.remainingAttempts > 1 ? 's' : ''} restant${result.remainingAttempts > 1 ? 's' : ''}';
        _pin = '';
        _remainingAttempts = result.remainingAttempts;
        _checking = false;
      });
    }
  }

  Future<void> _usePassword() async {
    // Effacer le PIN et retourner au login classique
    await ref.read(pinServiceProvider).clearPin();
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final name = user?.name.split(' ').first ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            // ── Logo FlotteCam ─────────────────────────────────────────
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 24, offset: const Offset(0, 10),
                )],
              ),
              child: Stack(alignment: Alignment.center, children: [
                const Icon(Icons.local_shipping_rounded,
                    color: Colors.white, size: 38),
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.success, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Salutation ─────────────────────────────────────────────
            Text(
              name.isNotEmpty ? '${_greeting()}, $name 👋' : _greeting(),
              style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Entrez votre code PIN pour continuer',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
            const SizedBox(height: 48),

            // ── Indicateurs 4 points ───────────────────────────────────
            AnimatedBuilder(
              animation: _shakeCtrl,
              builder: (context, child) {
                final progress = _shakeCtrl.value;
                final offset = progress < 1
                    ? 20 * (progress * 2 - 1).abs() * (1 - progress)
                    : 0.0;
                return Transform.translate(
                  offset: Offset(offset, 0), child: child);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  final isError = _error != null;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: filled ? 22 : 16,
                    height: filled ? 22 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isError && _pin.isEmpty
                          ? const Color(0xFFEF4444)
                          : filled
                              ? AppTheme.primary
                              : Colors.white.withOpacity(0.2),
                      boxShadow: filled ? [BoxShadow(
                        color: (isError
                            ? const Color(0xFFEF4444)
                            : AppTheme.primary).withOpacity(0.6),
                        blurRadius: 14,
                      )] : [],
                    ),
                  );
                }),
              ),
            ),

            // ── Message d'erreur ───────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _error != null ? 44 : 0,
              child: _error != null ? Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFEF4444), fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ) : null,
            ),

            const Spacer(),

            // ── Clavier numérique ──────────────────────────────────────
            _NumPad(onKey: _onKey, onDelete: _onDelete),
            const SizedBox(height: 16),

            // ── Utiliser identifiants ──────────────────────────────────
            TextButton.icon(
              onPressed: _usePassword,
              icon: Icon(Icons.lock_open_rounded,
                  size: 14, color: Colors.white.withOpacity(0.4)),
              label: Text(
                'Utiliser mes identifiants',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Clavier numérique ─────────────────────────────────────────────────────────
class _NumPad extends StatelessWidget {
  final void Function(String) onKey;
  final VoidCallback onDelete;

  const _NumPad({required this.onKey, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1','2','3'],
      ['4','5','6'],
      ['7','8','9'],
      ['','0','⌫'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: keys.map((row) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 80, height: 72);
            return _NumKey(
              label: key,
              onTap: () => key == '⌫' ? onDelete() : onKey(key),
              isDelete: key == '⌫',
            );
          }).toList(),
        )).toList(),
      ),
    );
  }
}

class _NumKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDelete;
  const _NumKey({required this.label, required this.onTap, this.isDelete = false});

  @override
  State<_NumKey> createState() => _NumKeyState();
}

class _NumKeyState extends State<_NumKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 80, height: 72,
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: widget.isDelete
              ? Icon(Icons.backspace_outlined,
                  color: Colors.white.withOpacity(0.7), size: 22)
              : Text(widget.label, style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
