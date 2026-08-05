part of '../settings_screen.dart';

// ── Mini key for PIN verify dialog ────────────────────────────────────────────
class _MiniKey extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;
  const _MiniKey({required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64, height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(digit,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
