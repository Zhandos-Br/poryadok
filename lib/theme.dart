import 'package:flutter/material.dart';

const brand = Color(0xFF0E6F66);
const brandDark = Color(0xFF0A5A52);
const brandSoft = Color(0xFFDDF1EE);
const surface = Color(0xFFF5F7F9);
const ink = Color(0xFF1B2733);
const muted = Color(0xFF5E6E7D);
const lineColor = Color(0xFFE8ECF0);
const okColor = Color(0xFF0B6B3F);
const warnColor = Color(0xFF8A4B00);
const badColor = Color(0xFFA3261B);

/// Набор цветов для оценки: шкала, фон метки и цвет текста.
class Tone {
  const Tone({required this.bar, required this.bg, required this.fg});

  final Color bar;
  final Color bg;
  final Color fg;
}

const toneGood = Tone(
  bar: Color(0xFF1F9D6B),
  bg: Color(0xFFE3F5EC),
  fg: Color(0xFF0B6B3F),
);
const toneMid = Tone(
  bar: Color(0xFFE2A21B),
  bg: Color(0xFFFFF1D6),
  fg: Color(0xFF8A4B00),
);
const toneBad = Tone(
  bar: Color(0xFFD64545),
  bg: Color(0xFFFDE8E6),
  fg: Color(0xFFA3261B),
);

/// Хорошо (зелёный), средне (жёлтый), плохо (красный).
/// Один и тот же порог для рейтинга, шкал и процентов в календаре.
Tone toneForScore(num score) {
  if (score >= 85) return toneGood;
  if (score >= 65) return toneMid;
  return toneBad;
}

String verdictForScore(num score) {
  if (score >= 85) return 'Отличный результат';
  if (score >= 65) return 'Хороший результат';
  return 'Нужно внимание';
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: brand),
  );
  return base.copyWith(
    scaffoldBackgroundColor: surface,
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: brandSoft,
      height: 66,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
