import 'dart:convert';

/// Shared PIN hashing utility used by both lock_screen.dart and set_pin_screen.dart
String hashPin(String pin) {
  final bytes = utf8.encode(pin + 'spendly_salt_2024');
  int hash = 0;
  for (final b in bytes) {
    hash = ((hash << 5) - hash + b) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16);
}
