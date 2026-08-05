import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/loan_model.dart';
import '../providers/loan_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/app_utils.dart';
import '../utils/coach_mark_helper.dart';
import '../widgets/empty_state.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Coach mark keys
  final GlobalKey _lendingTabKey = GlobalKey();
  final GlobalKey _borrowingTabKey = GlobalKey();
  final GlobalKey _addButtonKey = GlobalKey();

  // ── Selection mode ────────────────────────────────────────────────────────
  final Set<String> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) _selectedIds.remove(id);
      else _selectedIds.add(id);
    });
  }

  void _clearSelection() => setState(() => _selectedIds.clear());

  void _selectAll(List<dynamic> all) {
    setState(() => _selectedIds.addAll(all.map((e) => e.id as String)));
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Selected'),
        content: Text('Delete $count loan${count == 1 ? '' : 's'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final provider = context.read<LoanProvider>();
      for (final id in _selectedIds.toList()) provider.deleteLoan(id);
      _clearSelection();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CoachMarkHelper.showLoans(
        context,
        lendingTabKey: _lendingTabKey,
        borrowingTabKey: _borrowingTabKey,
        addButtonKey: _addButtonKey,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loans = context.watch<LoanProvider>();
    final settings = context.watch<SettingsProvider>();
    final wallets = context.watch<WalletProvider>();
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final netBalance = loans.netBalance;
    final isNetPositive = netBalance >= 0;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: _isSelecting
          ? AppBar(
              backgroundColor:
                  isDark ? const Color(0xFF1E1E1E) : Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearSelection,
              ),
              title: Text('${_selectedIds.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              actions: [
                TextButton(
                  onPressed: () => _selectAll([...loans.lending, ...loans.borrowing]),
                  child: const Text('All'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () => _deleteSelected(context),
                ),
              ],
            )
          : AppBar(
              backgroundColor:
                  isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
              title: const Text('Loans',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
      body: Column(
        children: [
          // ── Net balance summary card ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isNetPositive
                      ? [const Color(0xFF1E3A5F), const Color(0xFF0F2440)]
                      : [
                          const Color(0xFFB71C1C),
                          const Color(0xFF7F0000)
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isNetPositive
                            ? const Color(0xFF1E3A5F)
                            : const Color(0xFFB71C1C))
                        .withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Lending vs Borrowing row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.arrow_upward_rounded,
                                  color: Color(0xFF2ECC71), size: 14),
                              const SizedBox(width: 4),
                              Text('Lending',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withOpacity(0.6),
                                      fontSize: 12)),
                            ]),
                            const SizedBox(height: 4),
                            Text(
                              AppUtils.formatAmount(
                                  loans.totalLending, symbol),
                              style: const TextStyle(
                                  color: Color(0xFF2ECC71),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.2)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.arrow_downward_rounded,
                                    color: Color(0xFFE57373), size: 14),
                                const SizedBox(width: 4),
                                Text('Borrowing',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withOpacity(0.6),
                                        fontSize: 12)),
                              ]),
                              const SizedBox(height: 4),
                              Text(
                                AppUtils.formatAmount(
                                    loans.totalBorrowing, symbol),
                                style: const TextStyle(
                                    color: Color(0xFFE57373),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 10),
                  // Net balance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Net Balance',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 12)),
                          Text(
                              isNetPositive
                                  ? 'Others owe you more'
                                  : 'You owe others more',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11)),
                        ],
                      ),
                      Text(
                        '${isNetPositive ? '+' : '-'}${AppUtils.formatAmount(netBalance.abs(), symbol)}',
                        style: TextStyle(
                          color: isNetPositive
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFFE57373),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  // ── Wallet net breakdown ────────────────────────────────
                  if (wallets.wallets.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 8),
                    ...wallets.wallets.map((wallet) {
                      // Net effect of loans on this wallet
                      final borrowed = loans.borrowing
                          .where((l) =>
                              l.walletId == wallet.id &&
                              l.status != 'paid')
                          .fold(0.0, (s, l) => s + l.remaining);
                      final lent = loans.lending
                          .where((l) =>
                              l.walletId == wallet.id &&
                              l.status != 'paid')
                          .fold(0.0, (s, l) => s + l.remaining);

                      if (borrowed == 0 && lent == 0) {
                        return const SizedBox.shrink();
                      }

                      final net = borrowed - lent;
                      final walletColor = Color(wallet.colorValue);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                                WalletProvider.resolveIcon(wallet.type),
                                color: walletColor,
                                size: 12),
                            const SizedBox(width: 6),
                            Text(
                              wallet.name,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.55)),
                            ),
                            const Spacer(),
                            if (borrowed > 0)
                              Text(
                                '+${AppUtils.formatAmount(borrowed, symbol)}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF81C784)),
                              ),
                            if (borrowed > 0 && lent > 0)
                              Text('  ',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withOpacity(0.3))),
                            if (lent > 0)
                              Text(
                                '-${AppUtils.formatAmount(lent, symbol)}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFEF9A9A)),
                              ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${net >= 0 ? '+' : ''}${AppUtils.formatAmount(net, symbol)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: net >= 0
                                      ? const Color(0xFF81C784)
                                      : const Color(0xFFEF9A9A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          ),

          const SizedBox(height: 16),

          // ── Tab bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor:
                    theme.colorScheme.onSurface.withOpacity(0.5),
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    key: _lendingTabKey,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_upward_rounded,
                            size: 16),
                        const SizedBox(width: 6),
                        const Text('Lending'),
                        if (loans.lending.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${loans.lending.length}',
                                style: const TextStyle(fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    key: _borrowingTabKey,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_downward_rounded,
                            size: 16),
                        const SizedBox(width: 6),
                        const Text('Borrowing'),
                        if (loans.borrowing.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${loans.borrowing.length}',
                                style: const TextStyle(fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Loan lists ────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _LoanList(
                    loans: loans.lending,
                    symbol: symbol,
                    type: 'lending',
                    selectedIds: _selectedIds,
                    isSelecting: _isSelecting,
                    onToggleSelect: _toggleSelection),
                _LoanList(
                    loans: loans.borrowing,
                    symbol: symbol,
                    type: 'borrowing',
                    selectedIds: _selectedIds,
                    isSelecting: _isSelecting,
                    onToggleSelect: _toggleSelection),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: _addButtonKey,
        onPressed: () => _showAddLoan(
            context,
            _tabController.index == 0 ? 'lending' : 'borrowing'),
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabController.index == 0
            ? 'Add Lending'
            : 'Add Borrowing'),
      ),
    );
  }

  void _showAddLoan(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoanSheet(type: type),
    );
  }
}

// ── Loan List ─────────────────────────────────────────────────────────────────

class _LoanList extends StatelessWidget {
  final List<LoanModel> loans;
  final String symbol;
  final String type;
  final Set<String> selectedIds;
  final bool isSelecting;
  final ValueChanged<String> onToggleSelect;

  const _LoanList({
    required this.loans,
    required this.symbol,
    required this.type,
    required this.selectedIds,
    required this.isSelecting,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return EmptyState(
        icon: type == 'lending'
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded,
        title:
            type == 'lending' ? 'No Lending' : 'No Borrowing',
        subtitle: type == 'lending'
            ? 'Track money you lent to others'
            : 'Track money you borrowed from others',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: loans.length,
      itemBuilder: (ctx, i) {
        final loan = loans[i];
        final isSelected = selectedIds.contains(loan.id);
        return GestureDetector(
          onLongPress: () => onToggleSelect(loan.id),
          onTap: isSelecting ? () => onToggleSelect(loan.id) : null,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF4A90E2), width: 2)
                      : null,
                  color: isSelected
                      ? const Color(0xFF4A90E2).withOpacity(0.07)
                      : Colors.transparent,
                ),
                child: _LoanTile(loan: loan, symbol: symbol),
              ),
              if (isSelected)
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    width: 22, height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A90E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.08);
      },
    );
  }
}

// ── Loan Tile ─────────────────────────────────────────────────────────────────

class _LoanTile extends StatelessWidget {
  final LoanModel loan;
  final String symbol;

  const _LoanTile({required this.loan, required this.symbol});

  Color get _statusColor {
    if (loan.status == 'paid') return const Color(0xFF2ECC71);
    if (loan.isOverdue) return const Color(0xFFE57373);
    if (loan.status == 'partial') return const Color(0xFFFF9800);
    return const Color(0xFF4A90E2);
  }

  String get _statusLabel {
    if (loan.status == 'paid') return 'Paid';
    if (loan.isOverdue) return 'Overdue';
    if (loan.status == 'partial') return 'Partial';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLending = loan.type == 'lending';
    final wallets = context.watch<WalletProvider>();
    final wallet =
        loan.walletId != null ? wallets.getById(loan.walletId!) : null;

    return Dismissible(
      key: ValueKey(loan.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Loan',
                style: TextStyle(fontWeight: FontWeight.w700)),
            content:
                Text('Delete loan for "${loan.personName}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) =>
          context.read<LoanProvider>().deleteLoan(loan.id),
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
      child: GestureDetector(
        onTap: () => _showOptions(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: loan.isOverdue
                ? Border.all(
                    color:
                        const Color(0xFFE57373).withOpacity(0.4),
                    width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8)
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: (isLending
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFFE57373))
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(
                        loan.personName.isNotEmpty
                            ? loan.personName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isLending
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFFE57373),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.personName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            // Wallet badge
                            if (wallet != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(wallet.colorValue)
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        WalletProvider.resolveIcon(
                                            wallet.type),
                                        size: 10,
                                        color: Color(
                                            wallet.colorValue)),
                                    const SizedBox(width: 3),
                                    Text(
                                      wallet.name,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            Color(wallet.colorValue),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (loan.dueDate != null)
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 11,
                                      color: loan.isOverdue
                                          ? const Color(0xFFE57373)
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.4)),
                                  const SizedBox(width: 3),
                                  Text(
                                    AppUtils.formatDate(
                                        loan.dueDate!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: loan.isOverdue
                                          ? const Color(0xFFE57373)
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (loan.note != null && loan.note!.isNotEmpty)
                          Text(
                            loan.note!,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Amount + status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppUtils.formatAmount(loan.remaining, symbol),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isLending
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFFE57373),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Progress bar
              if (loan.status == 'partial' || loan.paidAmount > 0) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paid ${AppUtils.formatAmount(loan.paidAmount, symbol)} of ${AppUtils.formatAmount(loan.amount, symbol)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface
                            .withOpacity(0.4),
                      ),
                    ),
                    Text(
                      '${(loan.progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: loan.progress,
                    minHeight: 6,
                    backgroundColor: _statusColor.withOpacity(0.12),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_statusColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    if (loan.status == 'paid') return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(loan.personName,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              AppUtils.formatAmount(loan.remaining,
                      context.read<SettingsProvider>().currencySymbol) +
                  ' remaining',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.payments_rounded,
                  color: Color(0xFF2ECC71)),
              title: const Text('Record Payment',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _showPayment(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) =>
                      _LoanSheet(type: loan.type, existing: loan),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF2ECC71)),
              title: const Text('Mark as Fully Paid',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                ctx
                    .read<LoanProvider>()
                    .markPayment(loan.id, loan.remaining);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red),
              title: const Text('Delete',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<LoanProvider>().deleteLoan(loan.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPayment(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Payment from ${loan.personName}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText:
                'Amount (max ${AppUtils.formatAmount(loan.remaining, "")})',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text);
              if (amount != null && amount > 0) {
                ctx.read<LoanProvider>().markPayment(loan.id, amount);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }
}

// ── Add / Edit Loan Sheet ─────────────────────────────────────────────────────

class _LoanSheet extends StatefulWidget {
  final String type;
  final LoanModel? existing;

  const _LoanSheet({required this.type, this.existing});

  @override
  State<_LoanSheet> createState() => _LoanSheetState();
}

class _LoanSheetState extends State<_LoanSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  String? _selectedWalletId;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final l = widget.existing!;
      _nameCtrl.text = l.personName;
      _amountCtrl.text = l.amount.toStringAsFixed(2);
      _noteCtrl.text = l.note ?? '';
      _date = l.date;
      _dueDate = l.dueDate;
      _selectedWalletId = l.walletId;
    } else {
      // Default to first wallet
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final wallets = context.read<WalletProvider>().wallets;
        if (wallets.isNotEmpty && _selectedWalletId == null) {
          setState(() => _selectedWalletId = wallets.first.id);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text);
    if (name.isEmpty || amount == null || amount <= 0) return;

    // Block lending if selected wallet doesn't have enough funds
    if (widget.type == 'lending' && _selectedWalletId != null) {
      final walletProvider = context.read<WalletProvider>();
      final expenses = context.read<ExpenseProvider>().allExpenses;
      final available = walletProvider.getRemaining(_selectedWalletId!, expenses);
      if (amount > available) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Text('⚠️', style: TextStyle(fontSize: 22)),
                SizedBox(width: 10),
                Text('Insufficient Funds',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              ],
            ),
            content: Text(
              'You only have ${context.read<SettingsProvider>().currencySymbol}${available.toStringAsFixed(2)} available in this wallet.\n\nYou cannot lend more than you have.',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    final loan = LoanModel(
      id: widget.existing?.id ?? AppUtils.generateId(),
      personName: name,
      amount: amount,
      paidAmount: widget.existing?.paidAmount ?? 0,
      date: _date,
      dueDate: _dueDate,
      type: widget.type,
      note: _noteCtrl.text.trim().isEmpty
          ? null
          : _noteCtrl.text.trim(),
      status: widget.existing?.status ?? 'pending',
      walletId: _selectedWalletId,
    );

    final provider = context.read<LoanProvider>();
    if (widget.existing != null) {
      provider.updateLoan(loan);
    } else {
      provider.addLoan(loan);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLending = widget.type == 'lending';
    final wallets = context.watch<WalletProvider>().wallets;
    final settings = context.read<SettingsProvider>();
    final symbol = settings.currencySymbol;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 20),

              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isLending
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFFE57373))
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isLending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: isLending
                          ? const Color(0xFF2ECC71)
                          : const Color(0xFFE57373),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.existing != null
                        ? 'Edit ${isLending ? 'Lending' : 'Borrowing'}'
                        : 'New ${isLending ? 'Lending' : 'Borrowing'}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Person name
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: isLending
                      ? 'Who did you lend to?'
                      : 'Who did you borrow from?',
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 12),

              // Amount
              TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 12),

              // Note
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'Note (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // ── Wallet picker ───────────────────────────────────────────
              Text(
                isLending
                    ? 'Pay From Wallet'
                    : 'Receive Into Wallet',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color:
                      theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isLending
                    ? 'Money will be deducted from this wallet'
                    : 'Money will be added to this wallet',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 10),

              if (wallets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded,
                        color: theme.colorScheme.primary, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                          'Add wallets in Settings → Wallets first.',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ]),
                )
              else
                Column(
                  children: [
                    // No wallet option
                    GestureDetector(
                      onTap: () =>
                          setState(() => _selectedWalletId = null),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: _selectedWalletId == null
                              ? theme.colorScheme.primary
                                  .withOpacity(0.1)
                              : (isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedWalletId == null
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(children: [
                          Icon(Icons.money_off_rounded,
                              color: _selectedWalletId == null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.4),
                              size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Just track (no wallet)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedWalletId == null
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                        ]),
                      ),
                    ),

                    // Wallet list
                    ...wallets.map((wallet) {
                      final isSelected =
                          _selectedWalletId == wallet.id;
                      final walletColor = Color(wallet.colorValue);

                      return GestureDetector(
                        onTap: () => setState(
                            () => _selectedWalletId = wallet.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? walletColor.withOpacity(0.12)
                                : (isDark
                                    ? const Color(0xFF2A2A2A)
                                    : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? walletColor
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: walletColor.withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Icon(
                                    WalletProvider.resolveIcon(
                                        wallet.type),
                                    color: walletColor,
                                    size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(wallet.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: isSelected
                                                ? walletColor
                                                : null)),
                                    Text(
                                      'Available: ${AppUtils.formatAmount(context.read<WalletProvider>().getRemaining(wallet.id, context.read<ExpenseProvider>().allExpenses), symbol)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected
                                            ? walletColor
                                                .withOpacity(0.7)
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Effect indicator
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isLending
                                          ? const Color(0xFFE57373)
                                          : const Color(0xFF2ECC71))
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isLending
                                          ? Icons.arrow_upward_rounded
                                          : Icons
                                              .arrow_downward_rounded,
                                      size: 11,
                                      color: isLending
                                          ? const Color(0xFFE57373)
                                          : const Color(0xFF2ECC71),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      isLending ? 'Out' : 'In',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isLending
                                            ? const Color(0xFFE57373)
                                            : const Color(0xFF2ECC71),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),

              const SizedBox(height: 12),

              // Date
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: _DateTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: AppUtils.formatDate(_date),
                  isDark: isDark,
                  theme: theme,
                ),
              ),
              const SizedBox(height: 10),

              // Due date
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ??
                        DateTime.now()
                            .add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null)
                    setState(() => _dueDate = picked);
                },
                child: _DateTile(
                  icon: Icons.alarm_rounded,
                  label: 'Due date (optional)',
                  value: _dueDate != null
                      ? AppUtils.formatDate(_dueDate!)
                      : 'Tap to set',
                  isDark: isDark,
                  theme: theme,
                  trailing: _dueDate != null
                      ? GestureDetector(
                          onTap: () =>
                              setState(() => _dueDate = null),
                          child: const Icon(Icons.close_rounded,
                              size: 16),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLending
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFE57373),
                  ),
                  child: Text(
                      widget.existing != null ? 'Save' : 'Add'),
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

// ── Date tile ─────────────────────────────────────────────────────────────────

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final ThemeData theme;
  final Widget? trailing;

  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.theme,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface
                            .withOpacity(0.45))),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          trailing ??
              Icon(Icons.chevron_right_rounded,
                  color:
                      theme.colorScheme.onSurface.withOpacity(0.3)),
        ],
      ),
    );
  }
}
