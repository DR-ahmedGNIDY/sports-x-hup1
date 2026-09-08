import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/store_theme.dart';

/// Formats a piastre amount for display.
///
/// The API speaks integer minor units end to end — see the backend's
/// `priceMinor` — so this is the one place the decimal point is introduced,
/// and it is introduced for the eye only. No arithmetic downstream of here
/// touches the formatted value.
String formatMoney(int minor, {required bool isArabic}) {
  final major = minor / 100;
  final formatter = NumberFormat.currency(
    locale: isArabic ? 'ar_EG' : 'en_EG',
    symbol: isArabic ? 'ج.م' : 'EGP',
    decimalDigits: 2,
  );
  return formatter.format(major);
}

/// A price, and the struck-through original when there is a discount.
///
/// Both halves are red when discounted, matching the reference storefront —
/// the greyed-out "was" price that most themes default to reads as disabled
/// rather than as a saving.
class MoneyText extends StatelessWidget {
  const MoneyText({
    super.key,
    required this.priceMinor,
    this.compareAtPriceMinor,
    this.align = TextAlign.center,
    this.fontSize = 13,
  });

  final int priceMinor;
  final int? compareAtPriceMinor;
  final TextAlign align;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final was = compareAtPriceMinor;
    final isDiscounted = was != null && was > priceMinor;
    final colour = isDiscounted
        ? StoreTheme.sale
        : Theme.of(context).colorScheme.onSurface;

    return Text.rich(
      TextSpan(
        children: [
          if (isDiscounted)
            TextSpan(
              text: '${formatMoney(was, isArabic: isArabic)}  ',
              style: TextStyle(
                fontSize: fontSize,
                color: colour,
                decoration: TextDecoration.lineThrough,
                // Without this the strike-through inherits the parent's
                // colour rather than the price's.
                decorationColor: colour,
              ),
            ),
          TextSpan(
            text: formatMoney(priceMinor, isArabic: isArabic),
            style: TextStyle(
              fontSize: fontSize,
              color: colour,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textAlign: align,
    );
  }
}
