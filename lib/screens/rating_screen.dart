import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../rating.dart';
import '../theme.dart';
import '../widgets.dart';

/// Рейтинг сотрудника по 100 баллам с разбивкой.
/// Один и тот же экран для самого сотрудника («Мой рейтинг»)
/// и для руководителя с собственником («Профиль сотрудника»).
class RatingScreen extends StatelessWidget {
  const RatingScreen({super.key, required this.userId, this.embedded = false});

  final String userId;

  /// true: показывается как вкладка, без собственной панели сверху.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.userById(userId);
    final r = state.ratingFor(userId);
    final isMe = userId == state.me.id;

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          isMe ? 'Мой рейтинг' : user.name,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        if (!isMe)
          Text(user.position, style: const TextStyle(color: muted)),
        const SizedBox(height: 16),
        Panel(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                width: 124,
                height: 124,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (r.total / 100).clamp(0.0, 1.0),
                      strokeWidth: 12,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFFDDE5EA),
                      color: brand,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            r.total.round().toString(),
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'из 100',
                            style: TextStyle(fontSize: 13, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tag(
                      text: _verdict(r.total),
                      bg: r.total >= 85
                          ? const Color(0xFFDDF5E7)
                          : r.total >= 65
                              ? const Color(0xFFFFF1D6)
                              : const Color(0xFFFDE8E6),
                      fg: r.total >= 85
                          ? okColor
                          : r.total >= 65
                              ? warnColor
                              : badColor,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Пересчитывается каждый день',
                      style: TextStyle(fontSize: 13, color: muted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Из чего складывается рейтинг',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              _Bar(
                label: 'Выполнено в срок',
                value: r.onTime,
                max: RatingBreakdown.maxOnTime,
              ),
              _Bar(
                label: 'Полнота отчётов',
                value: r.completeness,
                max: RatingBreakdown.maxCompleteness,
              ),
              _Bar(
                label: 'Качество (оценки руководителя)',
                value: r.quality,
                max: RatingBreakdown.maxQuality,
              ),
              _Bar(
                label: 'Дисциплина',
                value: r.discipline,
                max: RatingBreakdown.maxDiscipline,
              ),
            ],
          ),
        ),
        if (isMe) ...[
          const SizedBox(height: 14),
          const Panel(
            borderColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Как поднять рейтинг',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: brandDark,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Закрывайте задачи до указанного срока: это половина рейтинга.',
                  style: TextStyle(color: brandDark, height: 1.4),
                ),
                SizedBox(height: 6),
                Text(
                  'Сдавайте всё, что просит задача: фото, видео, голос или текст.',
                  style: TextStyle(color: brandDark, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    if (embedded) return SafeArea(child: content);
    return Scaffold(appBar: AppBar(), body: content);
  }

  String _verdict(double total) {
    if (total >= 85) return 'Отличный результат';
    if (total >= 65) return 'Хороший результат';
    return 'Нужно внимание';
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.max});

  final String label;
  final double value;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
              Text(
                '${value.round()} / ${max.round()}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / max).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFDDE5EA),
              color: brand,
            ),
          ),
        ],
      ),
    );
  }
}
