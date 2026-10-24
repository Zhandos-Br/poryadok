import 'package:flutter/material.dart';

/// Цвета, которые зависят от светлой или тёмной темы.
class Palette {
  const Palette({
    required this.dark,
    required this.surface,
    required this.card,
    required this.line,
    required this.ink,
    required this.bubbleMine,
    required this.bubbleOther,
  });

  final bool dark;

  /// Фон экранов.
  final Color surface;

  /// Карточки, поля ввода, нижняя панель.
  final Color card;
  final Color line;

  /// Основной цвет текста.
  final Color ink;

  /// Пузырь своего сообщения и чужого.
  final Color bubbleMine;
  final Color bubbleOther;
}

const lightPalette = Palette(
  dark: false,
  surface: Color(0xFFF5F7F9),
  card: Colors.white,
  line: Color(0xFFE8ECF0),
  ink: Color(0xFF1B2733),
  bubbleMine: Color(0xFFD5F0E4),
  bubbleOther: Colors.white,
);

const darkPalette = Palette(
  dark: true,
  surface: Color(0xFF0F171D),
  card: Color(0xFF1A252D),
  line: Color(0xFF2B3843),
  ink: Color(0xFFE6EDF2),
  bubbleMine: Color(0xFF0B5D4B),
  bubbleOther: Color(0xFF202C33),
);

Palette paletteOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? darkPalette
        : lightPalette;

/// Размер текста во всём приложении.
enum TextSize { small, normal, large, huge }

extension TextSizeX on TextSize {
  String get label => switch (this) {
        TextSize.small => 'Мелкий',
        TextSize.normal => 'Обычный',
        TextSize.large => 'Крупный',
        TextSize.huge => 'Очень крупный',
      };

  double get scale => switch (this) {
        TextSize.small => 0.9,
        TextSize.normal => 1.0,
        TextSize.large => 1.15,
        TextSize.huge => 1.3,
      };
}

enum WallpaperPattern { none, dots, lines }

/// Обои чата. Для тёмной темы у каждых есть свой, более тёмный цвет.
class Wallpaper {
  const Wallpaper(
    this.name,
    this.light,
    this.dark, {
    this.pattern = WallpaperPattern.none,
  });

  final String name;
  final Color light;
  final Color dark;
  final WallpaperPattern pattern;
}

const wallpapers = <Wallpaper>[
  Wallpaper('Стандарт', Color(0xFFE9EFEC), Color(0xFF0B141A)),
  Wallpaper('Песок', Color(0xFFF3EBDD), Color(0xFF241F15)),
  Wallpaper('Небо', Color(0xFFE4EEF8), Color(0xFF111C27)),
  Wallpaper('Мята', Color(0xFFE0F1E8), Color(0xFF10211A)),
  Wallpaper('Сумерки', Color(0xFFCBD3E3), Color(0xFF1A2030)),
  Wallpaper(
    'Точки',
    Color(0xFFE9EFEC),
    Color(0xFF0B141A),
    pattern: WallpaperPattern.dots,
  ),
  Wallpaper(
    'Линии',
    Color(0xFFF3EBDD),
    Color(0xFF241F15),
    pattern: WallpaperPattern.lines,
  ),
];

/// Фон чата: цвет и при желании лёгкий узор.
class WallpaperBox extends StatelessWidget {
  const WallpaperBox({super.key, required this.index, this.child});

  final int index;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final w = wallpapers[index.clamp(0, wallpapers.length - 1)];
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? w.dark : w.light;
    final mark = dark ? const Color(0x14FFFFFF) : const Color(0x14000000);

    return Container(
      color: base,
      child: w.pattern == WallpaperPattern.none
          ? child
          : CustomPaint(
              painter: _PatternPainter(w.pattern, mark),
              child: child,
            ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter(this.pattern, this.color);

  final WallpaperPattern pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const step = 28.0;

    if (pattern == WallpaperPattern.dots) {
      paint.style = PaintingStyle.fill;
      for (var y = step / 2; y < size.height; y += step) {
        for (var x = step / 2; x < size.width; x += step) {
          canvas.drawCircle(Offset(x, y), 2, paint);
        }
      }
    } else if (pattern == WallpaperPattern.lines) {
      for (var x = -size.height; x < size.width; x += step) {
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x + size.height, 0),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.pattern != pattern || old.color != color;
}
