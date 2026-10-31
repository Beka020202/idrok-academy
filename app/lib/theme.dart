// ============================================================================
//  Idrok Academy — dizayn tizimi / дизайн-система
//  Ranglar, shriftlar, oraliqlar, burchaklar, soyalar, harakat (animatsiya).
//  Цвета, типографика, отступы, радиусы, тени, движение.
//
//  Brend: faqat to‘q sariq, sariq, qora, oq (+ ular orasidagi neytral kulranglar).
//  Бренд: только оранжевый, жёлтый, чёрный, белый (+ нейтральные серые между ними).
// ============================================================================

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------- shriftlar / шрифты
const String kBody = 'Manrope';
const String kMono = 'JetBrainsMono';
const String kDisplay = 'Unbounded'; // faqat brend yozuvi uchun / только для логотипа

const FontWeight w8 = FontWeight.w800;
const FontWeight w7 = FontWeight.w700;
const FontWeight w6 = FontWeight.w600;
const FontWeight w4 = FontWeight.w400;

const Color kWhite = Color(0xFFFFFFFF);
const Color kBlack = Color(0xFF111111);
const Color kOrange = Color(0xFFF86400);
const Color kYellow = Color(0xFFFFC200);

// ---------------------------------------------------------------- ranglar / цвета
/// Har bir mavzu alohida loyihalangan (shunchaki teskari emas).
/// Каждая тема спроектирована отдельно (не просто инверсия).
class AppColors {
  final bool isDark;

  // Fon va qatlamlar / фон и слои
  final Color bg, glowA, glowB;
  final Color surface, surfaceAlt, elevated;
  final Color glass, glassEdge, hairline, hairlineStrong;

  // Matn / текст
  final Color text, text2, text3;

  // Aksentlar / акценты
  final Color accent, accentHi, accentText, accentSoft;
  final Color yellow, yellowHi, yellowText, yellowSoft;
  final Color danger, dangerSoft;

  // Kod / код
  final Color codeBg, codeBar, codeFg, codeMuted;

  final Color shadow, scrim;

  const AppColors({
    required this.isDark,
    required this.bg,
    required this.glowA,
    required this.glowB,
    required this.surface,
    required this.surfaceAlt,
    required this.elevated,
    required this.glass,
    required this.glassEdge,
    required this.hairline,
    required this.hairlineStrong,
    required this.text,
    required this.text2,
    required this.text3,
    required this.accent,
    required this.accentHi,
    required this.accentText,
    required this.accentSoft,
    required this.yellow,
    required this.yellowHi,
    required this.yellowText,
    required this.yellowSoft,
    required this.danger,
    required this.dangerSoft,
    required this.codeBg,
    required this.codeBar,
    required this.codeFg,
    required this.codeMuted,
    required this.shadow,
    required this.scrim,
  });

  /// Asosiy tugma gradienti / градиент основной кнопки.
  LinearGradient get accentGradient =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accentHi, accent]);

  LinearGradient get yellowGradient =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [yellowHi, yellow]);

  /// Qahramon kartasi (yorqin to‘q sariq) / карточка-герой.
  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFFFF8A24), Color(0xFFE85300)]
            : const [Color(0xFFFF8A1F), Color(0xFFF25A00)],
      );
}

/// Yorug‘ mavzu: iliq oq, yumshoq soyalar, nozik chegaralar.
/// Светлая тема: тёплый белый, мягкие тени, тонкие границы.
const AppColors kLight = AppColors(
  isDark: false,
  bg: Color(0xFFF6F4F1),
  glowA: Color(0x1AF86400),
  glowB: Color(0x22FFC200),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFF0EDE8),
  elevated: Color(0xFFFFFFFF),
  glass: Color(0xC7FFFFFF),
  glassEdge: Color(0xE6FFFFFF),
  hairline: Color(0x14000000),
  hairlineStrong: Color(0x24000000),
  text: Color(0xFF111111),
  text2: Color(0xFF6B6863),
  text3: Color(0xFFA29E98),
  accent: Color(0xFFF86400),
  accentHi: Color(0xFFFF9035),
  accentText: Color(0xFFD35400),
  accentSoft: Color(0xFFFFEEDF),
  yellow: Color(0xFFFFBE00),
  yellowHi: Color(0xFFFFD84D),
  yellowText: Color(0xFF7A5700),
  yellowSoft: Color(0xFFFFF4CC),
  danger: Color(0xFFC24A00),
  dangerSoft: Color(0xFFFFE4D2),
  codeBg: Color(0xFF151413),
  codeBar: Color(0xFF1F1D1B),
  codeFg: Color(0xFFF4EFE8),
  codeMuted: Color(0xFF8C857C),
  shadow: Color(0x1A1A120A),
  scrim: Color(0x66000000),
);

/// Qorong‘i mavzu: chuqur qora, qatlamli sirtlar, yumshoq yorug‘lik.
/// Тёмная тема: глубокий чёрный, слоистые поверхности, мягкое свечение.
const AppColors kDark = AppColors(
  isDark: true,
  bg: Color(0xFF09090A),
  glowA: Color(0x1FF86400),
  glowB: Color(0x10FFC200),
  surface: Color(0xFF151517),
  surfaceAlt: Color(0xFF1E1E21),
  elevated: Color(0xFF242428),
  glass: Color(0xA6161618),
  glassEdge: Color(0x24FFFFFF),
  hairline: Color(0x14FFFFFF),
  hairlineStrong: Color(0x26FFFFFF),
  text: Color(0xFFF5F5F7),
  text2: Color(0xFFA3A3A8),
  text3: Color(0xFF6C6C72),
  accent: Color(0xFFFF7414),
  accentHi: Color(0xFFFF9A47),
  accentText: Color(0xFFFF9447),
  accentSoft: Color(0x29FF7414),
  yellow: Color(0xFFFFC21A),
  yellowHi: Color(0xFFFFDA66),
  yellowText: Color(0xFFFFD25C),
  yellowSoft: Color(0x24FFC21A),
  danger: Color(0xFFFF8A45),
  dangerSoft: Color(0x24FF6A00),
  codeBg: Color(0xFF0D0D0E),
  codeBar: Color(0xFF17171A),
  codeFg: Color(0xFFF4EFE8),
  codeMuted: Color(0xFF77726B),
  shadow: Color(0x80000000),
  scrim: Color(0x99000000),
);

// ---------------------------------------------------------------- shrift o‘lchamlari / типографика
/// iOS uslubidagi ierarxiya / иерархия в стиле iOS.
class AppType {
  static const largeTitle =
      TextStyle(fontFamily: kBody, fontSize: 32, height: 1.18, fontWeight: w8, letterSpacing: -0.9);
  static const title1 = TextStyle(fontFamily: kBody, fontSize: 26, height: 1.2, fontWeight: w8, letterSpacing: -0.6);
  static const title2 = TextStyle(fontFamily: kBody, fontSize: 21, height: 1.25, fontWeight: w8, letterSpacing: -0.4);
  static const title3 = TextStyle(fontFamily: kBody, fontSize: 18, height: 1.3, fontWeight: w8, letterSpacing: -0.3);
  static const headline = TextStyle(fontFamily: kBody, fontSize: 16, height: 1.35, fontWeight: w7, letterSpacing: -0.2);
  static const body = TextStyle(fontFamily: kBody, fontSize: 16, height: 1.55, fontWeight: w4, letterSpacing: -0.1);
  static const bodyStrong = TextStyle(fontFamily: kBody, fontSize: 16, height: 1.45, fontWeight: w6, letterSpacing: -0.1);
  static const callout = TextStyle(fontFamily: kBody, fontSize: 15, height: 1.4, fontWeight: w6, letterSpacing: -0.1);
  static const subhead = TextStyle(fontFamily: kBody, fontSize: 14, height: 1.4, fontWeight: w6);
  static const footnote = TextStyle(fontFamily: kBody, fontSize: 13, height: 1.35, fontWeight: w6);
  static const caption = TextStyle(fontFamily: kBody, fontSize: 12, height: 1.3, fontWeight: w7, letterSpacing: 0.1);
  static const overline = TextStyle(fontFamily: kBody, fontSize: 11, height: 1.2, fontWeight: w8, letterSpacing: 1.1);
  static const button = TextStyle(fontFamily: kBody, fontSize: 16, height: 1.2, fontWeight: w8, letterSpacing: -0.1);
  static const number = TextStyle(fontFamily: kBody, fontSize: 22, height: 1.1, fontWeight: w8, letterSpacing: -0.5);
  static const mono = TextStyle(fontFamily: kMono, fontSize: 14, height: 1.55, fontWeight: w4);
  static const monoStrong = TextStyle(fontFamily: kMono, fontSize: 15, height: 1.4, fontWeight: w7);
  static const brand = TextStyle(fontFamily: kBody, fontSize: 17, height: 1.15, fontWeight: w8, letterSpacing: -0.4);
}

// ---------------------------------------------------------------- oraliqlar va burchaklar / отступы и радиусы
/// 4-pikselli to‘r / сетка 4 px.
class S {
  static const double x1 = 4, x2 = 8, x3 = 12, x4 = 16, x5 = 20, x6 = 24, x7 = 28, x8 = 32, x10 = 40, x12 = 48;
  /// Ekran chetlari / поля экрана.
  static const double page = 20;
  /// Suzuvchi menyu uchun pastki joy / место под плавающее меню.
  static const double navSpace = 112;
}

class R {
  static const double xs = 8, sm = 12, md = 16, lg = 20, xl = 24, xxl = 28, pill = 999;
  static BorderRadius all(double r) => BorderRadius.circular(r);
}

// ---------------------------------------------------------------- soyalar va yorug‘lik / тени и свечение
class Shadows {
  /// Karta soyasi / тень карточки.
  static List<BoxShadow> card(AppColors c) => c.isDark
      ? const [BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 14), spreadRadius: -10)]
      : const [
          BoxShadow(color: Color(0x121A120A), blurRadius: 30, offset: Offset(0, 12), spreadRadius: -8),
          BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
        ];

  /// Yengil ko‘tarilish / лёгкий подъём (кнопки-иконки, таблетки).
  static List<BoxShadow> soft(AppColors c) => c.isDark
      ? const [BoxShadow(color: Color(0x4D000000), blurRadius: 16, offset: Offset(0, 6), spreadRadius: -6)]
      : const [BoxShadow(color: Color(0x141A120A), blurRadius: 16, offset: Offset(0, 6), spreadRadius: -6)];

  /// Nur sochuvchi tugma / «светящаяся» кнопка. strength: 0..1
  static List<BoxShadow> glow(Color color, AppColors c, {double strength = 1}) {
    final a = ((c.isDark ? 0x80 : 0x5C) * strength).round().clamp(0, 255).toInt();
    return [
      BoxShadow(color: color.withAlpha(a), blurRadius: 26, offset: const Offset(0, 10), spreadRadius: -8),
      BoxShadow(color: color.withAlpha((a * 0.5).round()), blurRadius: 8, offset: const Offset(0, 2), spreadRadius: -2),
    ];
  }
}

// ---------------------------------------------------------------- harakat / движение
class Motion {
  static const press = Duration(milliseconds: 110);
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);
  static const page = Duration(milliseconds: 380);

  /// Standart egri chiziq (iOS’ga yaqin) / стандартная кривая (близко к iOS).
  static const Curve curve = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Curve inOut = Curves.easeInOutCubic;
  static const Curve pop = Curves.easeOutBack;

  /// Qurilmada "harakatni kamaytirish" yoqilganmi / включено ли «уменьшение движения».
  static bool reduced(BuildContext context) => MediaQuery.disableAnimationsOf(context);

  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}

// ---------------------------------------------------------------- yordamchilar / помощники
/// "#E8622C" -> Color
Color hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
}

/// Rangli fon ustidagi matn: oq (juda och fonda — qora).
/// Текст на цветном фоне: белый (на очень светлом — чёрный).
Color onColor(Color bg) => bg.computeLuminance() > 0.75 ? kBlack : kWhite;

/// Oq yozuvga yengil soya — sariq/to‘q sariq ustida o‘qilishi uchun.
const List<Shadow> kTextShadow = [Shadow(color: Color(0x4D000000), blurRadius: 4, offset: Offset(0, 1))];

ThemeData buildTheme(AppColors c) {
  final scheme = ColorScheme.fromSeed(
    seedColor: c.accent,
    brightness: c.isDark ? Brightness.dark : Brightness.light,
  ).copyWith(
    primary: c.accent,
    onPrimary: kWhite,
    secondary: c.yellow,
    onSecondary: kWhite,
    surface: c.surface,
    onSurface: c.text,
    surfaceTint: Colors.transparent,
    outline: c.hairlineStrong,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kBody,
    scaffoldBackgroundColor: c.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    hoverColor: c.hairline,
    focusColor: c.accentSoft,
    dividerColor: c.hairline,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accent.withAlpha(0x55),
      selectionHandleColor: c.accent,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: c.isDark ? c.elevated : kBlack, borderRadius: R.all(R.sm)),
      textStyle: AppType.footnote.copyWith(color: kWhite),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
