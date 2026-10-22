import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../rating.dart';
import '../theme.dart';
import '../widgets.dart';

/// Рейтинг сотрудника по 100 баллам с разбивкой.
/// Один и тот же экран для самого сотрудника («Мой рейтинг»)
/// и для руководителя с собственником («Профиль сотрудника»).
/// Шкалы зелёные, жёлтые или красные в зависимости от результата.
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
    final tone = toneForScore(r.total);

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        ScreenTitle(isMe ? 'Мой рейтинг' : user.name),
        if (!isMe)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              user.position,
              style: const TextStyle(fontSize: 13, color: muted),
            ),
          ),
        const SizedBox(height: 16),
        Panel(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (r.total / 100).clamp(0.0, 1.0),
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFFE6EBEF),
                      color: tone.bar,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            r.total.round().toString(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: tone.fg,
                            ),
                          ),
                          const Text(
                            'из 100',
                            style: TextStyle(fontSize: 12, color: muted),
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
                    Tag(text: verdictForScore(r.total), bg: tone.bg, fg: tone.fg),
                    const SizedBox(height: 8),
                    const Text(
                      'Пересчитывается каждый день',
                      style: TextStyle(fontSize: 12.5, color: muted, height: 1.4),
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
            color: brandSoft,
            borderColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Как поднять рейтинг',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: brandDark,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Закрывайте задачи до указанного срока: это половина рейтинга.',
                  style: TextStyle(fontSize: 13, color: brandDark, height: 1.4),
                ),
                SizedBox(height: 6),
                Text(
                  'Сдавайте всё, что просит задача: фото, видео, голос или текст.',
                  style: TextStyle(fontSize: 13, color: brandDark, height: 1.4),
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
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.max});

  final String label;
  final double value;
  final double max;

  @override
  Widget build(BuildContext context) {
    final percent = max == 0 ? 0.0 : value / max * 100;
    final tone = toneForScore(percent);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 14)),
              ),
              Text(
                '${value.round()} / ${max.round()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tone.fg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ScoreBar(value: percent, height: 8),
        ],
      ),
    );
  }
}
