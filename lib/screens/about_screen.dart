import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // ── URL launchers ─────────────────────────────────────────────────────────

  Future<void> _launch(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Copied to clipboard!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          children: [
            // ── App card ──────────────────────────────────────────────
            _buildAppCard(context, isDark, theme)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1),

            const SizedBox(height: 24),

            // ── Description ───────────────────────────────────────────
            _buildSection(
              context,
              isDark,
              title: 'About Spendly',
              child: Text(
                'Spendly is a calm, confident, and beautifully designed personal finance tracker built to help you understand where your money goes — without the stress.\n\n'
                'Whether you\'re tracking daily coffee runs or planning a big savings goal, Spendly keeps everything organized in one place. Add expenses in seconds, visualize your spending with smart charts, set monthly budgets, and grow your savings jar — all offline, all private, all yours.\n\n'
                'Built for people who want to be more intentional with money, without the complexity of traditional finance apps.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(begin: 0.1),

            const SizedBox(height: 20),

            // ── Contact ───────────────────────────────────────────────
            _buildSection(
              context,
              isDark,
              title: 'Contact & Social',
              child: Column(
                children: [
                  _ContactTile(
                    icon: Icons.email_rounded,
                    color: const Color(0xFFE57373),
                    label: 'Email',
                    value: 'anis.mones.official@gmail.com',
                    onTap: () => _launch(
                        context, 'mailto:anis.mones.official@gmail.com'),
                  ),
                  const SizedBox(height: 10),
                  _ContactTile(
                    icon: Icons.camera_alt_rounded,
                    color: const Color(0xFFE91E8C),
                    label: 'Instagram',
                    value: '@anis_mones10',
                    onTap: () => _launch(
                        context, 'https://www.instagram.com/anis_mones10'),
                  ),
                  const SizedBox(height: 10),
                  _ContactTile(
                    icon: Icons.work_rounded,
                    color: const Color(0xFF0077B5),
                    label: 'LinkedIn',
                    value: 'Anis Mones',
                    onTap: () => _launch(
                        context,
                        'https://linkedin.com/in/anis-mones-325571399'),
                  ),
                  const SizedBox(height: 10),
                  _ContactTile(
                    icon: Icons.send_rounded,
                    color: const Color(0xFF2AABEE),
                    label: 'Telegram',
                    value: '@Mones_Anis',
                    onTap: () => _launch(
                        context, 'https://t.me/Mones_Anis'),
                  ),
                  const SizedBox(height: 10),
                  _ContactTile(
                    icon: Icons.code_rounded,
                    color: const Color(0xFF8E8E93),
                    label: 'GitHub',
                    value: 'Anismones10',
                    onTap: () => _launch(
                        context, 'https://github.com/Anismones10'),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.1),

            const SizedBox(height: 20),

            // ── App info ──────────────────────────────────────────────
            _buildSection(
              context,
              isDark,
              title: 'App Info',
              child: Column(
                children: [
                  _InfoRow(label: 'Version', value: '1.1.0'),
                  const Divider(height: 20),
                  _InfoRow(label: 'Developer', value: 'Anis Mones'),
                  const Divider(height: 20),
                  _InfoRow(label: 'Platform', value: 'Android & iOS'),
                  const Divider(height: 20),
                  _InfoRow(label: 'Storage', value: 'Local only — no cloud'),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.1),

            const SizedBox(height: 32),

            // ── Made with love ────────────────────────────────────────
            Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B00).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/blaze_fang.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Made with ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    Icon(
                      Icons.favorite_rounded,
                      color: const Color(0xFFE57373),
                      size: 16,
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.25, 1.25),
                          duration: 800.ms,
                          curve: Curves.easeInOut,
                        ),
                    Text(
                      ' by Blaze Fang Group',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF6B00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '© 2026 Spendly · Blaze Fang Group',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildAppCard(BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Spendly',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Track. Save. Grow.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Version 1.1.0',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    bool isDark, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

// ── Contact Tile ──────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Open link icon instead of copy icon
            Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: color.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.55),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
