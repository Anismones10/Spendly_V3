part of '../settings_screen.dart';

// ── Security Section ──────────────────────────────────────────────────────────

class _SecuritySection extends StatefulWidget {
  const _SecuritySection();

  @override
  State<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<_SecuritySection> {
  final Box _box  = Hive.box('settings');
  final LocalAuthentication _auth = LocalAuthentication();

  bool get _lockEnabled => _box.get('lockEnabled',   defaultValue: false) as bool;
  bool get _bioEnabled  => _box.get('lockBiometric', defaultValue: true)  as bool;
  int  get _timeoutMins => _box.get('lockTimeout',   defaultValue: 30)    as int;

  static const _timeoutOptions = [0, 1, 5, 15, 30];
  static const _timeoutLabels  = ['Immediately', '1 min', '5 min', '15 min', '30 min'];

  Future<void> _toggleLock(bool value) async {
    if (value) {
      // Enabling lock → go set a PIN
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const SetPinScreen()),
      );
      if (result == true) setState(() {});
    } else {
      // Disabling lock → just verify current PIN with a simple dialog
      final verified = await _verifyPinDialog();
      if (verified) {
        _box.put('lockEnabled', false);
        _box.put('lockPin', '');
        setState(() {});
      }
    }
  }

  /// Simple 4-dot PIN entry dialog — only verifies, no extra steps
  Future<bool> _verifyPinDialog() async {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String entered = '';
    String? errorMsg;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          void onKey(String key) {
            if (key == '⌫') {
              if (entered.isNotEmpty) {
                setLocal(() => entered =
                    entered.substring(0, entered.length - 1));
              }
              return;
            }
            if (entered.length >= 4) return;
            setLocal(() { entered += key; errorMsg = null; });

            if (entered.length == 4) {
              final saved = _box.get('lockPin', defaultValue: '') as String;
              if (hashPin(entered) == saved) {
                Navigator.pop(ctx, true);
              } else {
                setLocal(() { errorMsg = 'Incorrect PIN'; entered = ''; });
              }
            }
          }

          return Dialog(
            backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter your PIN',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Confirm to disable app lock',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      )),
                  const SizedBox(height: 24),

                  // 4 dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < entered.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: errorMsg != null
                              ? Colors.red
                              : filled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                              .withOpacity(0.15),
                        ),
                      );
                    }),
                  ),

                  if (errorMsg != null) ...[
                    const SizedBox(height: 8),
                    Text(errorMsg!,
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],

                  const SizedBox(height: 20),

                  // Mini keypad
                  ...[ ['1','2','3'], ['4','5','6'], ['7','8','9'] ]
                      .map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: row.map((d) => _MiniKey(
                        digit: d,
                        onTap: () => onKey(d),
                      )).toList(),
                    ),
                  )),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 64),
                      const SizedBox(width: 12),
                      _MiniKey(digit: '0', onTap: () => onKey('0')),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 64, height: 48,
                        child: IconButton(
                          onPressed: () => onKey('⌫'),
                          icon: Icon(Icons.backspace_outlined,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                              size: 20),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    return result ?? false;
  }

  Future<void> _changePin() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => const SetPinScreen(isChanging: true)),
    );
    setState(() {});
  }

  Future<void> _toggleBiometric(bool value) async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (value && !canCheck) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometrics not available on this device.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    } catch (_) {}
    _box.put('lockBiometric', value);
    setState(() {});
  }

  void _showTimeoutPicker() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Lock After',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('How long in background before locking',
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.45))),
            const SizedBox(height: 16),
            ...List.generate(_timeoutOptions.length, (i) {
              final isSelected = _timeoutMins == _timeoutOptions[i];
              return GestureDetector(
                onTap: () {
                  _box.put('lockTimeout', _timeoutOptions[i]);
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.08)
                        : (isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.35)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_timeoutLabels[i],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.primary : null,
                            )),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: theme.colorScheme.primary, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _timeoutLabel() {
    final idx = _timeoutOptions.indexOf(_timeoutMins);
    return idx >= 0 ? _timeoutLabels[idx] : '$_timeoutMins min';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Master lock toggle ──────────────────────────────────────────
        _SettingTile(
          icon: Icons.lock_rounded,
          title: 'App Lock',
          subtitle: _lockEnabled
              ? 'PIN required to open Spendly'
              : 'Tap to enable PIN lock',
          trailing: Switch.adaptive(
            value: _lockEnabled,
            onChanged: _toggleLock,
          ),
        ),

        if (_lockEnabled) ...[
          // ── Change PIN ────────────────────────────────────────────────
          _SettingTile(
            icon: Icons.pin_rounded,
            title: 'Change PIN',
            subtitle: 'Update your current PIN',
            subtitleColor: const Color(0xFF26A69A),
            iconColor: const Color(0xFF26A69A),
            onTap: _changePin,
          ),

          // ── Biometric ─────────────────────────────────────────────────
          _SettingTile(
            icon: Icons.fingerprint_rounded,
            title: 'Biometric Unlock',
            subtitle: 'Use fingerprint or face to unlock',
            subtitleColor: const Color(0xFF5C6BC0),
            iconColor: const Color(0xFF5C6BC0),
            trailing: Switch.adaptive(
              value: _bioEnabled,
              onChanged: _toggleBiometric,
            ),
          ),

          // ── Timeout ───────────────────────────────────────────────────
          _SettingTile(
            icon: Icons.timer_rounded,
            title: 'Lock After',
            subtitle: _timeoutLabel() + ' of background',
            subtitleColor: const Color(0xFFEF6C00),
            iconColor: const Color(0xFFEF6C00),
            onTap: _showTimeoutPicker,
          ),
        ],
      ],
    );
  }
}
