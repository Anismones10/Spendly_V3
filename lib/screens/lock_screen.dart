import 'package:flutter/material.dart';
import '../utils/pin_helper.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with TickerProviderStateMixin {
  final LocalAuthentication _auth = LocalAuthentication();
  final Box _box = Hive.box('settings');

  String _entered = '';
  bool _hasError = false;
  bool _biometricAvailable = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
    _checkBiometric();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    try {
      final canCheck  = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      final biometricEnabled =
          _box.get('lockBiometric', defaultValue: true) as bool;

      if (mounted) {
        setState(() =>
            _biometricAvailable = canCheck && isSupported && biometricEnabled);
      }

      // Auto-trigger biometric on open
      if (_biometricAvailable) {
        await Future.delayed(const Duration(milliseconds: 300));
        _tryBiometric();
      }
    } catch (_) {}
  }

  Future<void> _tryBiometric() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to access Spendly',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (authenticated && mounted) {
        _unlock();
      }
    } catch (_) {}
  }

  void _onKey(String key) {
    if (key == '⌫') {
      if (_entered.isNotEmpty) {
        setState(() {
          _entered = _entered.substring(0, _entered.length - 1);
          _hasError = false;
        });
      }
      return;
    }

    if (_entered.length >= 6) return;

    setState(() => _entered += key);

    // Auto-submit when PIN length matches saved PIN
    final savedPin = _box.get('lockPin', defaultValue: '') as String;
    // Saved pin is stored as hash of original — check length by trying
    // We try submit when entered length is 4, 5, or 6
    if (_entered.length >= 4) {
      _checkPin();
    }
  }

  void _checkPin() {
    final savedHash = _box.get('lockPin', defaultValue: '') as String;
    final enteredHash = hashPin(_entered);

    if (enteredHash == savedHash) {
      _unlock();
    } else if (_entered.length >= 6) {
      _onWrongPin();
    }
  }

  void _onWrongPin() {
    HapticFeedback.heavyImpact();
    setState(() => _hasError = true);
    _shakeCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() { _entered = ''; _hasError = false; });
    });
  }

  void _unlock() {
    HapticFeedback.lightImpact();
    // Update last active time
    _box.put('lockLastActive', DateTime.now().millisecondsSinceEpoch);
    widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pinLength = _getPinLength();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // ── App icon + title ───────────────────────────────────────
            Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: theme.colorScheme.primary, size: 38),
                ).animate().scale(
                    begin: const Offset(0.8, 0.8),
                    duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text('Spendly',
                  style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  )).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 8),
                Text('Enter your PIN to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  )).animate().fadeIn(delay: 200.ms),
              ],
            ),

            const SizedBox(height: 40),

            // ── PIN dots ───────────────────────────────────────────────
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) {
                final offset = sin(_shakeAnim.value * pi * 6) * 10;
                return Transform.translate(
                  offset: Offset(offset, 0), child: child);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pinLength > 0 ? pinLength : 4, (i) {
                  final filled = i < _entered.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16, height: 16,
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
                              blurRadius: 8)]
                          : null,
                    ),
                  );
                }),
              ),
            ).animate().fadeIn(delay: 250.ms),

            if (_hasError) ...[
              const SizedBox(height: 12),
              Text('Incorrect PIN',
                style: const TextStyle(
                  color: Color(0xFFE57373),
                  fontSize: 13, fontWeight: FontWeight.w600,
                )).animate().fadeIn(),
            ],

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
                      // Biometric button
                      _biometricAvailable
                          ? _bioKey(theme, isDark)
                          : const SizedBox(width: 72, height: 72),
                      _numKey('0', theme, isDark),
                      _backKey(theme, isDark),
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

  // Get pin length from stored hash (try 4 first, then allow up to 6)
  int _getPinLength() {
    // We don't store PIN length separately, so we use dots = max entered
    // Show 4 dots minimum, expand as user types
    return max(4, _entered.length);
  }

  Widget _keyRow(List<String> keys, ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _numKey(k, theme, isDark)).toList(),
    );
  }

  Widget _numKey(String digit, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _onKey(digit);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
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
              color: theme.colorScheme.onSurface,
            )),
        ),
      ),
    );
  }

  Widget _backKey(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _onKey('⌫');
      },
      child: SizedBox(
        width: 72, height: 72,
        child: Center(
          child: Icon(Icons.backspace_outlined,
            color: theme.colorScheme.onSurface.withOpacity(0.6), size: 24)),
      ),
    );
  }

  Widget _bioKey(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _tryBiometric,
      child: SizedBox(
        width: 72, height: 72,
        child: Center(
          child: Icon(Icons.fingerprint_rounded,
            color: theme.colorScheme.primary, size: 34)),
      ),
    );
  }
}
