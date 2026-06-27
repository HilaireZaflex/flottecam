import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/pin_service.dart';

class CreatePinScreen extends ConsumerStatefulWidget {
  const CreatePinScreen({super.key});

  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen>
    with SingleTickerProviderStateMixin {
  String _pin        = '';
  String _confirmPin = '';
  bool _confirming   = false;
  String? _error;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onKey(String digit) {
    setState(() {
      _error = null;
      if (_confirming) {
        if (_confirmPin.length < 4) _confirmPin += digit;
        if (_confirmPin.length == 4) _validate();
      } else {
        if (_pin.length < 4) _pin += digit;
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) setState(() => _confirming = true);
          });
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = null;
      if (_confirming) {
        if (_confirmPin.isNotEmpty) _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _validate() async {
    if (_pin != _confirmPin) {
      _shakeCtrl.forward(from: 0);
      setState(() {
        _error      = 'Les codes ne correspondent pas';
        _confirmPin = '';
        _confirming = false;
        _pin        = '';
      });
      return;
    }
    // Sauvegarder le PIN
    await ref.read(pinServiceProvider).savePin(_pin);
    if (mounted) context.go('/dashboard');
  }

  void _skip() => context.go('/dashboard');

  @override
  Widget build(BuildContext context) {
    final current = _confirming ? _confirmPin : _pin;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            // ── Logo ──────────────────────────────────────────────────
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 20, offset: const Offset(0, 8),
                )],
              ),
              child: const Icon(Icons.local_shipping_rounded,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(height: 24),

            // ── Titre ─────────────────────────────────────────────────
            Text(
              _confirming ? 'Confirmez votre code' : 'Créez votre code PIN',
              style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _confirming
                  ? 'Entrez à nouveau votre code PIN'
                  : 'Ce code remplacera votre mot de passe',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // ── Indicateurs 4 points ───────────────────────────────────
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                final offset = _shakeAnim.value * 16 *
                    (0.5 - (_shakeCtrl.value % 0.5)).abs() * 2;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < current.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: filled ? 20 : 16,
                    height: filled ? 20 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppTheme.primary : Colors.white.withOpacity(0.2),
                      boxShadow: filled ? [BoxShadow(
                        color: AppTheme.primary.withOpacity(0.6),
                        blurRadius: 12,
                      )] : [],
                    ),
                  );
                }),
              ),
            ),

            // ── Message d'erreur ───────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _error != null ? 40 : 0,
              child: _error != null ? Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                ),
              ) : null,
            ),

            const Spacer(),

            // ── Clavier numérique ──────────────────────────────────────
            _NumPad(onKey: _onKey, onDelete: _onDelete),
            const SizedBox(height: 16),

            // ── Passer ────────────────────────────────────────────────
            TextButton(
              onPressed: _skip,
              child: Text(
                'Passer pour l\'instant',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
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

// ── Clavier numérique réutilisable ────────────────────────────────────────────
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
              : Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
