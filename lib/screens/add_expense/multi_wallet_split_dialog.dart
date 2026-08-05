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
                onChanged: (val) {
                  setState(() {
                    _primaryAmount = val.clamp(0, widget.primaryAmount);
                  });
                },
              ),
              const SizedBox(height: 6),

              // Other wallets — toggleable and amount-editable
              ...widget.otherWallets.map((e) {
                final isUsed = _selected.containsKey(e.wallet.id);
                final assigned = _selected[e.wallet.id] ?? 0.0;
                return _WalletSplitRow(
                  name: e.wallet.name,
                  icon: WalletProvider.resolveIcon(e.wallet.type),
                  available: e.available,
                  assigned: assigned,
                  symbol: widget.symbol,
                  isFixed: false,
                  isEnabled: isUsed,
                  onToggle: () {
                    setState(() {
                      if (isUsed) {
                        _selected.remove(e.wallet.id);
                      } else {
                        final need = _stillNeeded;
                        _selected[e.wallet.id] =
                        need > e.available ? e.available : need;
                      }
                    });
                  },
                  onChanged: (val) {
                    setState(() {
                      // Cap at available AND at what's still needed from other wallets
                      final otherSelected = _selected.entries
                          .where((entry) => entry.key != e.wallet.id)
                          .fold(0.0, (s, entry) => s + entry.value);
                      final maxAllowed = (widget.totalNeeded -
                          _primaryAmount -
                          otherSelected)
                          .clamp(0.0, e.available);
                      _selected[e.wallet.id] = val.clamp(0, maxAllowed);
                    });
                  },
                );
              }),

              const SizedBox(height: 10),

              // Status indicator
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
                    Text(
                      _coveredSoFar > widget.totalNeeded + 0.001
                          ? 'Over by ${AppUtils.formatAmount(_coveredSoFar - widget.totalNeeded, widget.symbol)} — adjust amounts'
                          : 'Fully covered!',
                      style: TextStyle(
                          fontSize: 12,
                          color: _coveredSoFar > widget.totalNeeded + 0.001
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF2ECC71)),
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
            final result = <Map<String, dynamic>>[
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

