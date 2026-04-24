import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PriceText extends StatelessWidget {
  final double price;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const PriceText({
    super.key,
    required this.price,
    this.fontSize,
    this.fontWeight,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Text(
      formatter.format(price),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.bold,
        color: color,
      ),
    );
  }
}
