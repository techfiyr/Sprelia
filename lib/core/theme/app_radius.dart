import 'package:flutter/widgets.dart';

/// Corner radius tokens. Values satisfy both `doc/BRAND.md` §4 (cards 16–20,
/// buttons 14–18, inputs 12–16) and `doc/DESIGN_SYSTEM.md` §5.
abstract final class AppRadius {
  static const double small = 8;
  static const double input = 12;
  static const double button = 16;
  static const double card = 16;
  static const double cardLarge = 20;
  static const double sheet = 24;

  static const smallAll = BorderRadius.all(Radius.circular(small));
  static const inputAll = BorderRadius.all(Radius.circular(input));
  static const buttonAll = BorderRadius.all(Radius.circular(button));
  static const cardAll = BorderRadius.all(Radius.circular(card));
  static const cardLargeAll = BorderRadius.all(Radius.circular(cardLarge));
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));
}
