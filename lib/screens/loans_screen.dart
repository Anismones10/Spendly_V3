import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/loan_model.dart';
import '../providers/loan_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_utils.dart';
import '../widgets/empty_state.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final netBalance = loans.netBalance;
    final isNetPositive = netBalance >= 0;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Loans',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // ── Net balance summary card ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isNetPositive
                      ? [const Color(0xFF1E3A5F), const Color(0xFF0F2440)]
                      : [const Color(0xFFB71C1C), const Color(0xFF7F0000)],
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
                            Row(
                              children: [
                                const Icon(Icons.arrow_upward_rounded,
                                    color: Color(0xFF2ECC71), size: 14),
                                const SizedBox(width: 4),
                                Text('Lending',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppUtils.formatAmount(loans.totalLending, symbol),
                              style: const TextStyle(
                                color: Color(0xFF2ECC71),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
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
                              Row(
                                children: [
                                  const Icon(Icons.arrow_downward_rounded,
                                      color: Color(0xFFE57373), size: 14),
                                  const SizedBox(width: 4),
                                  Text('Borrowing',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppUtils.formatAmount(
                                    loans.totalBorrowing, symbol),
                                style: const TextStyle(
                                  color: Color(0xFFE57373),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
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
                          Text(
                            'Net Balance',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            isNetPositive
                                ? 'Others owe you more'
                                : 'You owe others more',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
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
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          ),

          const SizedBox(height: 16),

          // ── Tab bar ─────────────────────────────────────────────────────────
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_upward_rounded, size: 16),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_downward_rounded, size: 16),
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

          // ── Loan lists ──────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _LoanList(loans: loans.lending, symbol: symbol, type: 'lending'),
                _LoanList(
                    loans: loans.borrowing,
                    symbol: symbol,
                    type: 'borrowing'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLoan(context, _tabController.index == 0
            ? 'lending'
            : 'borrowing'),
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

  const _LoanList({
    required this.loans,
    required this.symbol,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return EmptyState(
        icon: type == 'lending'
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded,
        title: type == 'lending' ? 'No Lending' : 'No Borrowing',
        subtitle: type == 'lending'
            ? 'Track money you lent to others'
            : 'Track money you borrowed from others',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: loans.length,
      itemBuilder: (ctx, i) => _LoanTile(
        loan: loans[i],
        symbol: symbol,
      )
          .animate()
          .fadeIn(delay: (i * 50).ms)
          .slideX(begin: 0.08),
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
                    color: const Color(0xFFE57373).withOpacity(0.4),
                    width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8)
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
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (loan.dueDate != null) ...[
                              Icon(Icons.calendar_today_rounded,
                                  size: 11,
                                  color: loan.isOverdue
                                      ? const Color(0xFFE57373)
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.4)),
                              const SizedBox(width: 3),
                              Text(
                                AppUtils.formatDate(loan.dueDate!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: loan.isOverdue
                                      ? const Color(0xFFE57373)
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.4),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (loan.note != null &&
                                loan.note!.isNotEmpty)
                              Expanded(
                                child: Text(
                                  loan.note!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
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

              // Progress bar if partial
              if (loan.status == 'partial' || loan.paidAmount > 0) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paid ${AppUtils.formatAmount(loan.paidAmount, symbol)} of ${AppUtils.formatAmount(loan.amount, symbol)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
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
              AppUtils.formatAmount(loan.remaining, symbol) + ' remaining',
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
                context.read<LoanProvider>().markPayment(
                    loan.id, loan.remaining);
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
                ctx
                    .read<LoanProvider>()
                    .markPayment(loan.id, amount);
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

    final loan = LoanModel(
      id: widget.existing?.id ?? AppUtils.generateId(),
      personName: name,
      amount: amount,
      paidAmount: widget.existing?.paidAmount ?? 0,
      date: _date,
      dueDate: _dueDate,
      type: widget.type,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      status: widget.existing?.status ?? 'pending',
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

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                        DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
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
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(Icons.close_rounded, size: 16),
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
                  child: Text(widget.existing != null ? 'Save' : 'Add'),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
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
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.45))),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          trailing ??
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.3)),
        ],
      ),
    );
  }
}
