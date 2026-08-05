part of '../settings_screen.dart';

// ── All Wallets Card Color Tile ───────────────────────────────────────────────


// ── Account Tile ──────────────────────────────────────────────────────────────
class _AccountTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends State<_AccountTile> {
  bool _loading = false;

  // Check internet connectivity by trying to reach Google DNS
  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleTap() async {
    if (_loading) return;

    // Must be logged in to switch/add account
    if (!AuthService.isLoggedIn) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => login_nav.LoginScreen()));
      return;
    }

    // Check internet first
    setState(() => _loading = true);
    final online = await _hasInternet();
    if (!mounted) return;

    if (!online) {
      setState(() => _loading = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.wifi_off_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('No Internet'),
          ]),
          content: const Text(
            'You need an internet connection to switch accounts.\n\n'
                'Your data is stored locally — please connect to the internet '
                'so we can sync your data before switching.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Internet available — confirm sync + switch
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(widget.icon, color: const Color(0xFF26A69A)),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.title)),
        ]),
        content: const Text(
          'Your data will be synced to the cloud before switching accounts. '
              'This ensures nothing is lost.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF26A69A),
            ),
            child: const Text('Sync & Switch'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      setState(() => _loading = false);
      return;
    }

    // Sync data to cloud
    try {
      await SyncService.syncAll();
    } catch (_) {
      // Sync failed — warn user but allow them to proceed
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Sync Failed'),
          ]),
          content: const Text(
            'We could not sync your data to the cloud. '
                'Switching now may result in data loss.\n\nProceed anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Proceed Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) {
        setState(() => _loading = false);
        return;
      }
    }

    // Sign out + disconnect Google so the account picker appears on next sign-in
    await AuthService.signOut();
    try {
      await AuthService.disconnectGoogle();
    } catch (_) {}

    // Clear all local data so the new account starts fresh
    // (new account will either restore its own cloud data or start empty)
    await SyncService.clearAllLocalData();

    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => login_nav.LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF26A69A).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: _loading
            ? const Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF26A69A)),
        )
            : Icon(widget.icon, color: const Color(0xFF26A69A), size: 18),
      ),
      title: Text(widget.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(widget.subtitle,
          style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF26A69A))),
      trailing: _loading
          ? null
          : Icon(Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurface.withOpacity(0.3), size: 20),
      onTap: _loading ? null : _handleTap,
    );
  }
}
