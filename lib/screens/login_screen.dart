import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
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
      // First time signing in — check both local and cloud
      final hasCloud = await SyncService.hasCloudData();
      final hasLocal = SyncService.hasLocalData();

      if (hasCloud && hasLocal) {
        // ── Both have data — first confirm account ownership ─────────
        if (!mounted) return;
        final confirmed = await _showAccountConfirmDialog(user);
        if (confirmed != true) {
          // User not sure — sign out, keep local data safe
          await AuthService.signOut();
          setState(() => _loading = false);
          return;
        }
        // Confirmed it's their account — ask which data to keep
        if (!mounted) return;
        final keepLocal = await _showConflictDialog();
        if (keepLocal == null) {
          await AuthService.signOut();
          setState(() => _loading = false);
          return;
        }
        if (keepLocal) {
          await SyncService.migrateLocalData();
        } else {
          await SyncService.restoreFromCloud();
          if (mounted) {
            context.read<SettingsProvider>().refresh();
          }
        }
      } else if (hasCloud) {
        // Only cloud has data (new device, existing account)
        await SyncService.restoreFromCloud();
        if (mounted) {
          context.read<SettingsProvider>().refresh();
        }
      } else {
        // Only local has data (or both empty) — push local to cloud
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

  Future<bool?> _showAccountConfirmDialog(dynamic user) async {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final email  = user?.email ?? 'Unknown account';
    final name   = user?.displayName ?? '';
    final photo  = user?.photoURL;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm your account',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This Google account already has cloud data. Make sure this is YOUR account before continuing.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),

            // Account card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  // Profile photo or icon
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.15),
                    backgroundImage: photo != null
                        ? NetworkImage(photo)
                        : null,
                    child: photo == null
                        ? Icon(Icons.person_rounded,
                            color: theme.colorScheme.primary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (name.isNotEmpty)
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        Text(email,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'If this is not your account, tap Cancel to protect your local data.',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        height: 1.4),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, this is my account'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConflictDialog() async {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.merge_type_rounded,
                color: Color(0xFFFF9800), size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Data Conflict',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You have data on this device AND data in the cloud. Which one do you want to keep?',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            // Keep local option
            _ConflictOption(
              icon: Icons.phone_android_rounded,
              color: const Color(0xFF42A5F5),
              title: 'Keep this device',
              subtitle: 'Your local data will be uploaded to cloud',
              onTap: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: 10),
            // Keep cloud option
            _ConflictOption(
              icon: Icons.cloud_rounded,
              color: const Color(0xFF2ECC71),
              title: 'Keep cloud data',
              subtitle: 'Cloud data will be downloaded to this device',
              onTap: () => Navigator.pop(ctx, false),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
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

// ── Conflict option tile ───────────────────────────────────────────────────────
class _ConflictOption extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   subtitle;
  final VoidCallback onTap;

  const _ConflictOption({
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2A2A2A)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.5))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                size: 18),
          ],
        ),
      ),
    );
  }
}
