import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenshot_detect/flutter_screenshot_detect.dart';
import 'package:hive/hive.dart';

/// Watches for screenshots and reminds the user what a screenshot of their
/// finances actually contains before they share it.
///
/// Wraps the app shell so the warning works on every screen. The reminder can
/// be turned off for good — the choice is kept in the `settings` box under
/// `screenshotWarnDisabled`.
class ScreenshotGuard extends StatefulWidget {
  final Widget child;
  const ScreenshotGuard({super.key, required this.child});

  @override
  State<ScreenshotGuard> createState() => _ScreenshotGuardState();
}

class _ScreenshotGuardState extends State<ScreenshotGuard> {
  final FlutterScreenshotDetect _detector = FlutterScreenshotDetect();
  final Box _box = Hive.box('settings');

  // Subscribing here rather than via startListening, which drops its own
  // subscription and so gives us no way to cancel it.
  StreamSubscription<FlutterScreenshotEvent>? _sub;

  // Detection can fire more than once for a single screenshot (observer plus
  // capture callback), so keep one dialog at a time.
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _sub = _detector.onScreenshot.listen(
      (_) => _onScreenshot(),
      // A platform channel failure must not take the app down with it.
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _detector.dispose();
    super.dispose();
  }

  void _onScreenshot() {
    if (_dialogOpen || !mounted) return;
    final disabled =
        _box.get('screenshotWarnDisabled', defaultValue: false) as bool;
    if (disabled) return;

    _dialogOpen = true;
    showDialog(
      context: context,
      builder: (ctx) => _ScreenshotWarningDialog(
        onNeverAgain: () {
          _box.put('screenshotWarnDisabled', true);
          Navigator.pop(ctx);
        },
      ),
    ).whenComplete(() => _dialogOpen = false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ScreenshotWarningDialog extends StatelessWidget {
  final VoidCallback onNeverAgain;
  const _ScreenshotWarningDialog({required this.onNeverAgain});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const points = <({IconData icon, String text})>[
      (
        icon: Icons.account_balance_wallet_rounded,
        text: 'It may show your balances, wallet names and notes.',
      ),
      (
        icon: Icons.photo_library_rounded,
        text: 'It is saved to your gallery, where other apps can read it.',
      ),
      (
        icon: Icons.cloud_upload_rounded,
        text: 'Photo backup can copy it to the cloud automatically.',
      ),
      (
        icon: Icons.share_rounded,
        text: 'Check what is on screen before you send it to anyone.',
      ),
    ];

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      title: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.privacy_tip_rounded,
                color: Colors.orange, size: 21),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text('Screenshot taken',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'That image holds your financial data.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ...points.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(p.icon,
                        size: 16,
                        color: theme.colorScheme.onSurface
                            .withOpacity(0.45)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(p.text,
                          style: const TextStyle(
                              fontSize: 12.5, height: 1.45)),
                    ),
                  ],
                ),
              )),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      actions: [
        TextButton(
          onPressed: onNeverAgain,
          child: Text('Don\'t show again',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}
