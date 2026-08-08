import 'package:flutter/material.dart';

/// Asks whether to throw away unsaved edits.
///
/// Shared by Add/Edit Expense and Add/Edit Income so the two never drift
/// apart. Returns true when the user chooses to discard.
Future<bool> confirmDiscardChanges(
  BuildContext context, {
  /// What is being abandoned — 'expense' or 'income'.
  required String label,

  /// True when editing something that already exists, which changes the
  /// stakes: edits are lost, but the original entry survives.
  bool isEditing = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => _DiscardChangesDialog(
      label: label,
      isEditing: isEditing,
    ),
  );
  return result ?? false;
}

class _DiscardChangesDialog extends StatelessWidget {
  final String label;
  final bool isEditing;

  const _DiscardChangesDialog({
    required this.label,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const accent = Color(0xFFEF6C00);

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_off_rounded,
                color: accent, size: 21),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text('Discard changes?',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: Text(
        isEditing
            ? 'Your edits to this $label have not been saved. Leaving now '
                'keeps the original as it was.'
            : 'This $label has not been saved yet. Leaving now loses what '
                'you typed.',
        style: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      actions: [
        // Discard sits left and quiet; Keep editing sits right, where a
        // right-handed thumb lands and where a stray tap costs nothing.
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Discard',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFFE57373))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2ECC71),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep editing',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
