import 'dart:convert';

/// Shared PIN and recovery utilities

// ── PIN hash ───────────────────────────────────────────────────────────────────
String hashPin(String pin) {
  final bytes = utf8.encode(pin + 'spendly_salt_2024');
  int hash = 0;
  for (final b in bytes) {
    hash = ((hash << 5) - hash + b) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16);
}

// ── Secret word ───────────────────────────────────────────────────────────────
/// Hash the secret word for safe Hive storage
String hashSecretWord(String word) {
  final clean = word.trim().toLowerCase();
  final bytes = utf8.encode(clean + 'spendly_secret_2024');
  int hash = 0;
  for (final b in bytes) {
    hash = ((hash << 5) - hash + b) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16);
}

/// Check if entered word matches stored hash
bool verifySecretWord(String entered, String storedHash) {
  return hashSecretWord(entered.trim()) == storedHash;
}

/// Build a masked hint from a word  e.g. "Apple" → "A***e"
String buildHint(String word) {
  final w = word.trim();
  if (w.length <= 2) return '*' * w.length;
  if (w.length == 3) return '${w[0]}*${w[w.length - 1]}';
  final stars = '*' * (w.length - 2);
  return '${w[0]}$stars${w[w.length - 1]}';
}
