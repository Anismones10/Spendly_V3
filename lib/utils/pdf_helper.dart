import 'dart:math' as math;
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/loan_model.dart';
import '../models/goal_model.dart';
import '../models/category_model.dart';
import '../models/wallet_model.dart';

class PdfHelper {
  // ── Colors ─────────────────────────────────────────────────────────────────
  static final _navy     = PdfColor.fromHex('#1E3A5F');
  static final _navyDark = PdfColor.fromHex('#0F2440');
  static final _green    = PdfColor.fromHex('#2ECC71');
  static final _red      = PdfColor.fromHex('#E57373');
  static final _amber    = PdfColor.fromHex('#F39C12');
  static final _blue     = PdfColor.fromHex('#4A90E2');
  static final _purple   = PdfColor.fromHex('#9C27B0');
  static final _grey     = PdfColor.fromHex('#78909C');
  static final _light    = PdfColor.fromHex('#F0F4F8');
  static final _white    = PdfColors.white;
  // FIX 2: proper visible track color for bar charts
  static final _trackGrey = PdfColor.fromHex('#CFD8DC'); // blue-grey, matches app track

  static final _catColors = [
    PdfColor.fromHex('#E57373'),
    PdfColor.fromHex('#4A90E2'),
    PdfColor.fromHex('#2ECC71'),
    PdfColor.fromHex('#FF9800'),
    PdfColor.fromHex('#9C27B0'),
    PdfColor.fromHex('#26A69A'),
    PdfColor.fromHex('#F39C12'),
    PdfColor.fromHex('#78909C'),
    PdfColor.fromHex('#E91E63'),
    PdfColor.fromHex('#00BCD4'),
  ];

  // ── Safe currency symbol resolver ─────────────────────────────────────────
  static String _sym(String code) {
    const map = {
      'USD': 'USD ', 'CAD': 'CAD ', 'AUD': 'AUD ', 'BRL': 'BRL ',
      'MXN': 'MXN ', 'EUR': 'EUR ', 'GBP': 'GBP ', 'CHF': 'CHF ',
      'RUB': 'RUB ', 'TRY': 'TRY ', 'SEK': 'SEK ', 'NOK': 'NOK ',
      'AED': 'AED ', 'SAR': 'SAR ', 'IRR': 'IRR ', 'AFN': 'AFN ',
      'IQD': 'IQD ', 'KWD': 'KWD ', 'QAR': 'QAR ', 'JPY': 'JPY ',
      'CNY': 'CNY ', 'KRW': 'KRW ', 'INR': 'INR ', 'PKR': 'PKR ',
      'BDT': 'BDT ', 'THB': 'THB ', 'VND': 'VND ', 'SGD': 'SGD ',
      'HKD': 'HKD ',
    };
    return map[code] ?? (code + ' ');
  }

  static String _fmt(double amount, String sym) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    String numStr;
    if (abs >= 1000000) {
      numStr = (abs / 1000000).toStringAsFixed(2) + 'M';
    } else {
      final fixed = abs.toStringAsFixed(2);
      final parts = fixed.split('.');
      final buf = StringBuffer();
      final intDigits = parts[0];
      for (int i = 0; i < intDigits.length; i++) {
        if (i > 0 && (intDigits.length - i) % 3 == 0) buf.write(',');
        buf.write(intDigits[i]);
      }
      numStr = buf.toString() + '.' + parts[1];
    }
    return sign + sym + numStr;
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String _fmtDate(DateTime d) =>
      _pad(d.day) + '/' + _pad(d.month) + '/' + d.year.toString();

  static String _shortMonth(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  static bool _inRange(DateTime date, DateTimeRange range) =>
      !date.isBefore(range.start) &&
          date.isBefore(range.end.add(const Duration(days: 1)));

  static PdfColor _pdfColorFromInt(int v) => PdfColor(
    ((v >> 16) & 0xFF) / 255.0,
    ((v >> 8)  & 0xFF) / 255.0,
    (v         & 0xFF) / 255.0,
  );

  // ── Main export ────────────────────────────────────────────────────────────
  static Future<void> exportPdf({
    required String currency,
    required bool includeExpenses,
    required bool includeIncome,
    required bool includeLoans,
    required bool includeGoals,
    required DateTimeRange dateRange,
    required String dateLabel,
    required List<ExpenseModel> allExpenses,
    required List<IncomeModel> allIncome,
    required List<LoanModel> allLoans,
    required List<GoalModel> allGoals,
    required Map<String, CategoryModel> categories,
    required List<WalletModel> wallets,
  }) async {
    final expenses = includeExpenses
        ? allExpenses.where((e) => _inRange(e.date, dateRange)).toList()
        : <ExpenseModel>[];
    final income = includeIncome
        ? allIncome.where((e) => _inRange(e.date, dateRange)).toList()
        : <IncomeModel>[];
    final loans = includeLoans ? allLoans : <LoanModel>[];
    final goals = includeGoals ? allGoals : <GoalModel>[];

    final sym = _sym(currency);
    final doc = pw.Document();
    final now = DateTime.now();

    final totalExp = expenses.fold(0.0, (s, e) => s + e.amount);
    final totalInc = income.fold(0.0,   (s, e) => s + e.amount);
    final net      = totalInc - totalExp;
    final savRate  = totalInc > 0
        ? ((net / totalInc) * 100).clamp(0.0, 100.0) : 0.0;

    // Cover
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => _cover(
        now: now, dateLabel: dateLabel, sym: sym,
        sections: [
          if (includeExpenses) 'Expenses',
          if (includeIncome)   'Income',
          if (includeLoans)    'Loans',
          if (includeGoals)    'Goals',
        ],
      ),
    ));

    // Summary
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => _summary(
        totalExp: totalExp, totalInc: totalInc, net: net,
        savRate: savRate, sym: sym, expenses: expenses,
        income: income, categories: categories,
        wallets: wallets, dateLabel: dateLabel,
      ),
    ));

    if (includeExpenses && expenses.isNotEmpty) {
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _secHeader('Expenses', _navy),
        footer: (ctx) => _footer(ctx, now),
        build: (_) => _expensesSection(
          expenses: expenses, categories: categories,
          wallets: wallets, sym: sym,
        ),
      ));
    }

    if (includeIncome && income.isNotEmpty) {
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _secHeader('Income', _green),
        footer: (ctx) => _footer(ctx, now),
        build: (_) => _incomeSection(
          income: income, wallets: wallets, sym: sym,
        ),
      ));
    }

    if (includeLoans && loans.isNotEmpty) {
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _secHeader('Loans', _amber),
        footer: (ctx) => _footer(ctx, now),
        build: (_) => _loansSection(loans: loans, sym: currency),
      ));
    }

    if (includeGoals && goals.isNotEmpty) {
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _secHeader('Savings Goals', _purple),
        footer: (ctx) => _footer(ctx, now),
        build: (_) => _goalsSection(goals: goals, sym: currency),
      ));
    }

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'Spendly_Report_' + now.year.toString() +
          _pad(now.month) + _pad(now.day) + '.pdf',
    );
  }

  // ── Cover ──────────────────────────────────────────────────────────────────
  static pw.Widget _cover({
    required DateTime now,
    required String dateLabel,
    required String sym,
    required List<String> sections,
  }) {
    return pw.Stack(children: [
      pw.Positioned.fill(child: pw.Container(
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [_navyDark, _navy],
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
          ),
        ),
      )),
      pw.Positioned(top: -60, right: -60, child: pw.Container(
        width: 240, height: 240,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          color: PdfColors.white.shade(0.93),
        ),
      )),
      pw.Positioned(bottom: -80, left: -80, child: pw.Container(
        width: 300, height: 300,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          color: PdfColors.white.shade(0.95),
        ),
      )),
      pw.Padding(
        padding: const pw.EdgeInsets.all(60),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 60),
            pw.Container(
              width: 80, height: 80,
              decoration: pw.BoxDecoration(
                color: _white,
                borderRadius: pw.BorderRadius.circular(20),
              ),
              child: pw.Center(child: pw.Text(
                'S',
                style: pw.TextStyle(
                    fontSize: 48, fontWeight: pw.FontWeight.bold, color: _navy),
              )),
            ),
            pw.SizedBox(height: 30),
            pw.Text('Spendly',
                style: pw.TextStyle(
                    fontSize: 52, fontWeight: pw.FontWeight.bold, color: _white)),
            pw.Text('Financial Report',
                style: pw.TextStyle(fontSize: 24, color: _white)),
            pw.SizedBox(height: 60),
            pw.Container(height: 1, color: PdfColors.white),
            pw.SizedBox(height: 30),
            _cRow('Period:',    dateLabel),
            pw.SizedBox(height: 12),
            _cRow('Generated:', _fmtDate(now)),
            pw.SizedBox(height: 12),
            _cRow('Currency:', sym),
            pw.SizedBox(height: 12),
            _cRow('Sections:', sections.join(' - ')),
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(20),
              ),
              child: pw.Text('Track. Save. Grow.',
                  style: pw.TextStyle(
                      fontSize: 13, color: _navy, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      ),
    ]);
  }

  static pw.Widget _cRow(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(children: [
        pw.TextSpan(
          text: label + ' ',
          style: pw.TextStyle(
              fontSize: 14, color: PdfColors.white,
              fontWeight: pw.FontWeight.normal),
        ),
        pw.TextSpan(
          text: value,
          style: pw.TextStyle(
              fontSize: 14, color: _white, fontWeight: pw.FontWeight.bold),
        ),
      ]),
    );
  }

  // ── Summary ────────────────────────────────────────────────────────────────
  static pw.Widget _summary({
    required double totalExp,
    required double totalInc,
    required double net,
    required double savRate,
    required String sym,
    required List<ExpenseModel> expenses,
    required List<IncomeModel> income,
    required Map<String, CategoryModel> categories,
    required List<WalletModel> wallets,
    required String dateLabel,
  }) {
    final catTotals = <String, double>{};
    for (final e in expenses) {
      catTotals[e.categoryId] = (catTotals[e.categoryId] ?? 0) + e.amount;
    }
    final catEntries = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final srcTotals = <String, double>{};
    for (final i in income) {
      srcTotals[i.source] = (srcTotals[i.source] ?? 0) + i.amount;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [_navy, _blue],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
            borderRadius: pw.BorderRadius.circular(14),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Financial Summary',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold, color: _white)),
              pw.SizedBox(height: 4),
              pw.Text(dateLabel,
                  style: pw.TextStyle(fontSize: 12, color: _white)),
            ],
          ),
        ),
        pw.SizedBox(height: 18),

        pw.Row(children: [
          pw.Expanded(child: _card('Total Income',   _fmt(totalInc, sym), _green)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _card('Total Expenses', _fmt(totalExp, sym), _red)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _card('Net Balance',    _fmt(net, sym),
              net >= 0 ? _green : _red)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _card('Savings Rate',
              savRate.toStringAsFixed(1) + '%',
              savRate >= 20 ? _green : savRate >= 10 ? _amber : _red)),
        ]),
        pw.SizedBox(height: 20),

        if (totalInc > 0 || totalExp > 0) ...[
          _title('Income vs Expenses'),
          pw.SizedBox(height: 10),
          _hBar('Income',   totalInc, math.max(totalInc, totalExp), _green, sym),
          pw.SizedBox(height: 6),
          _hBar('Expenses', totalExp, math.max(totalInc, totalExp), _red,   sym),
          pw.SizedBox(height: 20),
        ],

        if (catEntries.isNotEmpty || srcTotals.isNotEmpty)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (catEntries.isNotEmpty)
                pw.Expanded(child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _title('By Category'),
                    pw.SizedBox(height: 8),
                    _donutWithLegend(
                      slices: _toSlices(catEntries, categories),
                      total: totalExp, sym: sym, size: 90,
                    ),
                  ],
                )),
              if (catEntries.isNotEmpty && srcTotals.isNotEmpty)
                pw.SizedBox(width: 16),
              if (srcTotals.isNotEmpty)
                pw.Expanded(child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _title('By Source'),
                    pw.SizedBox(height: 8),
                    _donutWithLegend(
                      slices: _srcSlices(srcTotals),
                      total: totalInc, sym: sym, size: 90,
                    ),
                  ],
                )),
            ],
          ),

        pw.SizedBox(height: 20),

        if (wallets.isNotEmpty) ...[
          _title('Wallet Balances'),
          pw.SizedBox(height: 8),
          _wallets(wallets, sym),
        ],
      ],
    );
  }

  // ── Expenses section ───────────────────────────────────────────────────────
  static List<pw.Widget> _expensesSection({
    required List<ExpenseModel> expenses,
    required Map<String, CategoryModel> categories,
    required List<WalletModel> wallets,
    required String sym,
  }) {
    final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
    final catTotals = <String, double>{};
    for (final e in expenses) {
      catTotals[e.categoryId] = (catTotals[e.categoryId] ?? 0) + e.amount;
    }
    final catEntries = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = expenses.fold(0.0, (s, e) => s + e.amount);

    // Build spending map keyed by day number
    final dailyMap = <int, double>{};
    for (final e in expenses) {
      dailyMap[e.date.day] = (dailyMap[e.date.day] ?? 0) + e.amount;
    }

    // Use the month from expenses dates (fallback to current month)
    final refDate = expenses.isNotEmpty ? expenses.first.date : DateTime.now();
    final daysInMonth = DateTime(refDate.year, refDate.month + 1, 0).day;

    // ALL days 1..daysInMonth — days with no spending get 0.0 (grey bar)
    final allDailyEntries = List.generate(daysInMonth, (i) {
      final day = i + 1;
      return MapEntry(day.toString(), dailyMap[day] ?? 0.0);
    });

    return [
      if (catEntries.isNotEmpty) ...[
        _title('Expenses by Category'),
        pw.SizedBox(height: 10),
        _donutWithLegend(
          slices: _toSlices(catEntries, categories),
          total: total, sym: sym, size: 120,
        ),
        pw.SizedBox(height: 20),
      ],

      if (allDailyEntries.isNotEmpty) ...[
        _title('Daily Spending'),
        pw.SizedBox(height: 10),
        _barChart(
          entries: allDailyEntries,
          color: _navy,
          sym: sym,
        ),
        pw.SizedBox(height: 20),
      ],

      if (catEntries.isNotEmpty) ...[
        _title('Category Breakdown'),
        pw.SizedBox(height: 8),
        _catTable(catEntries, categories, total, sym),
        pw.SizedBox(height: 20),
      ],

      _title('All Transactions (' + sorted.length.toString() + ')'),
      pw.SizedBox(height: 8),
      _expTable(sorted, categories, wallets, sym),
    ];
  }

  // ── Income section ─────────────────────────────────────────────────────────
  static List<pw.Widget> _incomeSection({
    required List<IncomeModel> income,
    required List<WalletModel> wallets,
    required String sym,
  }) {
    final sorted = [...income]..sort((a, b) => b.date.compareTo(a.date));
    final total  = income.fold(0.0, (s, e) => s + e.amount);

    final srcTotals = <String, double>{};
    for (final i in income) {
      srcTotals[i.source] = (srcTotals[i.source] ?? 0) + i.amount;
    }

    final monthMap = <String, double>{};
    for (final i in income) {
      final key = _shortMonth(i.date.month) + ' ' + i.date.year.toString();
      monthMap[key] = (monthMap[key] ?? 0) + i.amount;
    }

    return [
      if (srcTotals.isNotEmpty) ...[
        _title('Income by Source'),
        pw.SizedBox(height: 10),
        _donutWithLegend(
          slices: _srcSlices(srcTotals),
          total: total, sym: sym, size: 120,
        ),
        pw.SizedBox(height: 20),
      ],

      if (monthMap.length > 1) ...[
        _title('Monthly Income Trend'),
        pw.SizedBox(height: 10),
        _barChart(
          entries: monthMap.entries.toList(),
          color: _green, sym: sym,
        ),
        pw.SizedBox(height: 20),
      ],

      _title('All Income (' + sorted.length.toString() + ')'),
      pw.SizedBox(height: 8),
      _incTable(sorted, wallets, sym),
    ];
  }

  // ── Loans section ──────────────────────────────────────────────────────────
  static List<pw.Widget> _loansSection({
    required List<LoanModel> loans,
    required String sym,
  }) {
    final lending   = loans.where((l) => l.type == 'lending').toList();
    final borrowing = loans.where((l) => l.type == 'borrowing').toList();
    final totLend = lending.where((l) => l.status != 'paid')
        .fold(0.0, (s, l) => s + l.remaining);
    final totBorrow = borrowing.where((l) => l.status != 'paid')
        .fold(0.0, (s, l) => s + l.remaining);

    final statusCounts = <String, int>{};
    for (final l in loans) {
      statusCounts[l.status] = (statusCounts[l.status] ?? 0) + 1;
    }

    return [
      pw.Row(children: [
        pw.Expanded(child: _card('Total Lending',   _fmt(totLend,   sym), _green)),
        pw.SizedBox(width: 8),
        pw.Expanded(child: _card('Total Borrowing', _fmt(totBorrow, sym), _red)),
        pw.SizedBox(width: 8),
        pw.Expanded(child: _card('Net Position',
            _fmt(totLend - totBorrow, sym),
            totLend >= totBorrow ? _green : _red)),
      ]),
      pw.SizedBox(height: 16),

      _title('Lending vs Borrowing'),
      pw.SizedBox(height: 8),
      _hBar('Lending',   totLend,   math.max(totLend, totBorrow), _green, sym),
      pw.SizedBox(height: 6),
      _hBar('Borrowing', totBorrow, math.max(totLend, totBorrow), _red,   sym),
      pw.SizedBox(height: 16),

      _title('Loan Status Overview'),
      pw.SizedBox(height: 8),
      _statusCards(statusCounts, loans.length),
      pw.SizedBox(height: 16),

      if (lending.isNotEmpty) ...[
        _title('Lending (' + lending.length.toString() + ')'),
        pw.SizedBox(height: 6),
        _loanTable(lending, sym),
        pw.SizedBox(height: 16),
      ],
      if (borrowing.isNotEmpty) ...[
        _title('Borrowing (' + borrowing.length.toString() + ')'),
        pw.SizedBox(height: 6),
        _loanTable(borrowing, sym),
      ],
    ];
  }

  // ── Goals section ──────────────────────────────────────────────────────────
  static List<pw.Widget> _goalsSection({
    required List<GoalModel> goals,
    required String sym,
  }) {
    final active    = goals.where((g) => !g.isCompleted).toList();
    final completed = goals.where((g) => g.isCompleted).toList();
    final totTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
    final totSaved  = goals.fold(0.0, (s, g) => s + g.savedAmount);
    final pctAll    = totTarget > 0 ? totSaved / totTarget : 0.0;

    return [
      pw.Row(children: [
        pw.Expanded(child: _card('Total Goals',      goals.length.toString(),     _purple)),
        pw.SizedBox(width: 8),
        pw.Expanded(child: _card('Completed',        completed.length.toString(), _green)),
        pw.SizedBox(width: 8),
        pw.Expanded(child: _card('In Progress',      active.length.toString(),    _blue)),
        pw.SizedBox(width: 8),
        pw.Expanded(child: _card('Overall Progress',
            (pctAll * 100).toStringAsFixed(1) + '%',
            pctAll >= 0.75 ? _green : pctAll >= 0.5 ? _amber : _blue)),
      ]),
      pw.SizedBox(height: 16),

      _title('Goals Progress Overview'),
      pw.SizedBox(height: 8),
      ...goals.map((g) => _goalProgressRow(g, sym)),

      pw.SizedBox(height: 16),
      _title('Goal Details'),
      pw.SizedBox(height: 8),
      ...goals.map((g) => _goalCard(g, sym)),
    ];
  }

  // ── Donut with legend ──────────────────────────────────────────────────────
  static pw.Widget _donutWithLegend({
    required List<_Slice> slices,
    required double total,
    required String sym,
    required double size,
  }) {
    if (total <= 0 || slices.isEmpty) {
      return pw.Text('No data', style: pw.TextStyle(color: _grey, fontSize: 10));
    }
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: size, height: size,
          child: pw.CustomPaint(painter: (canvas, s) =>
              _drawDonut(canvas, s, slices, total)),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: slices.take(8).map((s) {
              final pct = (s.value / total * 100).toStringAsFixed(1);
              final label = s.label.isNotEmpty
                  ? s.label[0].toUpperCase() + s.label.substring(1)
                  : s.label;
              final amtStr = _fmt(s.value, sym);
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(children: [
                  pw.Container(
                    width: 8, height: 8,
                    decoration: pw.BoxDecoration(
                        color: s.color, shape: pw.BoxShape.circle),
                  ),
                  pw.SizedBox(width: 5),
                  pw.Expanded(
                    child: pw.Text(label,
                        style: const pw.TextStyle(fontSize: 8)),
                  ),
                  pw.Text(pct + '%',
                      style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: s.color)),
                  pw.SizedBox(width: 4),
                  pw.Text(amtStr,
                      style: pw.TextStyle(fontSize: 7, color: _grey)),
                ]),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  static void _drawDonut(PdfGraphics canvas, PdfPoint size,
      List<_Slice> slices, double total) {
    if (total == 0) return;
    final cx    = size.x / 2;
    final cy    = size.y / 2;
    final r     = math.min(cx, cy) - 2;
    final inner = r * 0.42;
    const steps = 72;

    double startAngle = -math.pi / 2;

    for (final s in slices) {
      if (s.value <= 0) continue;
      final sweep    = (s.value / total) * math.pi * 2;
      final numSteps = math.max(3, (steps * sweep / (math.pi * 2)).ceil());
      final step     = sweep / numSteps;

      canvas.setFillColor(s.color);

      final ox0 = cx + r * math.cos(startAngle);
      final oy0 = cy + r * math.sin(startAngle);
      canvas.moveTo(ox0, oy0);

      for (int i = 1; i <= numSteps; i++) {
        final a = startAngle + i * step;
        canvas.lineTo(cx + r * math.cos(a), cy + r * math.sin(a));
      }

      final endAngle = startAngle + sweep;
      canvas.lineTo(
        cx + inner * math.cos(endAngle),
        cy + inner * math.sin(endAngle),
      );

      for (int i = numSteps - 1; i >= 0; i--) {
        final a = startAngle + i * step;
        canvas.lineTo(cx + inner * math.cos(a), cy + inner * math.sin(a));
      }

      canvas.lineTo(ox0, oy0);
      canvas
        ..closePath()
        ..fillPath();

      startAngle += sweep;
    }
  }

  // ── Bar chart ──────────────────────────────────────────────────────────────
  // A4 page is 595pt wide. With 40pt margins on each side = 515pt content width.
  // pw.CustomPaint requires explicit width/height — without them size.x == 0.
  static const double _chartWidth = 515.0;

  // Y-axis label column width
  static const double _yAxisW   = 44.0;
  // Chart area width = full content width minus Y-axis column
  static const double _barAreaW = _chartWidth - _yAxisW;

  static pw.Widget _barChart({
    required List<MapEntry<String, double>> entries,
    required PdfColor color,
    required String sym,
  }) {
    if (entries.isEmpty || entries.every((e) => e.value == 0)) {
      return pw.Text('No data to display',
          style: pw.TextStyle(color: _grey, fontSize: 10));
    }
    final maxVal     = entries.map((e) => e.value).reduce(math.max);
    if (maxVal == 0) return pw.SizedBox(height: 4);

    final totalSpent = entries.fold(0.0, (s, e) => s + e.value);
    const chartH     = 100.0;

    // Round maxVal up to a clean number for Y-axis
    final yMax = _niceMax(maxVal);

    // 4 Y-axis tick values: 0, 25%, 50%, 75%, 100% of yMax
    final yTicks = [yMax, yMax * 0.75, yMax * 0.50, yMax * 0.25, 0.0];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Legend row + total spent ──────────────────────────────────────
        pw.Row(children: [
          pw.Container(width: 9, height: 9,
              decoration: pw.BoxDecoration(color: _trackGrey)),
          pw.SizedBox(width: 4),
          pw.Text('No spending',
              style: pw.TextStyle(fontSize: 7, color: _grey)),
          pw.SizedBox(width: 14),
          pw.Container(width: 9, height: 9,
              decoration: pw.BoxDecoration(color: color)),
          pw.SizedBox(width: 4),
          pw.Text('Spent that day',
              style: pw.TextStyle(fontSize: 7, color: _grey)),
          pw.Spacer(),
          pw.Text(
            'Total spent: ' + _fmt(totalSpent, sym),
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ]),
        pw.SizedBox(height: 6),

        // ── Amount labels ABOVE each bar (plain compact number) ───────────
        pw.Row(children: [
          // Spacer matching Y-axis column width
          pw.SizedBox(width: _yAxisW),
          pw.SizedBox(
            width: _barAreaW,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: entries.map((e) => pw.Expanded(
                child: pw.Center(
                  child: e.value > 0
                      ? pw.Text(
                    _compactNum(e.value),
                    style: pw.TextStyle(
                      fontSize: 4.5,
                      color: color,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  )
                      : pw.SizedBox(),
                ),
              )).toList(),
            ),
          ),
        ]),
        pw.SizedBox(height: 1),

        // ── Chart body: Y-axis labels (pw.Text) + bars (CustomPaint) ────────
        pw.SizedBox(
          width: _chartWidth,
          height: chartH,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Y-axis label column
              pw.SizedBox(
                width: _yAxisW,
                child: pw.Stack(
                  children: yTicks.map((tick) {
                    // Position each label as fraction of chartH from top
                    final topFraction = 1.0 - (tick / yMax);
                    return pw.Positioned(
                      top: topFraction * chartH - 5,
                      left: 0,
                      right: 2,
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          _compactNum(tick),
                          style: pw.TextStyle(fontSize: 5.5, color: _grey),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Bar area
              pw.SizedBox(
                width: _barAreaW,
                height: chartH,
                child: pw.CustomPaint(
                  painter: (canvas, size) =>
                      _drawBarsWithYAxis(canvas, size, entries, yMax, color, yTicks),
                ),
              ),
            ],
          ),
        ),

        // ── Day number labels BELOW bars (offset by yAxisW to align) ─────
        pw.SizedBox(height: 2),
        pw.Row(children: [
          pw.SizedBox(width: _yAxisW),
          pw.SizedBox(
            width: _barAreaW,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: entries.map((e) => pw.Expanded(
                child: pw.Center(
                  child: pw.Text(
                    e.key,
                    style: pw.TextStyle(fontSize: 5.0, color: _grey),
                  ),
                ),
              )).toList(),
            ),
          ),
        ]),
      ],
    );
  }

  // Round up to a clean "nice" ceiling — makes Y-axis labels tidy
  static double _niceMax(double val) {
    if (val <= 0) return 100;
    final magnitude = math.pow(10, (math.log(val) / math.ln10).floor()).toDouble();
    final normalized = val / magnitude;
    double nice;
    if (normalized <= 1)      nice = 1;
    else if (normalized <= 2) nice = 2;
    else if (normalized <= 5) nice = 5;
    else                      nice = 10;
    return nice * magnitude;
  }

  // Compact number without currency code — avoids word-wrap on narrow bars
  static String _compactNum(double v) {
    if (v <= 0) return '';
    if (v >= 1000000) {
      final m = v / 1000000;
      return (m == m.truncateToDouble()
          ? m.toInt().toString() : m.toStringAsFixed(1)) + 'M';
    }
    if (v >= 1000) {
      final k = v / 1000;
      return (k == k.truncateToDouble()
          ? k.toInt().toString() : k.toStringAsFixed(1)) + 'k';
    }
    return v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(0);
  }

  // Draws horizontal grid lines + bars (bottom-to-top fill) in the bar area.
  // Y-axis labels are rendered as pw.Text widgets outside this CustomPaint.
  static void _drawBarsWithYAxis(
      PdfGraphics canvas, PdfPoint size,
      List<MapEntry<String, double>> entries,
      double yMax, PdfColor color,
      List<double> yTicks,
      ) {
    final w = size.x;
    final h = size.y;
    final n = entries.length;
    if (n == 0 || yMax == 0) return;

    final slot = w / n;
    final barW = slot * 0.6;
    final gap  = (slot - barW) / 2;

    // In the pdf package canvas: Y=0 is BOTTOM, Y=h is TOP.
    // So "fill from bottom upward" means: start at y=0, height=barH.
    // Grid lines at tick t: y = (t / yMax) * h  (0 = bottom, h = top)

    // ── Horizontal grid lines ─────────────────────────────────────────────
    for (final tick in yTicks) {
      final y = (tick / yMax) * h; // y=0 bottom, y=h top
      canvas
        ..setStrokeColor(PdfColor.fromHex('#E0E0E0'))
        ..setLineWidth(0.4)
        ..moveTo(0, y)
        ..lineTo(w, y)
        ..strokePath();
    }

    // ── Draw bars ─────────────────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final val  = entries[i].value;
      final barH = (val / yMax) * h;
      final x    = i * slot + gap;

      // Grey full-height track — from y=0 (bottom) to y=h (top)
      canvas
        ..setFillColor(_trackGrey)
        ..drawRect(x, 0, barW, h)
        ..fillPath();

      // Colored fill — starts at y=0 (bottom) grows upward to barH
      if (barH > 0.5) {
        canvas
          ..setFillColor(color)
          ..drawRect(x, 0, barW, barH)
          ..fillPath();
      }
    }

    // Baseline at y=0 (bottom edge)
    canvas
      ..setStrokeColor(PdfColors.grey400)
      ..setLineWidth(0.5)
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..strokePath();
  }


  // ── Horizontal bar ─────────────────────────────────────────────────────────
  static pw.Widget _hBar(
      String label, double value, double maxVal, PdfColor color, String sym) {
    const barH   = 24.0;
    const labelW = 68.0;
    const chartW = 310.0;
    final fillW  = maxVal > 0 ? (value / maxVal) * chartW : 0.0;
    final amtStr = _fmt(value, sym);

    return pw.Row(children: [
      pw.SizedBox(
        width: labelW,
        child: pw.Text(label,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Stack(children: [
        // FIX: use _trackGrey for background instead of color.shade()
        pw.Container(
          width: chartW, height: barH,
          decoration: pw.BoxDecoration(
            color: _trackGrey,
            borderRadius: pw.BorderRadius.circular(5),
          ),
        ),
        if (fillW >= 1)
          pw.Container(
            width: fillW.clamp(4.0, chartW), height: barH,
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(5),
            ),
          ),
      ]),
      pw.SizedBox(width: 8),
      pw.Text(amtStr,
          style: pw.TextStyle(
              fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
    ]);
  }

  // ── Status cards (loans) ───────────────────────────────────────────────────
  static pw.Widget _statusCards(Map<String, int> counts, int total) {
    final colors = {'paid': _green, 'partial': _amber, 'pending': _blue};
    if (counts.isEmpty) return pw.SizedBox(height: 4);
    return pw.Row(children: counts.entries.map((e) {
      final pct   = total > 0 ? (e.value / total * 100) : 0.0;
      final color = colors[e.key] ?? _grey;
      final pctStr = pct.toStringAsFixed(0) + '%';
      final lbl   = e.key.toUpperCase() + ' (' + e.value.toString() + ')';
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4),
          child: pw.Column(children: [
            pw.Container(
              height: 52, width: double.infinity,
              decoration: pw.BoxDecoration(
                  color: color, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Center(child: pw.Text(pctStr,
                  style: pw.TextStyle(
                      color: _white, fontSize: 18, fontWeight: pw.FontWeight.bold))),
            ),
            pw.SizedBox(height: 4),
            pw.Text(lbl,
                style: pw.TextStyle(
                    fontSize: 8, fontWeight: pw.FontWeight.bold, color: color),
                textAlign: pw.TextAlign.center),
          ]),
        ),
      );
    }).toList());
  }

  // ── FIX 3: Goal progress row — replace drawRRect with drawRect ─────────────
  static pw.Widget _goalProgressRow(GoalModel g, String sym) {
    final pct   = g.progress.clamp(0.0, 1.0);
    final color = pct >= 1.0 ? _green
        : pct >= 0.75 ? _blue
        : pct >= 0.5  ? _amber : _grey;
    final savedStr  = _fmt(g.savedAmount, sym);
    final targetStr = _fmt(g.targetAmount, sym);
    final pctStr    = (pct * 100).toStringAsFixed(1) + '% complete';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Name + saved/target
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(g.name,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy,
                  )),
              pw.Text(
                savedStr + ' / ' + targetStr,
                style: pw.TextStyle(fontSize: 8, color: _grey),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          _progressBar(pct, color, height: 9),
          pw.SizedBox(height: 4),
          // Percentage left-aligned, completion status right-aligned
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                pctStr,
                style: pw.TextStyle(
                  fontSize: 8,
                  color: color,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (g.isCompleted)
                pw.Text(
                  'Completed',
                  style: pw.TextStyle(fontSize: 8, color: _green,
                      fontWeight: pw.FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── FIX 3: Goal card — replace drawRRect with drawRect ────────────────────
  static pw.Widget _goalCard(GoalModel g, String sym) {
    final pct         = g.progress.clamp(0.0, 1.0);
    final isCompleted = g.isCompleted;
    final color       = isCompleted ? _green
        : pct >= 0.75 ? _blue
        : pct >= 0.5  ? _amber
        : _grey;
    final statusLabel = isCompleted ? 'COMPLETED' : 'IN PROGRESS';
    // Badge color: green for completed, amber for in-progress
    final badgeColor  = isCompleted ? _green : _amber;
    final savedStr    = _fmt(g.savedAmount, sym);
    final targStr     = _fmt(g.targetAmount, sym);
    final remStr      = _fmt(g.remaining, sym);
    final pctStr      = (pct * 100).toStringAsFixed(1) + '% complete';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      decoration: pw.BoxDecoration(
        // Clean white card with a left colored accent border
        color: _white,
        border: pw.Border(
          left: pw.BorderSide(color: color, width: 4),
          top:    pw.BorderSide(color: PdfColor.fromHex('#E0E0E0'), width: 0.5),
          right:  pw.BorderSide(color: PdfColor.fromHex('#E0E0E0'), width: 0.5),
          bottom: pw.BorderSide(color: PdfColor.fromHex('#E0E0E0'), width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.all(14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Header: name + status badge ─────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(g.name,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: _navy,
                    )),
              ),
              // Clean rectangular badge — no circular radius to avoid fish shape
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: badgeColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  statusLabel,
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: _white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // ── Stats row ────────────────────────────────────────────────────
          pw.Row(children: [
            pw.Expanded(child: _gStat('Saved',     savedStr, _green)),
            pw.Expanded(child: _gStat('Target',    targStr,  _navy)),
            pw.Expanded(child: _gStat('Remaining', remStr,   _red)),
            if (g.deadline != null)
              pw.Expanded(child: _gStat('Deadline', _fmtDate(g.deadline!), _amber)),
          ]),

          pw.SizedBox(height: 12),

          // ── Progress bar ─────────────────────────────────────────────────
          _progressBar(pct, color, height: 10),
          pw.SizedBox(height: 5),

          // ── Percentage + remaining label ─────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(pctStr,
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: color,
                    fontWeight: pw.FontWeight.bold,
                  )),
              if (!isCompleted)
                pw.Text(
                  _fmt(g.remaining, sym) + ' to go',
                  style: pw.TextStyle(fontSize: 8, color: _grey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── FIX 3: Reusable progress bar using CustomPaint with drawRect ─────────
  // double.infinity width gives size.x == 0 in pw.CustomPaint — bars invisible.
  // Fix: use the same fixed _chartWidth (515pt = A4 minus 40pt margins each side).
  // For goal cards the bar is inside a container so _chartWidth still fits fine.
  static pw.Widget _progressBar(double pct, PdfColor color, {double height = 10}) {
    final clampedPct = pct.clamp(0.0, 1.0);
    return pw.SizedBox(
      // FIX: explicit fixed width — pw.CustomPaint needs a concrete size to paint
      width: _chartWidth,
      height: height,
      child: pw.CustomPaint(
        painter: (canvas, size) {
          final w = size.x;
          final h = size.y;
          final fillW = w * clampedPct;

          // Background track
          canvas
            ..setFillColor(_trackGrey)
            ..drawRect(0, 0, w, h)
            ..fillPath();

          // Filled portion
          if (fillW > 0.5) {
            canvas
              ..setFillColor(color)
              ..drawRect(0, 0, fillW, h)
              ..fillPath();
          }
        },
      ),
    );
  }

  static pw.Widget _gStat(String label, String value, PdfColor color) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _grey)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(
            fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
      ]);

  // ── Wallets ────────────────────────────────────────────────────────────────
  static pw.Widget _wallets(List<WalletModel> wallets, String sym) {
    return pw.Wrap(spacing: 10, runSpacing: 10,
      children: wallets.map((w) {
        final color  = _pdfColorFromInt(w.colorValue);
        final balStr = _fmt(w.balance, sym);
        return pw.Container(
          width: 135,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: color.shade(0.75), width: 1),
            borderRadius: pw.BorderRadius.circular(10),
            color: color.shade(0.95),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(w.name,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text(w.type.toUpperCase(),
                  style: pw.TextStyle(fontSize: 8, color: color)),
              pw.SizedBox(height: 4),
              pw.Text(balStr,
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Tables ─────────────────────────────────────────────────────────────────
  static pw.Widget _catTable(
      List<MapEntry<String, double>> entries,
      Map<String, CategoryModel> categories,
      double total, String sym,
      ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _light, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        _hdr(['#', 'Category', 'Amount', 'Share'], _navy),
        ...entries.asMap().entries.map((entry) {
          final i   = entry.key;
          final e   = entry.value;
          final cat = categories[e.key];
          final pct = total > 0 ? (e.value / total * 100) : 0.0;
          return pw.TableRow(
            decoration: i % 2 == 0
                ? pw.BoxDecoration(color: _light) : null,
            children: [
              _tc((i + 1).toString(), center: true),
              _tc(cat?.name ?? e.key),
              _tc(_fmt(e.value, sym), right: true),
              _tc(pct.toStringAsFixed(1) + '%', center: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _expTable(
      List<ExpenseModel> expenses,
      Map<String, CategoryModel> categories,
      List<WalletModel> wallets, String sym,
      ) {
    final walletMap = {for (final w in wallets) w.id: w};
    return pw.Table(
      border: pw.TableBorder.all(color: _light, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(52),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1.8),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.8),
        5: const pw.FlexColumnWidth(2),
      },
      children: [
        _hdr(['Date','Name','Category','Wallet','Amount','Note'], _navy),
        ...expenses.asMap().entries.map((entry) {
          final i      = entry.key;
          final e      = entry.value;
          final cat    = categories[e.categoryId];
          final wallet = e.walletId != null ? walletMap[e.walletId] : null;
          return pw.TableRow(
            decoration: i % 2 == 0
                ? pw.BoxDecoration(color: _light) : null,
            children: [
              _tc(_fmtDate(e.date)),
              _tc(e.name),
              _tc(cat?.name ?? '-'),
              _tc(wallet?.name ?? '-'),
              _tc(_fmt(e.amount, sym), right: true),
              _tc(e.note ?? '-'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _incTable(
      List<IncomeModel> income,
      List<WalletModel> wallets, String sym,
      ) {
    final walletMap = {for (final w in wallets) w.id: w};
    return pw.Table(
      border: pw.TableBorder.all(color: _light, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(52),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.8),
        5: const pw.FlexColumnWidth(2),
      },
      children: [
        _hdr(['Date','Name','Source','Wallet','Amount','Note'], _green),
        ...income.asMap().entries.map((entry) {
          final i      = entry.key;
          final inc    = entry.value;
          final wallet = inc.walletId != null ? walletMap[inc.walletId] : null;
          return pw.TableRow(
            decoration: i % 2 == 0
                ? pw.BoxDecoration(color: _light) : null,
            children: [
              _tc(_fmtDate(inc.date)),
              _tc(inc.name),
              _tc(inc.source),
              _tc(wallet?.name ?? '-'),
              _tc(_fmt(inc.amount, sym), right: true),
              _tc(inc.note ?? '-'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _loanTable(List<LoanModel> loans, String sym) {
    return pw.Table(
      border: pw.TableBorder.all(color: _light, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FixedColumnWidth(58),
        5: const pw.FixedColumnWidth(48),
      },
      children: [
        _hdr(['Person','Amount','Paid','Remaining','Due Date','Status'], _amber),
        ...loans.asMap().entries.map((entry) {
          final i = entry.key;
          final l = entry.value;
          return pw.TableRow(
            decoration: i % 2 == 0
                ? pw.BoxDecoration(color: _light) : null,
            children: [
              _tc(l.personName),
              _tc(_fmt(l.amount, sym),      right: true),
              _tc(_fmt(l.paidAmount, sym),  right: true),
              _tc(_fmt(l.remaining, sym),   right: true),
              _tc(l.dueDate != null ? _fmtDate(l.dueDate!) : '-'),
              _tc(l.status.toUpperCase(), center: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.TableRow _hdr(List<String> cols, PdfColor color) =>
      pw.TableRow(
        decoration: pw.BoxDecoration(color: color),
        children: cols.map((h) => pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(h,
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold, color: _white)),
        )).toList(),
      );

  static pw.Widget _tc(String text,
      {bool right = false, bool center = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(text,
            style: const pw.TextStyle(fontSize: 8),
            textAlign: right  ? pw.TextAlign.right
                : center ? pw.TextAlign.center
                : pw.TextAlign.left),
      );

  // ── Shared UI helpers ──────────────────────────────────────────────────────
  static pw.Widget _card(String label, String value, PdfColor color) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color.shade(0.75), width: 1),
          borderRadius: pw.BorderRadius.circular(8),
          color: color.shade(0.95),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _grey)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      );

  static pw.Widget _title(String text) =>
      pw.Row(children: [
        pw.Container(width: 4, height: 13, color: _navy),
        pw.SizedBox(width: 8),
        pw.Text(text, style: pw.TextStyle(
            fontSize: 12, fontWeight: pw.FontWeight.bold, color: _navy)),
      ]);

  static pw.Widget _secHeader(String title, PdfColor color) =>
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        margin: const pw.EdgeInsets.only(bottom: 16),
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [color, color.shade(0.80)],
            begin: pw.Alignment.centerLeft,
            end: pw.Alignment.centerRight,
          ),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(title, style: pw.TextStyle(
            fontSize: 16, fontWeight: pw.FontWeight.bold, color: _white)),
      );

  // ── FIX 1: Footer — replace em-dash separator with plain ASCII " | " ───────
  // The pdf package default font cannot render unicode em-dash or bullet chars.
  static pw.Widget _footer(pw.Context ctx, DateTime now) =>
      pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: pw.BoxDecoration(
            border: pw.Border(
                top: pw.BorderSide(color: _light, width: 1))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              // FIX 1: was using non-ASCII em-dash; now plain ASCII " | "
                'Spendly Financial Report | ' + _fmtDate(now),
                style: pw.TextStyle(fontSize: 8, color: _grey)),
            pw.Text(
                'Page ' + ctx.pageNumber.toString() +
                    ' of ' + ctx.pagesCount.toString(),
                style: pw.TextStyle(fontSize: 8, color: _grey)),
          ],
        ),
      );

  // ── Slice helpers ──────────────────────────────────────────────────────────
  static List<_Slice> _toSlices(
      List<MapEntry<String, double>> entries,
      Map<String, CategoryModel> categories,
      ) {
    return entries.asMap().entries.map((e) => _Slice(
      label: categories[e.value.key]?.name ?? e.value.key,
      value: e.value.value,
      color: _catColors[e.key % _catColors.length],
    )).toList();
  }

  static List<_Slice> _srcSlices(Map<String, double> src) {
    final entries = src.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.asMap().entries.map((e) => _Slice(
      label: e.value.key,
      value: e.value.value,
      color: _catColors[e.key % _catColors.length],
    )).toList();
  }
}

// ── Pie slice ──────────────────────────────────────────────────────────────────
class _Slice {
  final String   label;
  final double   value;
  final PdfColor color;
  const _Slice({required this.label, required this.value, required this.color});
}