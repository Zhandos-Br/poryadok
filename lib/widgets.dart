import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';

/// Белая карточка со скруглением и тонкой рамкой.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Material(
      color: Colors.white,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: borderColor ?? lineColor),
          ),
          child: child,
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
        borderRadius: BorderRadius.circular(8),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bg,
      child: Text(
        user.name.characters.first,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
