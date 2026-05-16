import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transfer_model.dart';
import '../models/wallet_model.dart';

class TransferProvider extends ChangeNotifier {
  final Box<TransferModel> _box = Hive.box<TransferModel>('transfers');
  final Box<WalletModel> _walletBox = Hive.box<WalletModel>('wallets');

  List<TransferModel> get allTransfers =>
      _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  List<TransferModel> getTransfersForWallet(String walletId) {
    return _box.values
        .where((t) =>
            t.fromWalletId == walletId || t.toWalletId == walletId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ── Execute transfer ────────────────────────────────────────────────────────
  bool transfer({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required DateTime date,
    String? note,
    required String id,
  }) {
    final fromWallet = _walletBox.get(fromWalletId);
    final toWallet = _walletBox.get(toWalletId);

    if (fromWallet == null || toWallet == null) return false;
    if (amount <= 0) return false;

    // Deduct from source wallet
    fromWallet.balance -= amount;
    fromWallet.save();

    // Add to destination wallet
    toWallet.balance += amount;
    toWallet.save();

    // Save transfer record
    final transfer = TransferModel(
      id: id,
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      date: date,
      note: note,
    );
    _box.put(id, transfer);

    notifyListeners();
    return true;
  }

  // ── Delete transfer → reverse wallet effect ─────────────────────────────────
  void deleteTransfer(String id) {
    final transfer = _box.get(id);
    if (transfer == null) return;

    final fromWallet = _walletBox.get(transfer.fromWalletId);
    final toWallet = _walletBox.get(transfer.toWalletId);

    // Reverse: add back to from, deduct from to
    if (fromWallet != null) {
      fromWallet.balance += transfer.amount;
      fromWallet.save();
    }
    if (toWallet != null) {
      toWallet.balance -= transfer.amount;
      if (toWallet.balance < 0) toWallet.balance = 0;
      toWallet.save();
    }

    _box.delete(id);
    notifyListeners();
  }

  void clearAll() {
    _box.clear();
    notifyListeners();
  }
}
