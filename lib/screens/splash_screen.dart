import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../main.dart';
import 'main_shell.dart';
import 'login_screen.dart';
import 'lock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Show splash for minimum 1.5 seconds
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Run nightly sync if needed (non-blocking)
    SyncService.syncIfNeeded();

    // Check app lock
    final box        = Hive.box('settings');
    final lockEnabled = box.get('lockEnabled', defaultValue: false) as bool;
    final hasPin      = (box.get('lockPin', defaultValue: '') as String).isNotEmpty;

    if (lockEnabled && hasPin) {
      // Push lock screen on TOP (not replace) so splash stays mounted
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LockScreen(
            onUnlocked: () => Navigator.of(context).pop(),
          ),
        ),
      );
      // Lock screen was dismissed (unlocked) — now navigate
      if (mounted) _goToApp();
      return;
    }

    _goToApp();
  }

  void _goToApp() {
    if (!mounted) return;

    // Check if user is logged in
    if (AuthService.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }

    // pushReplacement swaps the route stack synchronously (the transition
    // animation is purely visual), so by the next frame the splash route
    // is already gone. Signal it's now safe for widget-triggered pushes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      splashNavigationDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(Icons.account_balance_wallet_rounded,
                  color: theme.colorScheme.primary, size: 52),
            ).animate().scale(
                begin: const Offset(0.8, 0.8),
                duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 20),

            Text('Spendly',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -1,
                )).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 8),

            Text('Your personal finance companion',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                )).animate().fadeIn(delay: 350.ms),

            const SizedBox(height: 48),

            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}