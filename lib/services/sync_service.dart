import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/wallet_model.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import '../models/loan_model.dart';
import 'auth_service.dart';

/// Local-first sync service.
/// Hive is the primary source of truth (fast, offline).
/// Firestore is the cloud backup (nightly sync).
class SyncService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final Box _settings = Hive.box('settings');

  // ── User collection reference ─────────────────────────────────────────────
  static CollectionReference _userCol(String sub) {
    final uid = AuthService.userId!;
    return _db.collection('users').doc(uid).collection(sub);
  }

  // ── Check if nightly sync is needed ──────────────────────────────────────
  static bool get needsSync {
    final lastSync = _settings.get('lastSyncTime', defaultValue: 0) as int;
    final now      = DateTime.now().millisecondsSinceEpoch;
    final hours    = (now - lastSync) / (1000 * 60 * 60);
    return hours >= 24; // sync every 24 hours
  }

  // ── Check if cloud has any data ──────────────────────────────────────────
  static Future<bool> hasCloudData() async {
    if (!AuthService.isLoggedIn) return false;
    try {
      final uid  = AuthService.userId!;
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Check if local Hive has any data ──────────────────────────────────────
  static bool hasLocalData() {
    final expenses  = Hive.box<ExpenseModel>('expenses');
    final wallets   = Hive.box<WalletModel>('wallets');
    // Wallets always have 2 defaults — only count if user added expenses
    return expenses.isNotEmpty || wallets.length > 2;
  }

  // ── Full sync — call on app open if needsSync ─────────────────────────────
  static Future<void> syncIfNeeded() async {
    if (!AuthService.isLoggedIn) return;
    if (!needsSync) return;
    await syncAll();
  }

  // ── Migrate ALL local Hive data to Firestore ──────────────────────────────
  /// Called once on first login to push all existing local data to cloud.
  static Future<void> migrateLocalData() async {
    if (!AuthService.isLoggedIn) return;

    await Future.wait([
      _syncExpenses(),
      _syncIncome(),
      _syncWallets(),
      _syncCategories(),
      _syncGoals(),
      _syncLoans(),
      _syncSettings(),
    ]);

    _settings.put('lastSyncTime',
        DateTime.now().millisecondsSinceEpoch);
    _settings.put('dataMigrated', true);
  }

  // ── Full sync (nightly) ───────────────────────────────────────────────────
  static Future<void> syncAll() async {
    if (!AuthService.isLoggedIn) return;

    await Future.wait([
      _syncExpenses(),
      _syncIncome(),
      _syncWallets(),
      _syncCategories(),
      _syncGoals(),
      _syncLoans(),
      _syncSettings(),
    ]);

    _settings.put('lastSyncTime',
        DateTime.now().millisecondsSinceEpoch);
  }

  // ── Expenses ──────────────────────────────────────────────────────────────
  static Future<void> _syncExpenses() async {
    final box = Hive.box<ExpenseModel>('expenses');
    final batch = _db.batch();
    final col = _userCol('expenses');

    for (final e in box.values) {
      batch.set(col.doc(e.id), {
        'id':                     e.id,
        'name':                   e.name,
        'amount':                 e.amount,
        'categoryId':             e.categoryId,
        'date':                   e.date.toIso8601String(),
        'note':                   e.note,
        'isRecurring':            e.isRecurring,
        'recurringType':          e.recurringType,
        'walletId':               e.walletId,
        'timeHour':               e.timeHour,
        'timeMinute':             e.timeMinute,
        'recurringParentId':      e.recurringParentId,
        'recurringLastGenerated': e.recurringLastGenerated?.toIso8601String(),
      });
    }
    await batch.commit();
  }

  // ── Income ────────────────────────────────────────────────────────────────
  static Future<void> _syncIncome() async {
    final box = Hive.box<IncomeModel>('income');
    final batch = _db.batch();
    final col = _userCol('income');

    for (final i in box.values) {
      batch.set(col.doc(i.id), {
        'id':         i.id,
        'name':       i.name,
        'amount':     i.amount,
        'source':     i.source,
        'date':       i.date.toIso8601String(),
        'note':       i.note,
        'walletId':   i.walletId,
        'timeHour':   i.timeHour,
        'timeMinute': i.timeMinute,
      });
    }
    await batch.commit();
  }

  // ── Wallets ───────────────────────────────────────────────────────────────
  static Future<void> _syncWallets() async {
    final box = Hive.box<WalletModel>('wallets');
    final batch = _db.batch();
    final col = _userCol('wallets');

    for (final w in box.values) {
      batch.set(col.doc(w.id), {
        'id':             w.id,
        'name':           w.name,
        'type':           w.type,
        'balance':        w.balance,
        'colorValue':     w.colorValue,
        'icon':           w.icon,
        'allowOverdraft': w.allowOverdraft,
      });
    }
    await batch.commit();
  }

  // ── Categories ────────────────────────────────────────────────────────────
  static Future<void> _syncCategories() async {
    final box = Hive.box<CategoryModel>('categories');
    final batch = _db.batch();
    final col = _userCol('categories');

    for (final c in box.values) {
      batch.set(col.doc(c.id), {
        'id':         c.id,
        'name':       c.name,
        'icon':       c.icon,
        'colorValue': c.colorValue,
      });
    }
    await batch.commit();
  }

  // ── Goals ─────────────────────────────────────────────────────────────────
  static Future<void> _syncGoals() async {
    final box = Hive.box<GoalModel>('goals');
    final batch = _db.batch();
    final col = _userCol('goals');

    for (final g in box.values) {
      batch.set(col.doc(g.id), {
        'id':           g.id,
        'name':         g.name,
        'targetAmount': g.targetAmount,
        'savedAmount':  g.savedAmount,
        'deadline':     g.deadline?.toIso8601String(),
        'isCompleted':  g.isCompleted,
        'iconKey':      g.iconKey,
      });
    }
    await batch.commit();
  }

  // ── Loans ─────────────────────────────────────────────────────────────────
  static Future<void> _syncLoans() async {
    final box = Hive.box<LoanModel>('loans');
    final batch = _db.batch();
    final col = _userCol('loans');

    for (final l in box.values) {
      batch.set(col.doc(l.id), {
        'id':          l.id,
        'personName':  l.personName,
        'amount':      l.amount,
        'paidAmount':  l.paidAmount,
        'type':        l.type,
        'date':        l.date.toIso8601String(),
        'dueDate':     l.dueDate?.toIso8601String(),
        'note':        l.note,
        'status':      l.status,
        'walletId':    l.walletId,
      });
    }
    await batch.commit();
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  static Future<void> _syncSettings() async {
    final uid = AuthService.userId!;
    await _db.collection('users').doc(uid).set({
      'currency':     _settings.get('currency',     defaultValue: 'USD'),
      'isDarkMode':   _settings.get('darkMode',     defaultValue: false),
      'monthlyBudget': _settings.get('monthlyBudget', defaultValue: 0.0),
      'themeColor':   _settings.get('themeColor',   defaultValue: 0xFF2196F3),
      'notifEnabled': _settings.get('notifEnabled', defaultValue: false),
      'notifDaily':   _settings.get('notifDaily',   defaultValue: true),
      'notifWeekly':  _settings.get('notifWeekly',  defaultValue: true),
      'notifBudget':  _settings.get('notifBudget',  defaultValue: true),
      'notifLoan':    _settings.get('notifLoan',    defaultValue: true),
      'notifGoal':    _settings.get('notifGoal',    defaultValue: true),
      'notifHour':    _settings.get('notifHour',    defaultValue: 21),
      'notifMinute':  _settings.get('notifMinute',  defaultValue: 0),
      'lastSyncTime': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  // ── Restore from Firestore to Hive ────────────────────────────────────────
  /// Used when user logs in on a new device — pulls cloud data into Hive.
  static Future<void> restoreFromCloud() async {
    if (!AuthService.isLoggedIn) return;

    await Future.wait([
      _restoreExpenses(),
      _restoreIncome(),
      _restoreWallets(),
      _restoreCategories(),
      _restoreGoals(),
      _restoreLoans(),
      _restoreSettings(),
    ]);

    _settings.put('lastSyncTime',
        DateTime.now().millisecondsSinceEpoch);
    _settings.put('dataMigrated', true);
  }

  static Future<void> _restoreExpenses() async {
    final box  = Hive.box<ExpenseModel>('expenses');
    final docs = await _userCol('expenses').get();
    for (final doc in docs.docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (!box.containsKey(d['id'])) {
        box.put(d['id'], ExpenseModel(
          id:          d['id'],
          name:        d['name'],
          amount:      (d['amount'] as num).toDouble(),
          categoryId:  d['categoryId'],
          date:        DateTime.parse(d['date']),
          note:        d['note'],
          isRecurring: d['isRecurring'] ?? false,
          recurringType: d['recurringType'],
          walletId:    d['walletId'],
          timeHour:    d['timeHour'],
          timeMinute:  d['timeMinute'],
          recurringParentId:      d['recurringParentId'],
          recurringLastGenerated: d['recurringLastGenerated'] != null
              ? DateTime.parse(d['recurringLastGenerated'])
              : null,
        ));
      }
    }
  }

  static Future<void> _restoreIncome() async {
    final box  = Hive.box<IncomeModel>('income');
    final docs = await _userCol('income').get();
    for (final doc in docs.docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (!box.containsKey(d['id'])) {
        box.put(d['id'], IncomeModel(
          id:         d['id'],
          name:       d['name'],
          amount:     (d['amount'] as num).toDouble(),
          source:     d['source'] ?? 'other',
          date:       DateTime.parse(d['date']),
          note:       d['note'],
          walletId:   d['walletId'],
          timeHour:   d['timeHour'],
          timeMinute: d['timeMinute'],
        ));
      }
    }
  }

  static Future<void> _restoreWallets() async {
    final box  = Hive.box<WalletModel>('wallets');
    final docs = await _userCol('wallets').get();
    for (final doc in docs.docs) {
      final d = doc.data() as Map<String, dynamic>;
      box.put(d['id'], WalletModel(
        id:           d['id'],
        name:         d['name'],
        type:         d['type'],
        balance:      (d['balance'] as num).toDouble(),
        colorValue:   d['colorValue'],
        icon:         d['icon'] ?? 'wallet',
        allowOverdraft: d['allowOverdraft'] ?? false,
      ));
    }
  }

  static Future<void> _restoreCategories() async {
    final box  = Hive.box<CategoryModel>('categories');
    final docs = await _userCol('categories').get();
    for (final doc in docs.docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (!box.containsKey(d['id'])) {
        box.put(d['id'], CategoryModel(
          id:         d['id'],
          name:       d['name'],
          icon:       d['icon'],
          colorValue: d['colorValue'],
        ));
      }
    }
  }

  static Future<void> _restoreGoals() async {
    final box  = Hive.box<GoalModel>('goals');
    final docs = await _userCol('goals').get();
    for (final doc in docs.docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (!box.containsKey(d['id'])) {
        box.put(d['id'], GoalModel(
          id:           d['id'],
          name:         d['name'],
          targetAmount: (d['targetAmount'] as num).toDouble(),
          savedAmount:  (d['savedAmount'] as num).toDouble(),
          deadline:     d['deadline'] != null
              ? DateTime.parse(d['deadline'])
              : null,
          isCompleted: d['isCompleted'] ?? false,
          iconKey:     d['iconKey'],
        ));
      }
    }
  }

  static Future<void> _restoreLoans() async {
    final box  = Hive.box<LoanModel>('loans');
    final docs = await _userCol('loans').get();
    for (final doc in docs.docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (!box.containsKey(d['id'])) {
        box.put(d['id'], LoanModel(
          id:          d['id'],
          personName:  d['personName'],
          amount:      (d['amount'] as num).toDouble(),
          paidAmount:  (d['paidAmount'] as num? ?? 0).toDouble(),
          type:        d['type'] ?? 'lending',
          date:        DateTime.parse(d['date']),
          dueDate:     d['dueDate'] != null
              ? DateTime.parse(d['dueDate'])
              : null,
          note:     d['note'],
          status:   d['status'] ?? 'pending',
          walletId: d['walletId'],
        ));
      }
    }
  }
  static Future<void> _restoreSettings() async {
    final uid = AuthService.userId!;
    final doc = await _db.collection('users').doc(uid).get();
    final d = doc.data();
    if (d == null) return;

    if (d['currency'] != null) {
      _settings.put('currency', d['currency']);
    }
    if (d['isDarkMode'] != null) {
      _settings.put('darkMode', d['isDarkMode']);
    }
    if (d['monthlyBudget'] != null) {
      _settings.put('monthlyBudget', (d['monthlyBudget'] as num).toDouble());
    }
    if (d['themeColor'] != null) {
      _settings.put('themeColor', d['themeColor']);
    }
    if (d['notifEnabled'] != null) {
      _settings.put('notifEnabled', d['notifEnabled']);
    }
    if (d['notifDaily'] != null) {
      _settings.put('notifDaily', d['notifDaily']);
    }
    if (d['notifWeekly'] != null) {
      _settings.put('notifWeekly', d['notifWeekly']);
    }
    if (d['notifBudget'] != null) {
      _settings.put('notifBudget', d['notifBudget']);
    }
    if (d['notifLoan'] != null) {
      _settings.put('notifLoan', d['notifLoan']);
    }
    if (d['notifGoal'] != null) {
      _settings.put('notifGoal', d['notifGoal']);
    }
    if (d['notifHour'] != null) {
      _settings.put('notifHour', d['notifHour']);
    }
    if (d['notifMinute'] != null) {
      _settings.put('notifMinute', d['notifMinute']);
    }
  }
}
