import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/category_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/pdf_helper.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  // ── Section toggles ────────────────────────────────────────────────────────
  bool _includeExpenses = true;
  bool _includeIncome   = true;
  bool _includeLoans    = true;
  bool _includeGoals    = true;

  // ── Time filter ────────────────────────────────────────────────────────────
  String _selectedPeriod = 'this_month';
  DateTimeRange? _customRange;
  bool _isExporting = false;

  static const _periods = [
    {'key': 'this_month',   'label': 'This Month'},
    {'key': 'last_month',   'label': 'Last Month'},
    {'key': 'last_3months', 'label': 'Last 3 Months'},
    {'key': 'last_6months', 'label': 'Last 6 Months'},
    {'key': 'this_year',    'label': 'This Year'},
    {'key': 'all_time',     'label': 'All Time'},
    {'key': 'custom',       'label': 'Custom Range'},
  ];

  DateTimeRange _resolveRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'this_month':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case 'last_month':
        final first = DateTime(now.year, now.month - 1, 1);
        final last  = DateTime(now.year, now.month, 0);
        return DateTimeRange(start: first, end: last);
      case 'last_3months':
        return DateTimeRange(
          start: DateTime(now.year, now.month - 3, now.day),
          end: now,
        );
      case 'last_6months':
        return DateTimeRange(
          start: DateTime(now.year, now.month - 6, now.day),
          end: now,
        );
      case 'this_year':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      case 'custom':
        return _customRange ??
            DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            );
      case 'all_time':
      default:
        return DateTimeRange(
          start: DateTime(2000),
          end: now,
        );
    }
  }

  String _rangeLabel() {
    if (_selectedPeriod == 'custom' && _customRange != null) {
      return '${_fmt(_customRange!.start)} → ${_fmt(_customRange!.end)}';
    }
    return _periods
        .firstWhere((p) => p['key'] == _selectedPeriod)['label']!;
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedPeriod = 'custom';
      });
    }
  }

  Future<void> _export() async {
    if (!_includeExpenses &&
        !_includeIncome &&
        !_includeLoans &&
        !_includeGoals) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one section.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final expenses   = context.read<ExpenseProvider>().allExpenses;
      final income     = context.read<IncomeProvider>().allIncome;
      final loans      = context.read<LoanProvider>().allLoans;
      final goals      = context.read<GoalProvider>().goals;
      final cats       = context.read<CategoryProvider>().categories;
      final wallets    = context.read<WalletProvider>().wallets;
      final settings   = context.read<SettingsProvider>();
      final currency   = settings.currency; // pass CODE not symbol
      final catMap     = {for (final c in cats) c.id: c};
      final range      = _resolveRange();

      await PdfHelper.exportPdf(
        currency: currency,
        includeExpenses: _includeExpenses,
        includeIncome: _includeIncome,
        includeLoans: _includeLoans,
        includeGoals: _includeGoals,
        dateRange: range,
        dateLabel: _rangeLabel(),
        allExpenses: expenses,
        allIncome: income,
        allLoans: loans,
        allGoals: goals,
        categories: catMap,
        wallets: wallets,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Export PDF Report'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Preview banner ───────────────────────────────────────
            _PreviewBanner(
              includeExpenses: _includeExpenses,
              includeIncome:   _includeIncome,
              includeLoans:    _includeLoans,
              includeGoals:    _includeGoals,
              rangeLabel:      _rangeLabel(),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // ── Section: What to include ──────────────────────────────
            _sectionLabel('What to Include', theme),
            const SizedBox(height: 12),

            _SectionToggleCard(
              icon: Icons.receipt_long_rounded,
              label: 'Expenses',
              subtitle: 'Transactions, categories, charts',
              color: const Color(0xFFE57373),
              value: _includeExpenses,
              onChanged: (v) => setState(() => _includeExpenses = v),
              isDark: isDark,
              theme: theme,
            ).animate().fadeIn(delay: 80.ms).slideX(begin: -0.1),

            const SizedBox(height: 10),

            _SectionToggleCard(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Income',
              subtitle: 'Sources, trend, monthly breakdown',
              color: const Color(0xFF2ECC71),
              value: _includeIncome,
              onChanged: (v) => setState(() => _includeIncome = v),
              isDark: isDark,
              theme: theme,
            ).animate().fadeIn(delay: 120.ms).slideX(begin: -0.1),

            const SizedBox(height: 10),

            _SectionToggleCard(
              icon: Icons.handshake_rounded,
              label: 'Loans',
              subtitle: 'Lending, borrowing, repayment status',
              color: const Color(0xFFF39C12),
              value: _includeLoans,
              onChanged: (v) => setState(() => _includeLoans = v),
              isDark: isDark,
              theme: theme,
            ).animate().fadeIn(delay: 160.ms).slideX(begin: -0.1),

            const SizedBox(height: 10),

            _SectionToggleCard(
              icon: Icons.flag_rounded,
              label: 'Goals',
              subtitle: 'Progress bars, targets, deadlines',
              color: const Color(0xFF9C27B0),
              value: _includeGoals,
              onChanged: (v) => setState(() => _includeGoals = v),
              isDark: isDark,
              theme: theme,
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

            const SizedBox(height: 28),

            // ── Section: Time period ──────────────────────────────────
            _sectionLabel('Time Period', theme),
            const SizedBox(height: 12),

            // Period chips grid
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _periods.map((p) {
                final key      = p['key']!;
                final label    = p['label']!;
                final isCustom = key == 'custom';
                final selected = _selectedPeriod == key;

                return GestureDetector(
                  onTap: () async {
                    if (isCustom) {
                      await _pickCustomRange();
                    } else {
                      setState(() => _selectedPeriod = key);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCustom)
                          Icon(Icons.calendar_today_rounded,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : theme.colorScheme.primary),
                        if (isCustom) const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 240.ms),

            // Custom range display
            if (_selectedPeriod == 'custom' && _customRange != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range_rounded,
                        color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_fmt(_customRange!.start)}  →  ${_fmt(_customRange!.end)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickCustomRange,
                      child: Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── What's included info box ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: theme.colorScheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Your PDF will include',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._pdfFeatures.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 14,
                                color: const Color(0xFF2ECC71)),
                            const SizedBox(width: 8),
                            Text(f,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                )),
                          ],
                        ),
                      )),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),

      // ── Export button ────────────────────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: _isExporting ? null : _export,
            backgroundColor: _isExporting
                ? theme.colorScheme.primary.withOpacity(0.6)
                : theme.colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
            label: Text(
              _isExporting ? 'Generating PDF...' : 'Export PDF Report',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ).animate().slideY(begin: 0.5, delay: 400.ms),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, ThemeData theme) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: theme.colorScheme.primary,
      ),
    );
  }

  static const _pdfFeatures = [
    'Branded cover page with report details',
    'Financial summary with income vs expense chart',
    'Pie charts by category and income source',
    'Daily & monthly bar charts',
    'Complete transaction tables',
    'Loan progress bars and status',
    'Goal progress with visual bars',
    'Wallet balance overview',
    'Page numbers and export date',
  ];
}

// ── Preview Banner ────────────────────────────────────────────────────────────

class _PreviewBanner extends StatelessWidget {
  final bool includeExpenses;
  final bool includeIncome;
  final bool includeLoans;
  final bool includeGoals;
  final String rangeLabel;

  const _PreviewBanner({
    required this.includeExpenses,
    required this.includeIncome,
    required this.includeLoans,
    required this.includeGoals,
    required this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final sections = [
      if (includeExpenses) ('Expenses', const Color(0xFFE57373)),
      if (includeIncome)   ('Income',   const Color(0xFF2ECC71)),
      if (includeLoans)    ('Loans',    const Color(0xFFF39C12)),
      if (includeGoals)    ('Goals',    const Color(0xFF9C27B0)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A5F),
            const Color(0xFF1E3A5F).withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PDF Report Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      rangeLabel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sections.isEmpty)
            Text(
              'No sections selected',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sections.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: s.$2.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: s.$2.withOpacity(0.6), width: 1),
                  ),
                  child: Text(
                    s.$1,
                    style: TextStyle(
                      color: s.$2,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ── Section Toggle Card ───────────────────────────────────────────────────────

class _SectionToggleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final ThemeData theme;

  const _SectionToggleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.value,
    required this.onChanged,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value
              ? color.withOpacity(0.08)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? color : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: value
                    ? color.withOpacity(0.15)
                    : theme.colorScheme.onSurface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: value
                    ? color
                    : theme.colorScheme.onSurface.withOpacity(0.35),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: value
                          ? color
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? color : Colors.transparent,
                border: Border.all(
                  color: value
                      ? color
                      : theme.colorScheme.onSurface.withOpacity(0.25),
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
