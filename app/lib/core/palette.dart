import 'package:flutter/material.dart';

import 'l10n.dart';

class NamedColor {
  const NamedColor(this.hex, this.pl, this.en);
  final String hex;
  final String pl;
  final String en;

  Color get color => Palette.parse(hex);
  String get name => tr(pl, en);
}

class Palette {
  Palette._();

  /// 16 kolorów wydarzeń (z prototypu "Add Event"). Ta sama paleta w obu motywach.
  static const eventColors = <NamedColor>[
    NamedColor('#F9A8A0', 'Łosoś', 'Salmon'),
    NamedColor('#FDD5B8', 'Brzoskwinia', 'Peach'),
    NamedColor('#E0EEC6', 'Limonka', 'Lime'),
    NamedColor('#B5E8D5', 'Mięta', 'Mint'),
    NamedColor('#C5CAE9', 'Lawenda', 'Lavender'),
    NamedColor('#F0CFF2', 'Liliowy', 'Lilac'),
    NamedColor('#FF9AA2', 'Róż', 'Rose'),
    NamedColor('#FFAB40', 'Pomarańcz', 'Orange'),
    NamedColor('#B39DBA', 'Śliwka', 'Plum'),
    NamedColor('#77DD77', 'Zieleń', 'Green'),
    NamedColor('#87CEEB', 'Niebo', 'Sky'),
    NamedColor('#F49AC2', 'Malina', 'Raspberry'),
    NamedColor('#C9A0DC', 'Fiolet', 'Violet'),
    NamedColor('#FFD1DC', 'Pudrowy', 'Powder'),
    NamedColor('#A9C4CC', 'Stal', 'Steel'),
    NamedColor('#FDFD96', 'Cytryna', 'Lemon'),
  ];

  /// 20 kolorów akcentu aplikacji (prototyp "Theme Color").
  static const accentColors = <NamedColor>[
    NamedColor('#4FC3F7', 'Błękit', 'Sky Blue'),
    NamedColor('#FF8FB1', 'Róż', 'Pink'),
    NamedColor('#9FA8DA', 'Lawenda', 'Lavender'),
    NamedColor('#80CBC4', 'Mięta', 'Mint'),
    NamedColor('#F9A8A0', 'Łosoś', 'Salmon'),
    NamedColor('#FFCC80', 'Brzoskwinia', 'Peach'),
    NamedColor('#C5E1A5', 'Limonka', 'Lime'),
    NamedColor('#CE93D8', 'Orchidea', 'Orchid'),
    NamedColor('#FF8A80', 'Koral', 'Coral'),
    NamedColor('#FFAB40', 'Pomarańcz', 'Orange'),
    NamedColor('#B39DBA', 'Śliwka', 'Plum'),
    NamedColor('#66BB6A', 'Zieleń', 'Green'),
    NamedColor('#64B5F6', 'Niebo', 'Azure'),
    NamedColor('#F48FB1', 'Malina', 'Raspberry'),
    NamedColor('#BA68C8', 'Fiolet', 'Violet'),
    NamedColor('#90A4AE', 'Stal', 'Steel'),
    NamedColor('#FFD54F', 'Słońce', 'Sunshine'),
    NamedColor('#A5D6A7', 'Szałwia', 'Sage'),
    NamedColor('#B0BEC5', 'Mgła', 'Mist'),
    NamedColor('#4DD0E1', 'Turkus', 'Turquoise'),
  ];

  static const defaultAccent = '#4FC3F7';
  static const defaultEventColor = '#87CEEB';
  static const defaultGroupColor = '#F49AC2';

  static Color parse(String hex) {
    final value = hex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }

  static String toHex(Color c) {
    final argb = c.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static NamedColor? findAccent(String hex) {
    for (final c in accentColors) {
      if (c.hex.toUpperCase() == hex.toUpperCase()) return c;
    }
    return null;
  }

  /// Czarny lub biały tekst zależnie od jasności tła (dostępność, sekcja 10.4).
  static Color onColor(Color background) =>
      background.computeLuminance() > 0.45 ? const Color(0xFF1B1B1F) : Colors.white;

  /// Kolor o zmienionej jasności (HSL) — do czytelnego tekstu na pastelowym tle.
  static Color withLightness(Color c, double lightness) =>
      HSLColor.fromColor(c).withLightness(lightness.clamp(0.0, 1.0)).toColor();

  /// Kolory miniatury wydarzenia: tło półprzezroczyste, tekst przyciemniony/rozjaśniony dla kontrastu.
  static (Color background, Color foreground) chip(Color color, Brightness brightness) {
    final hsl = HSLColor.fromColor(color);
    if (brightness == Brightness.dark) {
      return (color.withValues(alpha: 0.28), hsl.withLightness(0.82).withSaturation((hsl.saturation + 0.1).clamp(0, 1)).toColor());
    }
    return (color.withValues(alpha: 0.32), hsl.withLightness(0.22).withSaturation((hsl.saturation * 0.85).clamp(0, 1)).toColor());
  }

  /// Kolor z identyfikatora — dla avatarów bez zdjęcia.
  static Color fromId(String id) {
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return eventColors[hash % eventColors.length].color;
  }
}
