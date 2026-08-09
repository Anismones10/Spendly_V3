part of '../add_expense_screen.dart';

// ── Multi-Wallet Split Dialog ─────────────────────────────────────────────────
class _MultiWalletSplitDialog extends StatefulWidget {
  final WalletModel? primaryWallet;
  final double primaryAmount;
  final List<({WalletModel wallet, double available})> otherWallets;
  final Map<String, double> preAssigned;
  final double totalNeeded;
  final String symbol;

  const _MultiWalletSplitDialog({
    required this.primaryWallet,
    required this.primaryAmount,
    required this.otherWallets,
    required this.preAssigned,
    required this.totalNeeded,
    required this.symbol,
  });

  @override
  State<_MultiWalletSplitDialog> createState() =>
      _MultiWalletSplitDialogState();
}

class _MultiWalletSplitDialogState extends State<_MultiWalletSplitDialog> {
  late Map<String, double> _selected;
  late double _primaryAmount;

  /// Set when a wallet was ticked while the total was already covered, so the
  /// dialog can say why nothing happened instead of adding a wallet that pays
  /// zero and silently drops out on save.
  bool _showNoRoomHint = false;

  @override
  void initState() {
    super.initState();
    _primaryAmount = widget.primaryAmount;
    _selected = Map.from(widget.preAssigned);
  }

  double get _coveredSoFar =>
      _primaryAmount + _selected.values.fold(0.0, (s, v) => s + v);

  double get _stillNeeded =>
      (widget.totalNeeded - _coveredSoFar).clamp(0, double.infinity);

  bool get _fullyFunded =>
      _coveredSoFar >= widget.totalNeeded - 0.001 &&
          _coveredSoFar <= widget.totalNeeded + 0.001;

  /// The most the primary wallet may take: whatever the expense still needs
  /// once the other wallets have taken their share, never more than it holds.
  ///
  /// Every row is capped this way, so the assigned amounts can never add up
  /// past the total. One wallet paying the whole amount leaves the others with
  /// nothing to give, rather than letting two wallets each cover it.
  double get _primaryCap =>
      (widget.totalNeeded - _selected.values.fold(0.0, (s, v) => s + v))
          .clamp(0.0, widget.primaryAmount);

  /// The same cap for one of the other wallets, ignoring what that wallet
  /// itself currently holds so editing its own field is not capped by it.
  double _capFor(String walletId, double available) {
    final elsewhere = _primaryAmount +
        _selected.entries
            .where((e) => e.key != walletId)
            .fold(0.0, (s, e) => s + e.value);
    return (widget.totalNeeded - elsewhere).clamp(0.0, available);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded,
              color: Color(0xFF4A90E2), size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text('Split Payment',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        ),
      ]),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total needed summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_fullyFunded
                      ? const Color(0xFF2ECC71)
                      : const Color(0xFFE57373))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_fullyFunded
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFE57373))
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.6))),
                    Text(
                      AppUtils.formatAmount(
                          widget.totalNeeded, widget.symbol),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Primary wallet — now editable so user can choose how much to use
              _WalletSplitRow(
                name: widget.primaryWallet?.name ?? 'Primary',
                icon: WalletProvider.resolveIcon(
                    widget.primaryWallet?.type ?? ''),
                available: widget.primaryAmount,
                assigned: _primaryAmount,
                symbol: widget.symbol,
                isFixed: false,
                isEnabled: true,
                maxAssignable: _primaryCap,
                onChanged: (val) {
                  setState(() {
                    _showNoRoomHint = false;
                    _primaryAmount = val.clamp(0.0, _primaryCap);
                  });
                },
              ),
              const SizedBox(height: 6),

              // Other wallets — toggleable and amount-editable
              ...widget.otherWallets.map((e) {
                final isUsed = _selected.containsKey(e.wallet.id);
                final assigned = _selected[e.wallet.id] ?? 0.0;
                final cap = _capFor(e.wallet.id, e.available);
                return _WalletSplitRow(
                  name: e.wallet.name,
                  icon: WalletProvider.resolveIcon(e.wallet.type),
                  available: e.available,
                  assigned: assigned,
                  symbol: widget.symbol,
                  isFixed: false,
                  isEnabled: isUsed,
                  maxAssignable: cap,
                  onToggle: () {
                    setState(() {
                      if (isUsed) {
                        _showNoRoomHint = false;
                        _selected.remove(e.wallet.id);
                        return;
                      }
                      final need = _stillNeeded;
                      // Ticking a wallet with nothing left to pay would show it
                      // as part of the split and then drop it on save, leaving
                      // an expense marked split but tagged with one wallet.
                      if (need <= 0.001) {
                        _showNoRoomHint = true;
                        return;
                      }
                      _showNoRoomHint = false;
                      _selected[e.wallet.id] =
                      need > e.available ? e.available : need;
                    });
                  },
                  onChanged: (val) {
                    setState(() {
                      _showNoRoomHint = false;
                      // Capped at this wallet's balance and at what the others
                      // have not already taken, so the split cannot exceed the
                      // total.
                      _selected[e.wallet.id] = val.clamp(0.0, cap);
                    });
                  },
                );
              }),

              const SizedBox(height: 10),

              if (_showNoRoomHint)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFFF9800), size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Lower the primary wallet’s amount first — the total is already covered',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFFFF9800)),
                      ),
                    ),
                  ]),
                ),
              if (!_fullyFunded)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE57373).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFE57373), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Still need ${AppUtils.formatAmount(_stillNeeded, widget.symbol)} more',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFE57373)),
                      ),
                    ),
                  ]),
                ),
              if (_fullyFunded)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF2ECC71), size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Fully covered!',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF2ECC71)),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _fullyFunded
              ? () {
            // A wallet assigned nothing is not part of the split — kept in, it
            // would save as a 0.00 expense and still tag the list entry.
            final result = <Map<String, dynamic>>[
              if (_primaryAmount > 0.001)
                {
                  'walletId': widget.primaryWallet?.id ?? '',
                  'amount': _primaryAmount,
                },
              ..._selected.entries
                  .where((e) => e.value > 0.001)
                  .map((e) =>
              {'walletId': e.key, 'amount': e.value}),
            ];
            Navigator.pop(context, result);
          }
              : null,
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2)),
          child: const Text('Split & Save'),
        ),
      ],
    );
  }
}

