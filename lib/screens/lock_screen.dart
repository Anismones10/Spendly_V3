import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/pin_helper.dart';
import 'set_pin_screen.dart';
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
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

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

                const SizedBox(height: 32),

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

                const SizedBox(height: 16),

                // ── Forgot PIN? ────────────────────────────────────────────
                GestureDetector(
                  onTap: () => _showForgotPin(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Forgot PIN?',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        decoration: TextDecoration.underline,
                        decorationColor:
                        theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
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

  // ── Forgot PIN flow ───────────────────────────────────────────────────────
  void _showForgotPin(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Forgot PIN?',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Choose a recovery option',
                style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            const SizedBox(height: 24),

            // Secret word recovery
            _RecoveryOption(
              icon: Icons.key_rounded,
              color: const Color(0xFFFF9800),
              title: 'Use Secret Word',
              subtitle: 'Enter the secret word you set when creating your PIN',
              onTap: () {
                Navigator.pop(ctx);
                _showSecretWordInput(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Recovery Code input ────────────────────────────────────────────────────
  void _showSecretWordInput(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ctrl   = TextEditingController();
    String? errorMsg;
    bool obscureWord = true;
    final hint   = _box.get('secretWordHint', defaultValue: '') as String;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 40),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter Secret Word',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),

                // Hint
                if (hint.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFF9800).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            color: Color(0xFFFF9800), size: 16),
                        const SizedBox(width: 8),
                        Text('Hint: $hint',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF9800),
                            )),
                      ],
                    ),
                  ),

                TextField(
                  controller: ctrl,
                  obscureText: obscureWord,
                  decoration: InputDecoration(
                    labelText: 'Secret word',
                    errorText: errorMsg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureWord
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      // setLocal rebuilds the whole dialog → obscureWord persists
                      onPressed: () =>
                          setLocal(() => obscureWord = !obscureWord),
                    ),
                  ),
                  onChanged: (_) =>
                      setLocal(() => errorMsg = null),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final stored = _box.get('secretWordHash',
                              defaultValue: '') as String;
                          if (verifySecretWord(ctrl.text, stored)) {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SetPinScreen()),
                            );
                          } else {
                            setLocal(() => errorMsg =
                            'Incorrect word. Try again.');
                          }
                        },
                        child: const Text('Verify'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Reset PIN with secret word ───────────────────────────────────────────────
  void _showResetConfirm(BuildContext context) {
    // This option is now handled by _showSecretWordInput
    _showSecretWordInput(context);
  }

} // end _LockScreenState

// ── Recovery option tile ───────────────────────────────────────────────────────
class _RecoveryOption extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   subtitle;
  final VoidCallback onTap;

  const _RecoveryOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2A2A2A)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.5))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                size: 20),
          ],
        ),
      ),
    );
  }
}

enum _PinState { idle, success, error }