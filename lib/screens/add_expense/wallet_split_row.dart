part of '../add_expense_screen.dart';

// ── Wallet Split Row ──────────────────────────────────────────────────────────
class _WalletSplitRow extends StatefulWidget {
  final String name;
  final IconData icon;
  final double available;
  final double assigned;
  final String symbol;
  final bool isFixed;
  final bool isEnabled;
  final VoidCallback? onToggle;
  final void Function(double)? onChanged;

  /// The most this row may be assigned — usually its own balance, but less when
  /// the split has only part of the total left to cover. Defaults to
  /// [available] for a row that answers to nothing but its own wallet.
  ///
  /// The dialog clamps again on its side, but the limit has to be known here
  /// too: the field only corrects itself when this row rejects the number, so a
  /// cap applied solely by the parent left the field showing an amount the
  /// split had already refused.
  final double? maxAssignable;

  const _WalletSplitRow({
    required this.name,
    required this.icon,
    required this.available,
    required this.assigned,
    required this.symbol,
    required this.isFixed,
    this.isEnabled = true,
    this.onToggle,
    this.onChanged,
    this.maxAssignable,
  });

  @override
  State<_WalletSplitRow> createState() => _WalletSplitRowState();
}

class _WalletSplitRowState extends State<_WalletSplitRow> {
  late TextEditingController _ctrl;
  late FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _focus = FocusNode();
    _setCtrlValue(widget.assigned);

    _focus.addListener(() {
      if (_focus.hasFocus) {
        // Clear on focus so user types a fresh number
        _ctrl.clear();
      } else {
        // Restore on blur if left empty
        if (_ctrl.text.trim().isEmpty) {
          _setCtrlValue(widget.assigned);
          widget.onChanged?.call(widget.assigned);
        }
      }
    });
  }

  void _setCtrlValue(double v) {
    _ctrl.value = TextEditingValue(
      text: v > 0 ? v.toStringAsFixed(2) : '',
      selection: TextSelection.collapsed(
          offset: v > 0 ? v.toStringAsFixed(2).length : 0),
    );
  }

  @override
  void didUpdateWidget(_WalletSplitRow old) {
    super.didUpdateWidget(old);
    if (old.assigned != widget.assigned && !_focus.hasFocus) {
      _setCtrlValue(widget.assigned);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isFixed || widget.isEnabled;
    // Nothing left for this wallet to pay: the box still answers a tap so the
    // dialog can say why, but it should not look like one simply waiting to be
    // ticked.
    final noRoom = !widget.isEnabled &&
        widget.maxAssignable != null &&
        widget.maxAssignable! <= 0.001;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF4A90E2).withOpacity(0.07)
            : Colors.grey.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? const Color(0xFF4A90E2).withOpacity(0.25)
              : Colors.grey.withOpacity(0.15),
        ),
      ),
      child: Row(children: [
        if (!widget.isFixed)
          GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: widget.isEnabled
                    ? const Color(0xFF4A90E2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.isEnabled
                      ? const Color(0xFF4A90E2)
                      : Colors.grey.withOpacity(noRoom ? 0.25 : 0.4),
                  width: 1.5,
                ),
              ),
              child: widget.isEnabled
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : noRoom
                      ? Icon(Icons.lock_outline_rounded,
                          size: 13, color: Colors.grey.withOpacity(0.6))
                      : null,
            ),
          ),
        Icon(widget.icon,
            size: 18,
            color: active
                ? const Color(0xFF4A90E2)
                : Colors.grey.withOpacity(0.4)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? null : Colors.grey.withOpacity(0.5))),
              Text(
                'Available: ${AppUtils.formatAmount(widget.available, widget.symbol)}',
                style: TextStyle(
                    fontSize: 11,
                    color: active
                        ? const Color(0xFF2ECC71)
                        : Colors.grey.withOpacity(0.4)),
              ),
            ],
          ),
        ),
        if (active)
          SizedBox(
            width: 90,
            child: widget.isFixed
                ? Text(
              AppUtils.formatAmount(widget.assigned, widget.symbol),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2ECC71)),
            )
                : TextField(
              controller: _ctrl,
              focusNode: _focus,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                prefixText: widget.symbol,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) {
                final val = double.tryParse(v) ?? 0;
                // Cap at available balance — can't use more than wallet has
                final availCap = val > widget.available
                    ? widget.available
                    : val;
                // And at what's still needed of the total, when the parent
                // told us a tighter limit than the balance
                final cap =
                    availCap > (widget.maxAssignable ?? availCap)
                        ? (widget.maxAssignable ?? availCap)
                        : availCap;
                if (cap != val) {
                  // Correct the field if over limit
                  _setCtrlValue(cap);
                }
                widget.onChanged?.call(cap);
              },
            ),
          ),
      ]),
    );
  }
}
