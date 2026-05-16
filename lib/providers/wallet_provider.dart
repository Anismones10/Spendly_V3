import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/wallet_model.dart';
import '../utils/app_utils.dart';

class WalletProvider extends ChangeNotifier {
  final Box<WalletModel> _box = Hive.box<WalletModel>('wallets');

  // Default wallets seeded only on first launch
  static final List<WalletModel> _defaults = [
    WalletModel(
      id: 'cash',
      name: 'Cash',
      type: 'cash',
      balance: 0,
      colorValue: 0xFF4CAF50,
      icon: 'cash',
    ),
    WalletModel(
      id: 'card',
      name: 'Card',
      type: 'card',
      balance: 0,
      colorValue: 0xFF1E3A5F,
      icon: 'card',
    ),
  ];

  WalletProvider() {
    _seedDefaults();
  }

  void _seedDefaults() {
    // Only add defaults if this is the first launch
    if (_box.isEmpty) {
      for (final w in _defaults) {
        _box.put(w.id, w);
      }
    }
  }

  List<WalletModel> get wallets => _box.values.toList();

  WalletModel? getById(String id) => _box.get(id);

  double get totalBalance => _box.values.fold(0, (sum, w) => sum + w.balance);

  double getSpent(String walletId, List<dynamic> expenses) {
    return expenses
        .where((e) => e.walletId == walletId)
        .fold(0.0, (sum, e) => sum + (e.amount as double));
  }

  double getRemaining(String walletId, List<dynamic> expenses) {
    final wallet = _box.get(walletId);
    if (wallet == null) return 0;
    return wallet.balance - getSpent(walletId, expenses);
  }

  double getTotalRemaining(List<dynamic> expenses) {
    return _box.values.fold(0.0, (sum, w) {
      return sum + getRemaining(w.id, expenses);
    });
  }

  double getTotalSpent(List<dynamic> expenses) {
    return _box.values.fold(0.0, (sum, w) {
      return sum + getSpent(w.id, expenses);
    });
  }

  void addWallet(WalletModel wallet) {
    _box.put(wallet.id, wallet);
    notifyListeners();
  }

  void updateWallet(WalletModel wallet) {
    _box.put(wallet.id, wallet);
    notifyListeners();
  }

  void updateBalance(String id, double newBalance) {
    final wallet = _box.get(id);
    if (wallet != null) {
      wallet.balance = newBalance;
      wallet.save();
      notifyListeners();
    }
  }

  void deleteWallet(String id) {
    if (_box.length <= 1) return;

    _box.delete(id);
    notifyListeners();
  }

  void clearAll() {
    _box.clear();

    for (final w in _defaults) {
      _box.put(w.id, w);
    }

    notifyListeners();
  }

  static IconData resolveIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.payments_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'savings':
        return Icons.savings_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  static int colorForType(String type) {
    switch (type) {
      case 'cash':
        return 0xFF4CAF50;
      case 'card':
        return 0xFF1E3A5F;
      case 'bank':
        return 0xFF2196F3;
      case 'savings':
        return 0xFF9C27B0;
      default:
        return 0xFF4A90E2;
    }
  }
}
