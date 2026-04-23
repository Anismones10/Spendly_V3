import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StreakBadge extends StatelessWidget {
  final int streak;
  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    if (streak == 0) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => _showStreakInfo(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 1000.ms,
          ),
    );
  }

  void _showStreakInfo(BuildContext context) {
    String message;
    if (streak >= 30) {
      message = 'Amazing! One full month under budget! 🏆';
    } else if (streak >= 7) {
      message = '$streak days in a row! You are on fire! 🔥';
    } else {
      message = '$streak day streak! Keep it up!';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFFFF9800),
      ),
    );
  }
}
