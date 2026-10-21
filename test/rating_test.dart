import 'package:flutter_test/flutter_test.dart';
import 'package:poryadok/models.dart';
import 'package:poryadok/rating.dart';

void main() {
  DateTime at(int h, [int m = 0]) => DateTime(2026, 10, 18, h, m);

  test('считает рейтинг по четырём частям', () {
    final tasks = [
      // Сдано в срок, всё что нужно, оценка 5.
      TaskItem(
        id: 't1',
        title: 'Открыть точку',
        assigneeId: 'e1',
        due: at(10),
        requiredKinds: {ReportKind.photo},
        report: Report(
          submittedAt: at(9),
          kinds: {ReportKind.photo},
          stars: 5,
        ),
      ),
      // Сдано с опозданием, не хватает текста, оценка 3.
      TaskItem(
        id: 't2',
        title: 'Протереть витрину',
        assigneeId: 'e1',
        due: at(12),
        requiredKinds: {ReportKind.photo, ReportKind.text},
        report: Report(
          submittedAt: at(13),
          kinds: {ReportKind.photo},
          stars: 3,
        ),
      ),
    ];

    final r = calculateRating(tasks, now: at(23));

    expect(r.onTime, closeTo(25, 0.001)); // 1 из 2 в срок
    expect(r.completeness, closeTo(10, 0.001)); // 1 из 2 полных
    expect(r.quality, closeTo(16, 0.001)); // средняя 4 из 5
    expect(r.discipline, closeTo(0, 0.001)); // единственный день с опозданием
    expect(r.total, closeTo(51, 0.001));
  });

  test('будущие задачи рейтинг не снижают', () {
    final tasks = [
      TaskItem(
        id: 't1',
        title: 'Вечерняя задача',
        assigneeId: 'e1',
        due: at(21),
        requiredKinds: {ReportKind.photo},
      ),
    ];

    final r = calculateRating(tasks, now: at(9));

    expect(r.total, 0);
  });

  test('без оценок качество нейтральное', () {
    final tasks = [
      TaskItem(
        id: 't1',
        title: 'Открыть точку',
        assigneeId: 'e1',
        due: at(10),
        requiredKinds: {ReportKind.photo},
        report: Report(submittedAt: at(9), kinds: {ReportKind.photo}),
      ),
    ];

    final r = calculateRating(tasks, now: at(23));

    expect(r.quality, closeTo(16, 0.001));
    expect(r.total, closeTo(50 + 20 + 16 + 10, 0.001));
  });
}
