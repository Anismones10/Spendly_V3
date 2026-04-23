import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CalculatorSheet extends StatefulWidget {
  final double initial;
  const CalculatorSheet({super.key, this.initial = 0});

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  String _display = '';
  String _expression = '';
  bool _justEvaluated = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial > 0) {
      _display = widget.initial.toStringAsFixed(2);
    }
  }

  void _onKey(String key) {
    setState(() {
      if (key == 'C') {
        _display = '';
        _expression = '';
        _justEvaluated = false;
      } else if (key == '⌫') {
        if (_display.isNotEmpty) {
          _display = _display.substring(0, _display.length - 1);
        }
      } else if (key == '=') {
        _evaluate();
      } else if (['+', '−', '×', '÷', '%'].contains(key)) {
        if (_justEvaluated) {
          _expression = _display;
          _justEvaluated = false;
        } else {
          _expression = _display;
        }
        final op = key == '−' ? '-' : key == '×' ? '*' : key == '÷' ? '/' : key;
        _display = '$_display $op ';
      } else {
        if (_justEvaluated) {
          _display = key;
          _justEvaluated = false;
        } else {
          _display += key;
        }
      }
    });
  }

  void _evaluate() {
    try {
      // Simple safe parser - handles basic operations
      String expr = _display
          .replaceAll('−', '-')
          .replaceAll('×', '*')
          .replaceAll('÷', '/');

      // Support: num op num
      final parts = expr.trim().split(RegExp(r'\s+'));
      if (parts.length == 3) {
        final a = double.parse(parts[0]);
        final b = double.parse(parts[2]);
        final op = parts[1];
        double result;
        switch (op) {
          case '+': result = a + b; break;
          case '-': result = a - b; break;
          case '*': result = a * b; break;
          case '/': result = b != 0 ? a / b : 0; break;
          case '%': result = a * b / 100; break;
          default: return;
        }
        _display = result % 1 == 0
            ? result.toInt().toString()
            : result.toStringAsFixed(2);
        _justEvaluated = true;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final keys = [
      ['C', '%', '⌫', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['0', '.', '=', ''],
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _display.isEmpty ? '0' : _display,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Keys
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: keys.map((row) {
                return Row(
                  children: row.map((key) {
                    if (key.isEmpty) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(5),
                          height: 64,
                          child: ElevatedButton(
                            onPressed: () {
                              final result = double.tryParse(
                                _display.split(' ').last,
                              );
                              Navigator.pop(context, result);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: const Text('OK',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 18)),
                          ),
                        ),
                      );
                    }
                    final isOp = ['+', '−', '×', '÷', '%'].contains(key);
                    final isEq = key == '=';
                    final isClear = key == 'C' || key == '⌫';

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onKey(key),
                        child: Container(
                          margin: const EdgeInsets.all(5),
                          height: 64,
                          decoration: BoxDecoration(
                            color: isEq
                                ? theme.colorScheme.primary
                                : isClear
                                    ? theme.colorScheme.error.withOpacity(0.15)
                                    : isOp
                                        ? theme.colorScheme.primary.withOpacity(0.15)
                                        : isDark
                                            ? const Color(0xFF2A2A2A)
                                            : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            key,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: isEq
                                  ? Colors.white
                                  : isClear
                                      ? theme.colorScheme.error
                                      : isOp
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ).animate().scale(
                            begin: const Offset(1, 1),
                            curve: Curves.easeOut,
                          ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
