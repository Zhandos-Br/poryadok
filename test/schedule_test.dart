import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poryadok/app_state.dart';
import 'package:poryadok/schedule.dart';

void main() {
  test('Айгерим работает в будни и отдыхает в выходные', () {
    final state = AppState();
    final now = DateTime.now();

    var monday = DateTime(now.year, now.month, 1);
    while (monday.weekday != DateTime.monday) {
      monday = monday.add(const Duration(days: 1));
    }
    final saturday = monday.add(const Duration(days: 5));

    expect(state.statusOf('e1', monday), DayStatus.work);
    expect(state.statusOf('e1', saturday), DayStatus.off);
  });

  test('итоги за месяц: дни и часы совпадают со сменами', () {
    final state = AppState();
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    var weekdays = 0;
    for (var d = 1; d <= daysInMonth; d++) {
      if (DateTime(now.year, now.month, d).weekday <= 5) weekdays++;
    }

    final totals = state.totalsFor('e1', now.year, now.month);

    expect(totals.days, weekdays);
    expect(totals.hours, weekdays * 8);
    expect(totals.days + totals.offDays + totals.vacationDays, daysInMonth);
  });

  test('руководитель может поставить отпуск и итоги меняются', () {
    final state = AppState();
    final now = DateTime.now();

    var monday = DateTime(now.year, now.month, 1);
    while (monday.weekday != DateTime.monday) {
      monday = monday.add(const Duration(days: 1));
    }

    final before = state.totalsFor('e1', now.year, now.month);
    state.setStatus('e1', monday, DayStatus.vacation);
    final after = state.totalsFor('e1', now.year, now.month);

    expect(after.days, before.days - 1);
    expect(after.vacationDays, before.vacationDays + 1);
  });
}
