import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/pin_helper.dart';
import '../utils/biometric_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with TickerProviderStateMixin {
  final Box _box = Hive.box('settings');

  String    _entered  = '';
  _PinState _pinState = _PinState.idle;

  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;
  late AnimationController _resultCtrl;
  late Animation<double>   _resultScale;

  bool     _biometricAvailable = false;
  BioIcon _bioIcon            = BioIcon.fingerprint;

  static const int _pinLength = 4;

  @override
  void initState() {
    super.initState();

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

    _resultCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _resultScale = CurvedAnimation(
        parent: _resultCtrl, curve: Curves.elasticOut);

    _initBiometric();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  Future<void> _initBiometric() async {
    final bioEnabled =
        _box.get('lockBiometric', defaultValue: true) as bool;
    if (!bioEnabled) return;

    final available = await BiometricService.isAvailable();
    final icon      = await BiometricService.getIcon();

    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _bioIcon            = icon;
      });
    }

    // Auto-trigger on open
    if (available) {
      await Future.delayed(const Duration(milliseconds: 400));
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (_pinState != _PinState.idle) return;
    final success = await BiometricService.authenticate();
    if (success && mounted) _onSuccess();
  }

  // ── Key input ──────────────────────────────────────────────────────────────
  void _onKey(String key) {
    if (_pinState != _PinState.idle) return;

    if (key == '⌫') {
      if (_entered.isNotEmpty) {
        setState(() => _entered =
            _entered.substring(0, _entered.length - 1));
      }
      return;
    }

    if (_entered.length >= _pinLength) return;
    setState(() => _entered += key);

    if (_entered.length == _pinLength) _checkPin();
  }

  void _checkPin() {
    final savedHash = _box.get('lockPin', defaultValue: '') as String;
    if (hashPin(_entered) == savedHash) {
      _onSuccess();
    } else {
      _onError();
    }
  }

  void _onSuccess() {
    HapticFeedback.lightImpact();
    setState(() => _pinState = _PinState.success);
    _resultCtrl.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _box.put('lockLastActive',
            DateTime.now().millisecondsSinceEpoch);
        widget.onUnlocked();
      }
    });
  }

  void _onError() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 80),
        () => HapticFeedback.heavyImpact());
    Future.delayed(const Duration(milliseconds: 160),
        () => HapticFeedback.heavyImpact());

    setState(() => _pinState = _PinState.error);
    _resultCtrl.forward(from: 0);
    _shakeCtrl.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() { _entered = ''; _pinState = _PinState.idle; });
        _resultCtrl.reset();
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 1.5),
              ),
              child: Icon(Icons.account_balance_wallet_rounded,
                  color: theme.colorScheme.primary, size: 38),
            ).animate().scale(
                begin: const Offset(0.8, 0.8),
                duration: 400.ms, curve: Curves.elasticOut),

            const SizedBox(height: 16),

            Text('Spendly',
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5))
                .animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 8),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                key: ValueKey(_pinState),
                _pinState == _PinState.error
                    ? 'Incorrect PIN. Try again.'
                    : _pinState == _PinState.success
                        ? 'Unlocked!'
                        : 'Enter your PIN to continue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _pinState != _PinState.idle
                      ? FontWeight.w600 : FontWeight.w400,
                  color: _pinState == _PinState.error
                      ? const Color(0xFFE57373)
                      : _pinState == _PinState.success
                          ? const Color(0xFF2ECC71)
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 48),

            _buildPinIndicator(theme),

            const Spacer(),

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
                      _biometricAvailable
                          ? _bioKey(theme)
                          : const SizedBox(width: 72, height: 72),
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

  Widget _buildPinIndicator(ThemeData theme) {
    if (_pinState == _PinState.success || _pinState == _PinState.error) {
      final isSuccess = _pinState == _PinState.success;
      final color =
          isSuccess ? const Color(0xFF2ECC71) : const Color(0xFFE57373);
      return ScaleTransition(
        scale: _resultScale,
        child: Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
          ),
          child: Icon(
            isSuccess ? Icons.check_rounded : Icons.close_rounded,
            color: color, size: 38),
        ),
      );
    }

    return AnimatedBuilder(
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
              color: filled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.15),
              boxShadow: filled
                  ? [BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.45),
                      blurRadius: 10)]
                  : null,
            ),
          );
        }),
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
      onTap: () {
        if (_pinState != _PinState.idle) return;
        HapticFeedback.lightImpact();
        _onKey(digit);
      },
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Center(child: Text(digit,
          style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface))),
      ),
    );
  }

  Widget _backKey(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        if (_pinState != _PinState.idle) return;
        HapticFeedback.lightImpact();
        _onKey('⌫');
      },
      child: SizedBox(width: 72, height: 72,
        child: Center(child: Icon(Icons.backspace_outlined,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          size: 24))),
    );
  }

  Widget _bioKey(ThemeData theme) {
    return GestureDetector(
      onTap: _tryBiometric,
      child: SizedBox(width: 72, height: 72,
        child: Center(child: Icon(
          _bioIcon == BioIcon.face
              ? Icons.face_rounded
              : Icons.fingerprint_rounded,
          color: theme.colorScheme.primary, size: 36))),
    );
  }
}

enum _PinState { idle, success, error }
