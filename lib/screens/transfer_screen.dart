import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/transfer_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transfer_model.dart';
import '../utils/app_utils.dart';
import '../widgets/calculator_sheet.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _fromWalletId;
  String? _toWalletId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wallets = context.read<WalletProvider>().wallets;
      if (wallets.length >= 2) {
        setState(() {
          _fromWalletId = wallets[0].id;
          _toWalletId = wallets[1].id;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _openCalculator() async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CalculatorSheet(
        initial: double.tryParse(_amountController.text) ?? 0,
      ),
    );
    if (result != null) {
      setState(
          () => _amountController.text = result.toStringAsFixed(2));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _swapWallets() {
    setState(() {
      final temp = _fromWalletId;
      _fromWalletId = _toWalletId;
      _toWalletId = temp;
    });
  }

  Future<void> _save() async {
    if (_fromWalletId == null || _toWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both wallets.')),
      );
      return;
    }

    if (_fromWalletId == _toWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('From and To wallets must be different.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    // Check if from wallet has enough
    final wallets = context.read<WalletProvider>();
    final fromWallet = wallets.getById(_fromWalletId!);
    final symbol = context.read<SettingsProvider>().currencySymbol;

    if (fromWallet != null && fromWallet.balance < amount) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFF9800), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Low Balance',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 17)),
            ),
          ]),
          content: Text(
            '${fromWallet.name} only has ${AppUtils.formatAmount(fromWallet.balance, symbol)}. '
            'You are transferring ${AppUtils.formatAmount(amount, symbol)}.\n\n'
            'The wallet balance will go negative.',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Transfer Anyway'),
            ),
          ],
        ),
      );
      if (shouldProceed != true) return;
    }

    final success = context.read<TransferProvider>().transfer(
          fromWalletId: _fromWalletId!,
          toWalletId: _toWalletId!,
          amount: amount,
          date: _date,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          id: AppUtils.generateId(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Transferred ${AppUtils.formatAmount(amount, symbol)} successfully!'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF2ECC71),
        ),
      );
      _amountController.clear();
      _noteController.clear();
      setState(() => _date = DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = context.watch<WalletProvider>().wallets;
    final transfers = context.watch<TransferProvider>().allTransfers;
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fromWallet = _fromWalletId != null
        ? wallets.firstWhere((w) => w.id == _fromWalletId,
            orElse: () => wallets.first)
        : null;
    final toWallet = _toWalletId != null
        ? wallets.firstWhere((w) => w.id == _toWalletId,
            orElse: () => wallets.last)
        : null;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Transfer',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Transfer card ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── From → To wallets ───────────────────────────────
                  Row(
                    children: [
                      // From wallet
                      Expanded(
                        child: _WalletSelector(
                          label: 'From',
                          selectedId: _fromWalletId,
                          wallets: wallets,
                          excludeId: _toWalletId,
                          symbol: symbol,
                          onChanged: (id) =>
                              setState(() => _fromWalletId = id),
                          isDark: isDark,
                          theme: theme,
                          color: const Color(0xFFE57373),
                        ),
                      ),

                      // Swap button
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: GestureDetector(
                          onTap: _swapWallets,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.swap_horiz_rounded,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      // To wallet
                      Expanded(
                        child: _WalletSelector(
                          label: 'To',
                          selectedId: _toWalletId,
                          wallets: wallets,
                          excludeId: _fromWalletId,
                          symbol: symbol,
                          onChanged: (id) =>
                              setState(() => _toWalletId = id),
                          isDark: isDark,
                          theme: theme,
                          color: const Color(0xFF2ECC71),
                        ),
                      ),
                    ],
                  ),

                  // Arrow indicator
                  if (fromWallet != null && toWallet != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          Text(fromWallet.name,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE57373))),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 16),
                          Text(toWallet.name,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2ECC71))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Amount ──────────────────────────────────────────
                  Text('Amount',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.6))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _openCalculator,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _amountController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Tap to enter amount',
                          prefixIcon:
                              const Icon(Icons.calculate_rounded),
                          suffixText: symbol,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Date ────────────────────────────────────────────
                  Text('Date',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.6))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(AppUtils.formatDate(_date),
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500)),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Note ────────────────────────────────────────────
                  Text('Note (Optional)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.6))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. ATM withdrawal',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Transfer button ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          wallets.length < 2 ? null : _save,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Transfer',
                          style:
                              TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),

                  if (wallets.length < 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'You need at least 2 wallets to transfer.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.4),
                        ),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // ── Transfer history ────────────────────────────────────────
            if (transfers.isNotEmpty) ...[
              Text('Transfer History',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              ...transfers.asMap().entries.map((entry) {
                final t = entry.value;
                final from = wallets.firstWhere(
                    (w) => w.id == t.fromWalletId,
                    orElse: () => wallets.first);
                final to = wallets.firstWhere(
                    (w) => w.id == t.toWalletId,
                    orElse: () => wallets.last);

                return _TransferTile(
                  transfer: t,
                  fromWallet: from,
                  toWallet: to,
                  symbol: symbol,
                  isDark: isDark,
                  theme: theme,
                )
                    .animate()
                    .fadeIn(delay: (entry.key * 50).ms)
                    .slideX(begin: 0.08);
              }),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Wallet Selector ───────────────────────────────────────────────────────────

class _WalletSelector extends StatelessWidget {
  final String label;
  final String? selectedId;
  final List<dynamic> wallets;
  final String? excludeId;
  final String symbol;
  final ValueChanged<String?> onChanged;
  final bool isDark;
  final ThemeData theme;
  final Color color;

  const _WalletSelector({
    required this.label,
    required this.selectedId,
    required this.wallets,
    required this.excludeId,
    required this.symbol,
    required this.onChanged,
    required this.isDark,
    required this.theme,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final available =
        wallets.where((w) => w.id != excludeId).toList();
    final selected = selectedId != null
        ? wallets.cast<dynamic>().where((w) => w.id == selectedId).isNotEmpty
            ? wallets.firstWhere((w) => w.id == selectedId)
            : null
        : null;

    return GestureDetector(
      onTap: () => _showPicker(context, available),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected != null
                  ? Color(selected.colorValue).withOpacity(0.1)
                  : (isDark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected != null
                    ? Color(selected.colorValue).withOpacity(0.4)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  selected != null
                      ? WalletProvider.resolveIcon(selected.type)
                      : Icons.account_balance_wallet_outlined,
                  color: selected != null
                      ? Color(selected.colorValue)
                      : theme.colorScheme.onSurface.withOpacity(0.3),
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  selected != null ? selected.name : 'Select',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected != null
                        ? Color(selected.colorValue)
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (selected != null)
                  Text(
                    AppUtils.formatAmount(selected.balance, symbol),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface
                          .withOpacity(0.45),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context, List available) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Select $label Wallet',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...available.map((wallet) {
              final walletColor = Color(wallet.colorValue);
              return GestureDetector(
                onTap: () {
                  onChanged(wallet.id);
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: wallet.id == selectedId
                          ? walletColor
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: walletColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                            WalletProvider.resolveIcon(wallet.type),
                            color: walletColor,
                            size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(wallet.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            Text(
                                AppUtils.formatAmount(
                                    wallet.balance, symbol),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: walletColor,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      if (wallet.id == selectedId)
                        Icon(Icons.check_circle_rounded,
                            color: walletColor, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Transfer History Tile ─────────────────────────────────────────────────────

class _TransferTile extends StatelessWidget {
  final TransferModel transfer;
  final dynamic fromWallet;
  final dynamic toWallet;
  final String symbol;
  final bool isDark;
  final ThemeData theme;

  const _TransferTile({
    required this.transfer,
    required this.fromWallet,
    required this.toWallet,
    required this.symbol,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(transfer.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Transfer?',
                style: TextStyle(fontWeight: FontWeight.w700)),
            content: const Text(
                'This will reverse the wallet balances. Are you sure?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) =>
          context.read<TransferProvider>().deleteTransfer(transfer.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded,
            color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            // From → To icon
            Stack(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Color(fromWallet.colorValue).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                      WalletProvider.resolveIcon(fromWallet.type),
                      color: Color(fromWallet.colorValue),
                      size: 22),
                ),
                Positioned(
                  bottom: -2, right: -2,
                  child: Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: Color(toWallet.colorValue),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          width: 1.5),
                    ),
                    child: Icon(
                        WalletProvider.resolveIcon(toWallet.type),
                        color: Colors.white,
                        size: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(fromWallet.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(fromWallet.colorValue))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 12),
                      ),
                      Text(toWallet.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(toWallet.colorValue))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(AppUtils.formatDate(transfer.date),
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.4))),
                  if (transfer.note != null &&
                      transfer.note!.isNotEmpty)
                    Text(transfer.note!,
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.4))),
                ],
              ),
            ),
            Text(
              AppUtils.formatAmount(transfer.amount, symbol),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
