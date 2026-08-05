part of '../add_expense_screen.dart';

class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _BalanceRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight:
                bold ? FontWeight.w700 : FontWeight.w400)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
