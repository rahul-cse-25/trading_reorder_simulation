import 'package:flutter/material.dart';
import '../../../../core/utils/price_formatter.dart';
import 'app_text.dart';

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
    return AppText(
      AppPriceFormatter.format(price),
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
    );
  }
}
