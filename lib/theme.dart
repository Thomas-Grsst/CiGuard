import 'package:flutter/material.dart';

/// Un « style » : la palette de fond et de texte de toute l'app.
class Palette {
  const Palette({
    required this.id,
    required this.name,
    required this.dark,
    required this.bg,
    required this.surface,
    required this.raised,
    required this.border,
    required this.divider,
    required this.text,
    required this.soft,
    required this.muted,
  });

  final String id;
  final String name;
  final bool dark;
  final Color bg;
  final Color surface;
  final Color raised;
  final Color border;
  final Color divider;
  final Color text;
  final Color soft;
  final Color muted;
}

const palettes = <Palette>[
  Palette(
    id: 'graphite', name: 'Graphite', dark: true,
    bg: Color(0xFF0D0E10), surface: Color(0xFF16181B), raised: Color(0xFF1F2226),
    border: Color(0xFF26292E), divider: Color(0xFF1F2226),
    text: Color(0xFFEDEEF0), soft: Color(0xFFC4C8CE), muted: Color(0xFF9A9FA6),
  ),
  Palette(
    id: 'amoled', name: 'Noir absolu', dark: true,
    bg: Color(0xFF000000), surface: Color(0xFF0F0F10), raised: Color(0xFF19191B),
    border: Color(0xFF242427), divider: Color(0xFF19191B),
    text: Color(0xFFF2F2F3), soft: Color(0xFFC8C8CC), muted: Color(0xFF9B9BA1),
  ),
  Palette(
    id: 'minuit', name: 'Minuit', dark: true,
    bg: Color(0xFF0A0F1E), surface: Color(0xFF111830), raised: Color(0xFF19223F),
    border: Color(0xFF263052), divider: Color(0xFF19223F),
    text: Color(0xFFE8ECF8), soft: Color(0xFFC0C8E0), muted: Color(0xFF8F9AB8),
  ),
  Palette(
    id: 'foret', name: 'Forêt', dark: true,
    bg: Color(0xFF0A120E), surface: Color(0xFF111C17), raised: Color(0xFF192620),
    border: Color(0xFF25342C), divider: Color(0xFF192620),
    text: Color(0xFFE6EFEA), soft: Color(0xFFBFD0C7), muted: Color(0xFF8FA399),
  ),
  Palette(
    id: 'prune', name: 'Prune', dark: true,
    bg: Color(0xFF130C16), surface: Color(0xFF1D1421), raised: Color(0xFF281C2D),
    border: Color(0xFF36283C), divider: Color(0xFF281C2D),
    text: Color(0xFFF0E8F2), soft: Color(0xFFD2C3D6), muted: Color(0xFFA595AA),
  ),
  Palette(
    id: 'moka', name: 'Moka', dark: true,
    bg: Color(0xFF14100C), surface: Color(0xFF1E1813), raised: Color(0xFF29211A),
    border: Color(0xFF382C23), divider: Color(0xFF29211A),
    text: Color(0xFFF2EBE6), soft: Color(0xFFD6C8BE), muted: Color(0xFFA89889),
  ),
  Palette(
    id: 'ocean', name: 'Océan', dark: true,
    bg: Color(0xFF071316), surface: Color(0xFF0E1D21), raised: Color(0xFF15282D),
    border: Color(0xFF20373D), divider: Color(0xFF15282D),
    text: Color(0xFFE4F1F2), soft: Color(0xFFBBD3D6), muted: Color(0xFF86A4A8),
  ),
  Palette(
    id: 'bordeaux', name: 'Bordeaux', dark: true,
    bg: Color(0xFF150B0D), surface: Color(0xFF201214), raised: Color(0xFF2B191C),
    border: Color(0xFF3B2428), divider: Color(0xFF2B191C),
    text: Color(0xFFF3E8E9), soft: Color(0xFFD9C3C6), muted: Color(0xFFAC9397),
  ),
  Palette(
    id: 'clair', name: 'Clair', dark: false,
    bg: Color(0xFFF4F5F7), surface: Color(0xFFFFFFFF), raised: Color(0xFFECEEF1),
    border: Color(0xFFDADDE2), divider: Color(0xFFEAECEF),
    text: Color(0xFF15171A), soft: Color(0xFF3A3F46), muted: Color(0xFF5E646C),
  ),
  Palette(
    id: 'sable', name: 'Sable', dark: false,
    bg: Color(0xFFF5F0E8), surface: Color(0xFFFFFCF7), raised: Color(0xFFEDE5D9),
    border: Color(0xFFDDD2C2), divider: Color(0xFFEBE3D7),
    text: Color(0xFF1E1A16), soft: Color(0xFF463E35), muted: Color(0xFF6B6154),
  ),
];

class AccentSwatch {
  const AccentSwatch(this.name, this.color);
  final String name;
  final Color color;
}

const accents = <AccentSwatch>[
  AccentSwatch('Bleu', Color(0xFF8FA8FF)),
  AccentSwatch('Ciel', Color(0xFF7CC4FF)),
  AccentSwatch('Turquoise', Color(0xFF5FD3D8)),
  AccentSwatch('Menthe', Color(0xFF7FDCB4)),
  AccentSwatch('Émeraude', Color(0xFF5FD08A)),
  AccentSwatch('Sauge', Color(0xFFA9C79A)),
  AccentSwatch('Citron', Color(0xFFE6E07A)),
  AccentSwatch('Ambre', Color(0xFFF2B36B)),
  AccentSwatch('Pêche', Color(0xFFFFB899)),
  AccentSwatch('Corail', Color(0xFFF2907A)),
  AccentSwatch('Rubis', Color(0xFFFF7A8A)),
  AccentSwatch('Rose', Color(0xFFF28FB0)),
  AccentSwatch('Lilas', Color(0xFFE0A6F0)),
  AccentSwatch('Violet', Color(0xFFB79CFF)),
  AccentSwatch('Lavande', Color(0xFFC9B6FF)),
  AccentSwatch('Glacier', Color(0xFFD7DCE3)),
];

/// Sur un fond clair, un accent pastel serait illisible : on l'assombrit.
Color forLight(Color c) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness(hsl.lightness.clamp(0.0, 0.40))
      .withSaturation((hsl.saturation * 0.9).clamp(0.0, 1.0))
      .toColor();
}

class Cg extends ThemeExtension<Cg> {
  Cg(this.p, this.accentRaw)
      : accent = p.dark ? accentRaw : forLight(accentRaw),
        danger = p.dark ? const Color(0xFFF2A0A0) : const Color(0xFFB3261E),
        dangerBorder = p.dark ? const Color(0xFF4A2A2C) : const Color(0xFFF0C4C0),
        warn = p.dark ? const Color(0xFFF2B36B) : const Color(0xFF9A5B00),
        bad = p.dark ? const Color(0xFFF28B82) : const Color(0xFFC5221F);

  final Palette p;
  final Color accentRaw;
  final Color accent;
  final Color danger;
  final Color dangerBorder;
  final Color warn;
  final Color bad;

  Color get onAccent =>
      accent.computeLuminance() > 0.4 ? const Color(0xFF0D0E10) : Colors.white;

  /// Couleur d'un pictogramme (avatar) selon le style courant.
  Color tint(Color c) => p.dark ? c : forLight(c);

  @override
  Cg copyWith() => this;

  @override
  Cg lerp(Cg? other, double t) => t < 0.5 || other == null ? this : other;
}

extension CgContext on BuildContext {
  Cg get cg => Theme.of(this).extension<Cg>()!;
}

TextStyle geist(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color? color,
  bool mono = false,
  double? spacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: mono ? 'GeistMono' : 'Geist',
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    color: color,
    letterSpacing: spacing == null ? null : spacing * size,
    height: height,
  );
}

ThemeData buildTheme(Palette p, Color accentRaw) {
  final cg = Cg(p, accentRaw);
  final brightness = p.dark ? Brightness.dark : Brightness.light;
  final scheme = ColorScheme.fromSeed(seedColor: cg.accent, brightness: brightness).copyWith(
    primary: cg.accent,
    onPrimary: cg.onAccent,
    surface: p.surface,
    onSurface: p.text,
    error: cg.danger,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    fontFamily: 'Geist',
    splashColor: cg.accent.withValues(alpha: 0.10),
    highlightColor: cg.accent.withValues(alpha: 0.06),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: cg.accent,
      selectionColor: cg.accent.withValues(alpha: 0.35),
      selectionHandleColor: cg.accent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.border),
      ),
      titleTextStyle: geist(19, weight: FontWeight.w600, color: p.text),
      contentTextStyle: geist(15, color: p.soft, height: 1.45),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: p.border,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.raised,
      contentTextStyle: geist(14, color: p.text),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.border),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: cg.accent,
      inactiveTrackColor: p.border,
      thumbColor: cg.accent,
      overlayColor: cg.accent.withValues(alpha: 0.15),
      trackHeight: 4,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cg.accent,
        textStyle: geist(15, weight: FontWeight.w600),
      ),
    ),
    extensions: [cg],
  );
}
