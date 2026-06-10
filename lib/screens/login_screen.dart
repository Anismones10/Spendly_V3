import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });

    final user = await AuthService.signInWithGoogle();

    if (user == null) {
      setState(() { _loading = false; _error = 'Sign in cancelled.'; });
      return;
    }

    final box             = Hive.box('settings');
    final alreadyMigrated = box.get('dataMigrated', defaultValue: false) as bool;

    if (!alreadyMigrated) {
      try {
        await SyncService.restoreFromCloud();
      } catch (_) {
        await SyncService.migrateLocalData();
      }
    } else {
      await SyncService.syncIfNeeded();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  void _skipForNow() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // ── Logo ──────────────────────────────────────────────────
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

              const SizedBox(height: 24),

              Text('Spendly',
                  style: TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -1,
                  )).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 12),

              Text(
                'Track your spending.\nReach your goals.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, height: 1.5,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const Spacer(),

              // ── Feature list ───────────────────────────────────────────
              ...[
                ('📊', 'Track every expense and income'),
                ('💳', 'Manage multiple wallets'),
                ('☁️', 'Backed up automatically to cloud'),
              ].map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Text(f.$1, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 14),
                        Text(f.$2,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            )),
                      ],
                    ),
                  )),

              const SizedBox(height: 32),

              // ── Error ──────────────────────────────────────────────────
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13)),
                ),
                const SizedBox(height: 12),
              ],

              // ── Google Sign In button ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    foregroundColor: theme.colorScheme.onSurface,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.g_mobiledata_rounded,
                                size: 28,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 10),
                            const Text('Continue with Google',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

              const SizedBox(height: 12),

              // ── Skip button ────────────────────────────────────────────
              TextButton(
                onPressed: _skipForNow,
                child: Text(
                  'Skip for now  →',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 8),

              Text(
                'You can sign in later from Settings\nto enable cloud backup.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
