part of '../settings_screen.dart';

// ── Sync Tile ─────────────────────────────────────────────────────────────────
class _SyncTile extends StatefulWidget {
  const _SyncTile();

  @override
  State<_SyncTile> createState() => _SyncTileState();
}

class _SyncTileState extends State<_SyncTile> {
  bool _syncing = false;

  String _lastSyncText() {
    final box  = Hive.box('settings');
    final last = box.get('lastSyncTime', defaultValue: 0) as int;
    if (last == 0) return 'Never synced';
    final dt   = DateTime.fromMillisecondsSinceEpoch(last);
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inHours < 1)    return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)     return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _sync() async {
    if (!AuthService.isLoggedIn) {
      // Not logged in — go to login screen
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => login_nav.LoginScreen()));
      return;
    }
    setState(() => _syncing = true);
    await SyncService.syncAll();
    if (mounted) setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final isLoggedIn = AuthService.isLoggedIn;

    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF42A5F5).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: _syncing
            ? Padding(
          padding: const EdgeInsets.all(8),
          child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary),
        )
            : const Icon(Icons.cloud_sync_rounded,
            color: Color(0xFF42A5F5), size: 18),
      ),
      title: const Text('Sync to Cloud',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(
        isLoggedIn
            ? 'Last sync: ${_lastSyncText()}'
            : 'Sign in to enable cloud backup',
        style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.5)),
      ),
      trailing: Icon(
        isLoggedIn ? Icons.sync_rounded : Icons.login_rounded,
        color: theme.colorScheme.primary, size: 20,
      ),
      onTap: _syncing ? null : _sync,
    );
  }
}
