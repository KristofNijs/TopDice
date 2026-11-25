import 'package:flutter/material.dart';

/// Kleurenpalet in casinostijl: het groen van de speeltafels.
class CasinoColors {
  CasinoColors._();

  /// Klassiek vilten tafelgroen van casinotafels.
  static const Color tableGreen = Color(0xFF35654D);

  /// Iets donkerder groen voor de app-balk.
  static const Color tableGreenDark = Color(0xFF274F3C);

  /// Goud voor knoppen en accenten, zoals fiches.
  static const Color gold = Color(0xFFD9B44A);

  /// Donkergroen voor tekst op gouden knoppen en accenten.
  static const Color goldInk = Color(0xFF1E3D2C);

  /// Bijna-wit, zoals een ivoorkleurige dobbelsteen.
  static const Color ivory = Color(0xFFFFF8E7);

  /// Achtergrondkleur van een dobbelsteen-face.
  static const Color dieFace = ivory;

  /// Tekstkleur van de dobbelsteenwaarde op [dieFace].
  static const Color dieValue = tableGreenDark;
}

/// Het casino-thema van de app: tafelgroene achtergrond op elk scherm,
/// met gouden accenten en voldoende contrast voor tekst en UI-elementen.
final ThemeData casinoTheme = _buildCasinoTheme();

ThemeData _buildCasinoTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: CasinoColors.tableGreen,
    brightness: Brightness.dark,
    primary: CasinoColors.gold,
    onPrimary: CasinoColors.goldInk,
    secondary: CasinoColors.gold,
    onSecondary: CasinoColors.goldInk,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: CasinoColors.tableGreen,
    appBarTheme: const AppBarTheme(
      backgroundColor: CasinoColors.tableGreenDark,
      foregroundColor: CasinoColors.ivory,
    ),
  );
}
