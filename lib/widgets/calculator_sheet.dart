import 'package:flutter/material.dart';

class CalculatorSheet extends StatefulWidget {
  final double initial;
  const CalculatorSheet({super.key, this.initial = 0});

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  // Full expression string e.g. "123 + 45 - 6 × 2"
  String _expression = '';
  // What's shown in the display
  String _display = '';
  // Result after pressing =
  String _result = '';
  bool _justEvaluated = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial > 0) {
      _display = _formatNum(widget.initial);
      _expression = _formatNum(widget.initial);
    }
  }

  String _formatNum(double n) {
    if (n == n.truncateToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }

  // Check if last character in expression is an operator
  bool get _lastIsOperator {
    final trimmed = _expression.trimRight();
    if (trimmed.isEmpty) return false;
    return ['+', '-', '×', '÷', '%'].contains(trimmed[trimmed.length - 1]);
  }

  void _onKey(String key) {
    setState(() {
      if (key == 'C') {
        _expression = '';
        _display = '';
        _result = '';
        _justEvaluated = false;
        return;
      }

      if (key == '⌫') {
        if (_justEvaluated) {
          _expression = '';
          _display = '';
          _result = '';
          _justEvaluated = false;
          return;
        }
        if (_expression.isNotEmpty) {
          // Remove last character, also trim trailing space
          _expression = _expression.trimRight();
          _expression =
              _expression.substring(0, _expression.length - 1).trimRight();
          _display = _expression;
          _result = '';
        }
        return;
      }

      if (key == '=') {
        _evaluate();
        return;
      }

      // Operator keys
      if (['+', '-', '×', '÷', '%'].contains(key)) {
        if (_justEvaluated && _result.isNotEmpty) {
          // Continue calculation from result
          _expression = _result;
          _result = '';
          _justEvaluated = false;
        }
        if (_expression.isEmpty) return;
        // Replace last operator if already ends with one
        if (_lastIsOperator) {
          _expression = _expression.trimRight();
          _expression =
              _expression.substring(0, _expression.length - 1).trimRight();
        }
        _expression += ' $key ';
        _display = _expression;
        _result = '';
        return;
      }

      // Number / dot keys
      if (_justEvaluated) {
        // Start fresh after evaluation
        _expression = '';
        _result = '';
        _justEvaluated = false;
      }

      // Prevent multiple dots in current number
      if (key == '.') {
        // Find the current number being typed
        final parts = _expression.split(RegExp(r'[\+\-×÷%]'));
        final currentNum = parts.last.trim();
        if (currentNum.contains('.')) return;
        if (currentNum.isEmpty) {
          _expression += '0.';
          _display = _expression;
          return;
        }
      }

      _expression += key;
      _display = _expression;
      _result = '';
    });
  }

  void _evaluate() {
    if (_expression.isEmpty) return;

    try {
      // Convert display operators to Dart operators
      String expr = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .trim();

      // Remove trailing operator
      if (['+', '-', '*', '/', '%'].contains(expr[expr.length - 1])) {
        expr = expr.substring(0, expr.length - 1).trim();
      }

      final result = _evalExpression(expr);
      if (result != null) {
        _result = _formatNum(result);
        _display = _result;
        _expression = _result;
        _justEvaluated = true;
      }
    } catch (_) {}
  }

  // ── Full expression evaluator (respects * / before + -) ──────────────────
  double? _evalExpression(String expr) {
    // Tokenize
    final tokens = _tokenize(expr);
    if (tokens == null || tokens.isEmpty) return null;

    // First pass: handle * / %
    final pass1 = <dynamic>[];
    int i = 0;
    while (i < tokens.length) {
      final token = tokens[i];
      if (token == '*' || token == '/' || token == '%') {
        if (pass1.isEmpty || i + 1 >= tokens.length) return null;
        final left = pass1.removeLast() as double;
        final right = tokens[i + 1] as double;
        if (token == '*') {
          pass1.add(left * right);
        } else if (token == '/') {
          if (right == 0) return null;
          pass1.add(left / right);
        } else {
          pass1.add(left * right / 100);
        }
        i += 2;
      } else {
        pass1.add(token);
        i++;
      }
    }

    // Second pass: handle + -
    double result = pass1[0] as double;
    int j = 1;
    while (j < pass1.length) {
      final op = pass1[j] as String;
      final val = pass1[j + 1] as double;
      if (op == '+') {
        result += val;
      } else if (op == '-') {
        result -= val;
      }
      j += 2;
    }

    return result;
  }

  List<dynamic>? _tokenize(String expr) {
    final tokens = <dynamic>[];
    final buffer = StringBuffer();

    for (int i = 0; i < expr.length; i++) {
      final ch = expr[i];
      if (ch == ' ') continue;
      if ('+-*/%.'.contains(ch)) {
        if (buffer.isNotEmpty) {
          final num = double.tryParse(buffer.toString());
          if (num == null) return null;
          tokens.add(num);
          buffer.clear();
        }
        // Handle negative numbers at start or after operator
        if (ch == '-' &&
            (tokens.isEmpty ||
                tokens.last is String)) {
          buffer.write(ch);
        } else {
          tokens.add(ch);
        }
      } else {
        buffer.write(ch);
      }
    }

    if (buffer.isNotEmpty) {
      final num = double.tryParse(buffer.toString());
      if (num == null) return null;
      tokens.add(num);
    }

    return tokens;
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
      ['0', '.', '=', 'OK'],
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
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Display ─────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Expression (small, above)
                if (_display.isNotEmpty && _justEvaluated == false)
                  Text(
                    _display,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                      fontWeight: FontWeight.w300,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                // Result (big, below)
                Text(
                  _justEvaluated
                      ? _result
                      : (_display.isEmpty ? '0' : _display),
                  style: TextStyle(
                    fontSize: _justEvaluated ? 38 : 28,
                    fontWeight: _justEvaluated
                        ? FontWeight.w700
                        : FontWeight.w300,
                    letterSpacing: -1,
                    color: _justEvaluated
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Keys ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: keys.map((row) {
                return Row(
                  children: row.map((key) {
                    // Map display key to actual key
                    final actualKey = key == '−' ? '-' : key;

                    if (key == 'OK') {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // If not evaluated, evaluate first
                            if (!_justEvaluated) _evaluate();
                            final val = double.tryParse(_result.isEmpty
                                ? _display
                                : _result);
                            Navigator.pop(context, val);
                          },
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            height: 64,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: const Text('OK',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20)),
                          ),
                        ),
                      );
                    }

                    final isOp = ['+', '−', '×', '÷', '%'].contains(key);
                    final isEq = key == '=';
                    final isClear = key == 'C' || key == '⌫';
                    final isActive = _lastIsOperator &&
                        (key == '+' ||
                            key == '−' ||
                            key == '×' ||
                            key == '÷');

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onKey(actualKey),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          margin: const EdgeInsets.all(5),
                          height: 64,
                          decoration: BoxDecoration(
                            color: isEq
                                ? theme.colorScheme.primary
                                : isActive
                                    ? theme.colorScheme.primary
                                        .withOpacity(0.25)
                                    : isClear
                                        ? theme.colorScheme.error
                                            .withOpacity(0.15)
                                        : isOp
                                            ? theme.colorScheme.primary
                                                .withOpacity(0.12)
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
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          SizedBox(
              height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
