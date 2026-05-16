import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shows a one-time hint banner. Dismissed permanently via Hive.
/// Usage:
///   HintBanner(
///     hintKey: 'hint_dashboard',
///     icon: Icons.swipe_rounded,
///     title: 'Swipe to see wallets',
///     message: 'The card at the top shows all wallets. Swipe left or right to view each one.',
///   )
class HintBanner extends StatefulWidget {
  final String hintKey;
  final IconData icon;
  final String title;
  final String message;
  final Color? color;

  const HintBanner({
    super.key,
    required this.hintKey,
    required this.icon,
    required this.title,
    required this.message,
    this.color,
  });

  @override
  State<HintBanner> createState() => _HintBannerState();
}

class _HintBannerState extends State<HintBanner> {
  late bool _shown;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    _shown = box.get(widget.hintKey, defaultValue: false) as bool;
  }

  void _dismiss() {
    final box = Hive.box('settings');
    box.put(widget.hintKey, true);
    setState(() => _shown = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_shown) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.color ?? theme.colorScheme.primary;

    return Animate(
      effects: const [
        SlideEffect(
          begin: Offset(0, 1),
          end: Offset(0, 0),
          duration: Duration(milliseconds: 400),
          curve: Curves.easeOut,
        ),
        FadeEffect(duration: Duration(milliseconds: 300)),
      ],
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Got it button
            GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Got it',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
