part of '../settings_screen.dart';

// ── Isolated Switch — same pattern as _SecuritySection ───────────────────────
// Reads Hive directly into local state. Only THIS widget rebuilds on toggle.

class _SmoothSwitch extends StatefulWidget {
  final String hiveKey;       // Hive key to read/write
  final bool defaultValue;
  final VoidCallback onToggle; // Provider call (for notifyListeners)

  const _SmoothSwitch({
    required this.hiveKey,
    required this.defaultValue,
    required this.onToggle,
  });

  @override
  State<_SmoothSwitch> createState() => _SmoothSwitchState();
}

class _SmoothSwitchState extends State<_SmoothSwitch> {
  final Box _box = Hive.box('settings');
  late bool _value;

  @override
  void initState() {
    super.initState();
    // Read directly from Hive — same as SecuritySection does
    _value = _box.get(widget.hiveKey, defaultValue: widget.defaultValue) as bool;
  }

  void _toggle(bool v) {
    setState(() => _value = v);       // Only this widget rebuilds
    HapticFeedback.lightImpact();
    widget.onToggle();                // Tell provider (for theme/sound changes)
  }

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: _value,
      onChanged: _toggle,
    );
  }
}
