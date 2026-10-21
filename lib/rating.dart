import 'models.dart';

/// Рейтинг сотрудника по 100-балльной шкале:
/// 50 — выполнено в срок, 20 — полнота отчётов,
/// 20 — качество (оценки руководителя), 10 — дисциплина.
class RatingBreakdown {
  const RatingBreakdown({
    required this.onTime,
    required this.completeness,
    required this.quality,
    required this.discipline,
  });

  static const zero = RatingBreakdown(
    onTime: 0,
    completeness: 0,
    quality: 0,
    discipline: 0,
  );

  static const maxOnTime = 50.0;
  static const maxCompleteness = 20.0;
  static const maxQuality = 20.0;
  static const maxDiscipline = 10.0;

  final double onTime;
  final double completeness;
  final double quality;
  final double discipline;

  double get total => onTime + completeness + quality + discipline;
}

/// Считает рейтинг по задачам сотрудника.
///
/// В расчёт попадают задачи, срок которых уже наступил, и уже сданные.
/// Будущие задачи рейтинг не снижают.
///
/// Качество: средняя оценка по оценённым отчётам. Пока оценок нет,
/// берётся нейтральные 4 из 5, чтобы новый сотрудник не начинал с нуля.
///
/// Дисциплина: доля дней, в которых все задачи сданы в срок.
RatingBreakdown calculateRating(
  List<TaskItem> tasks, {
  required DateTime now,
}) {
  final counted = tasks.where((t) => t.done || now.isAfter(t.due)).toList();
  if (counted.isEmpty) return RatingBreakdown.zero;

  final n = counted.length;

  final onTimeShare = counted.where((t) => t.onTime).length / n;
  final completeShare = counted.where((t) => t.complete).length / n;

  final stars = [
    for (final t in counted)
      if (t.report?.stars != null) t.report!.stars!,
  ];
  final avgStars =
      stars.isEmpty ? 4.0 : stars.reduce((a, b) => a + b) / stars.length;

  final days = <DateTime, List<TaskItem>>{};
  for (final t in counted) {
    days.putIfAbsent(t.day, () => []).add(t);
  }
  final cleanDays =
      days.values.where((list) => list.every((t) => t.onTime)).length;

  return RatingBreakdown(
    onTime: RatingBreakdown.maxOnTime * onTimeShare,
    completeness: RatingBreakdown.maxCompleteness * completeShare,
    quality: RatingBreakdown.maxQuality * avgStars / 5,
    discipline: RatingBreakdown.maxDiscipline * cleanDays / days.length,
  );
}
