import 'package:flutter/material.dart';

import 'models.dart';
import 'settings.dart';
import 'theme.dart';

/// Белая карточка с мягкой тенью и тонкой рамкой.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.color,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2B2616),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: color ?? paletteOf(context).card,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: borderColor ?? paletteOf(context).line),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Шапка с названием компании: спокойная песочная плашка,
/// заметнее фона, но без блеска.
class CompanyHeader extends StatelessWidget {
  const CompanyHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final base = p.dark ? const Color(0xFF2A3135) : const Color(0xFFE3DFD0);
    final top = p.dark ? const Color(0xFF30383C) : const Color(0xFFEAE6D8);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, base],
        ),
        border: Border.all(color: p.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2B2616),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: p.ink,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 0.6,
                        color: muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Заголовок экрана: крупно, но не кричаще.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: paletteOf(context).ink,
        letterSpacing: -0.2,
      ),
    );
  }
}

/// Маленькая подпись над блоком: «СОТРУДНИКИ · 4».
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.7,
        color: muted,
      ),
    );
  }
}

/// Шкала 0–100: зелёная, жёлтая или красная в зависимости от результата.
class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key, required this.value, this.height = 6});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: (value / 100).clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: const Color(0xFFE6EBEF),
        color: toneForScore(value).bar,
      ),
    );
  }
}

/// Число результата на цветной подложке.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score, this.big = false});

  final double score;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final tone = toneForScore(score);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: big ? 14 : 10,
        vertical: big ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(big ? 14 : 10),
      ),
      child: Text(
        score.round().toString(),
        style: TextStyle(
          fontSize: big ? 28 : 16,
          fontWeight: FontWeight.w600,
          color: tone.fg,
        ),
      ),
    );
  }
}

/// Небольшая метка: «Фото», «Видео» и т.п.
class Tag extends StatelessWidget {
  const Tag({
    super.key,
    required this.text,
    this.icon,
    this.bg = const Color(0xFFEEF2F5),
    this.fg = const Color(0xFF3B4C5B),
  });

  final String text;
  final IconData? icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class KindChips extends StatelessWidget {
  const KindChips({super.key, required this.kinds});

  final Iterable<ReportKind> kinds;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final k in kinds) Tag(text: k.label, icon: k.icon),
      ],
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.user, this.size = 44});

  final AppUser user;
  final double size;

  static const _employeeColors = <List<Color>>[
    [Color(0xFFDDF1EE), Color(0xFF0A5A52)],
    [Color(0xFFFFF1D6), Color(0xFF8A4B00)],
    [Color(0xFFE9EEF2), Color(0xFF3B4C5B)],
    [Color(0xFFE8E1F7), Color(0xFF5B3FA0)],
  ];

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (user.role) {
      case Role.owner:
        bg = brandDark;
        fg = Colors.white;
      case Role.manager:
        bg = const Color(0xFF3B4C5B);
        fg = Colors.white;
      case Role.employee:
        final n = int.tryParse(user.id.substring(1)) ?? 0;
        final pair = _employeeColors[n % _employeeColors.length];
        bg = pair[0];
        fg = pair[1];
    }
    if (user.photo != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: bg,
        backgroundImage: MemoryImage(user.photo!),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bg,
      child: Text(
        user.name.characters.first,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
