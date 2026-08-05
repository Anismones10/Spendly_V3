part of '../settings_screen.dart';

// ── Wallets Page ──────────────────────────────────────────────────────────────

class _WalletsPage extends StatelessWidget {
  const _WalletsPage();

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final wallets  = walletProvider.wallets;
    final settings = context.watch<SettingsProvider>();
    final symbol   = settings.currencySymbol;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final theme    = Theme.of(context);

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Wallets'),
        actions: [
          if (wallets.length >= 2)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Transfer',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TransferScreen())),
            ),
        ],
      ),
      body: wallets.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text('No wallets yet',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 16)),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // ── All Wallets Card Color ──────────────────────────────
          Consumer<SettingsProvider>(
            builder: (_, settings, __) {
              const palette = [
                Color(0xFF1E3A5F), Color(0xFF0F2440),
                Color(0xFF2196F3), Color(0xFF1565C0),
                Color(0xFF6A1B9A), Color(0xFF283593),
                Color(0xFF00695C), Color(0xFF37474F),
                Color(0xFF4A148C), Color(0xFF1B5E20),
                Color(0xFFB71C1C), Color(0xFFE65100),
              ];
              final current = settings.allWalletsColor;
              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: current.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.account_balance_wallet_rounded,
                            color: current, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text('All Wallets Card Color',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: palette.map((color) {
                        final isSelected = current.value == color.value;
                        return GestureDetector(
                          onTap: () => settings.setAllWalletsColor(color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 36 : 30,
                            height: isSelected ? 36 : 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                  color: theme.colorScheme.onSurface,
                                  width: 2.5)
                                  : null,
                              boxShadow: isSelected
                                  ? [BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8)]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 16, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Balance',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      Text(
                        AppUtils.formatAmount(
                            walletProvider.totalBalance, symbol),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 24,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                if (wallets.length >= 2)
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const TransferScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('Transfer',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ...wallets.map((wallet) => _WalletTile(
            wallet: wallet, symbol: symbol,
            onEdit: () =>
                _showWalletSheet(context, existing: wallet),
            onDelete: wallets.length > 1
                ? () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Row(children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red),
                    SizedBox(width: 10),
                    Text('Delete Wallet'),
                  ]),
                  content: Text(
                    'Are you sure you want to delete "${wallet.name}"?\n\n'
                        'All expense records linked to this wallet will still exist but will show no wallet.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red),
                      onPressed: () =>
                          Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                walletProvider.deleteWallet(wallet.id);
              }
            }
                : null,
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWalletSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Wallet'),
      ),
    );
  }

  void _showWalletSheet(BuildContext context, {WalletModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletSheet(existing: existing),
    );
  }
}

class _WalletTile extends StatelessWidget {
  final WalletModel wallet;
  final String symbol;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _WalletTile({
    required this.wallet, required this.symbol,
    required this.onEdit, this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = Color(wallet.colorValue);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(WalletProvider.resolveIcon(wallet.type),
                color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                Text(wallet.type.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11, color: color,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppUtils.formatAmount(wallet.balance, symbol),
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15,
                      color: color)),
              Text('balance',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4))),
            ],
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4)),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (onDelete != null) ...[
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.red),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletSheet extends StatefulWidget {
  final WalletModel? existing;
  const _WalletSheet({this.existing});

  @override
  State<_WalletSheet> createState() => _WalletSheetState();
}

class _WalletSheetState extends State<_WalletSheet> {
  final _nameCtrl = TextEditingController();
  String _selectedType = 'cash';
  late Color _selectedColor;

  static const List<Color> _palette = [
    Color(0xFF4CAF50), Color(0xFF1E3A5F), Color(0xFF2196F3),
    Color(0xFF9C27B0), Color(0xFFE57373), Color(0xFFFF9800),
    Color(0xFF00BCD4), Color(0xFFFF6B6B), Color(0xFF4ECDC4),
    Color(0xFFFFBE76), Color(0xFF6C63FF), Color(0xFFE91E63),
  ];

  final List<Map<String, dynamic>> _types = [
    {'type': 'cash',    'label': 'Cash',    'icon': Icons.payments_rounded},
    {'type': 'card',    'label': 'Card',    'icon': Icons.credit_card_rounded},
    {'type': 'bank',    'label': 'Bank',    'icon': Icons.account_balance_rounded},
    {'type': 'savings', 'label': 'Savings', 'icon': Icons.savings_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text  = widget.existing!.name;
      _selectedType   = widget.existing!.type;
      _selectedColor  = Color(widget.existing!.colorValue);
    } else {
      _selectedColor = Color(WalletProvider.colorForType(_selectedType));
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final provider = context.read<WalletProvider>();
    final balance  = widget.existing?.balance ?? 0;
    final wallet   = WalletModel(
      id: widget.existing?.id ?? AppUtils.generateId(),
      name: name, type: _selectedType, balance: balance,
      colorValue: _selectedColor.value, icon: _selectedType,
    );
    if (widget.existing != null) {
      provider.updateWallet(wallet);
    } else {
      provider.addWallet(wallet);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 20),
              Text(widget.existing != null ? 'Edit Wallet' : 'New Wallet',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Wallet name',
                  prefixIcon: Icon(Icons.label_rounded),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: _types.map((t) {
                  final isSelected = _selectedType == t['type'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedType  = t['type'] as String;
                        _selectedColor = Color(
                            WalletProvider.colorForType(_selectedType));
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withOpacity(0.15)
                              : (isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? _selectedColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(t['icon'] as IconData,
                                color: isSelected
                                    ? _selectedColor
                                    : theme.colorScheme.onSurface
                                    .withOpacity(0.35),
                                size: 20),
                            const SizedBox(height: 4),
                            Text(t['label'] as String,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? _selectedColor
                                        : theme.colorScheme.onSurface
                                        .withOpacity(0.4))),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Color',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: _palette.map((color) {
                  final isSelected = _selectedColor.value == color.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 10, spreadRadius: 2)]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.existing != null
                      ? 'Save Changes' : 'Add Wallet'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
