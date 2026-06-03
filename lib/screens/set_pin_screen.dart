import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/pin_helper.dart';

class SetPinScreen extends StatefulWidget {
  final bool isChanging;
  const SetPinScreen({super.key, this.isChanging = false});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen>
    with SingleTickerProviderStateMixin {
  final Box _box = Hive.box('settings');

  // Always 4 digits
  static const int _pinLength = 4;

  // Steps: 0 = verify old (only if changing), 1 = enter new, 2 = confirm
  int    _step     = 0;
  String _entered  = '';
  String _firstPin = '';
  bool   _hasError = false;
  String _errorMsg = '';

  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    if (!widget.isChanging) _step = 1;

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0,   end: -14), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14, end: 14),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: 14,  end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10,  end: 0),   weight: 1),
    ]).animate(CurvedAnimation(
        parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _title {
    if (_step == 0) return 'Enter current PIN';
    if (_step == 1) return 'Set new PIN';
    return 'Confirm new PIN';
  }

  String get _subtitle {
    if (_step == 0) return 'Enter your current 4-digit PIN';
    if (_step == 1) return 'Choose a 4-digit PIN';
    return 'Re-enter your PIN to confirm';
  }

  void _onKey(String key) {
    if (key == '⌫') {
      if (_entered.isNotEmpty) {
        setState(() {
          _entered  = _entered.substring(0, _entered.length - 1);
          _hasError = false;
        });
      }
      return;
    }

    if (_entered.length >= _pinLength) return;

    setState(() { _entered += key; _hasError = false; });

    // Auto-submit on 4th digit
    if (_entered.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 100), _onSubmit);
    }
  }

  void _onSubmit() {
    if (_step == 0) {
      // Verify old PIN
      final savedHash = _box.get('lockPin', defaultValue: '') as String;
      if (hashPin(_entered) == savedHash) {
        setState(() { _step = 1; _entered = ''; _hasError = false; });
      } else {
        _showError('Incorrect PIN');
      }
      return;
    }

    if (_step == 1) {
      setState(() {
        _firstPin = _entered;
        _step     = 2;
        _entered  = '';
        _hasError = false;
      });
      return;
    }

    // Step 2 — confirm
    if (_entered == _firstPin) {
      _box.put('lockPin',       hashPin(_entered));
      _box.put('lockPinLength', _pinLength);
      _box.put('lockEnabled',   true);
      _box.put('lockLastActive',
          DateTime.now().millisecondsSinceEpoch);

      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isChanging
                ? 'PIN changed successfully!'
                : 'PIN set successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF2ECC71),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      setState(() {
        _firstPin = '';
        _step     = 1;
      });
      _showError("PINs don't match. Try again.");
    }
  }

  void _showError(String msg) {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 80),
        () => HapticFeedback.heavyImpact());
    setState(() {
      _hasError = true;
      _errorMsg = msg;
      _entered  = '';
    });
    _shakeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        elevation: 0,
        title: Text(widget.isChanging ? 'Change PIN' : 'Set PIN'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // ── Step indicator (only when changing) ────────────────────
            if (widget.isChanging) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i <= _step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _step ? 24 : 8, height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: active
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
            ],

            // ── Icon ───────────────────────────────────────────────────
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _step == 2
                    ? Icons.lock_outline_rounded
                    : Icons.pin_outlined,
                color: theme.colorScheme.primary, size: 32),
            ).animate().scale(
                begin: const Offset(0.8, 0.8),
                duration: 300.ms, curve: Curves.elasticOut),

            const SizedBox(height: 20),

            Text(_title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700)),

            const SizedBox(height: 8),

            Text(_subtitle,
                style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),

            const SizedBox(height: 44),

            // ── 4 PIN dots with shake ──────────────────────────────────
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(_shakeAnim.value, 0), child: child),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _entered.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasError
                          ? const Color(0xFFE57373)
                          : filled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.15),
                      boxShadow: filled && !_hasError
                          ? [BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.4),
                              blurRadius: 10)]
                          : null,
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 12),

            // ── Error text ─────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _hasError ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                _hasError ? _errorMsg : ' ',
                style: const TextStyle(
                    color: Color(0xFFE57373),
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),

            const Spacer(),

            // ── Keypad ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  _keyRow(['1', '2', '3'], theme, isDark),
                  const SizedBox(height: 14),
                  _keyRow(['4', '5', '6'], theme, isDark),
                  const SizedBox(height: 14),
                  _keyRow(['7', '8', '9'], theme, isDark),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 72, height: 72),
                      _numKey('0', theme, isDark),
                      _backKey(theme),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _keyRow(List<String> keys, ThemeData theme, bool isDark) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((k) => _numKey(k, theme, isDark)).toList(),
      );

  Widget _numKey(String digit, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); _onKey(digit); },
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Center(
          child: Text(digit,
            style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface))),
      ),
    );
  }

  Widget _backKey(ThemeData theme) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); _onKey('⌫'); },
      child: SizedBox(
        width: 72, height: 72,
        child: Center(
          child: Icon(Icons.backspace_outlined,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            size: 24)),
      ),
    );
  }
}
