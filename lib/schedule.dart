import 'package:flutter/material.dart';

/// Что сотрудник делает в конкретный день.
enum DayStatus { work, off, vacation }

extension DayStatusX on DayStatus {
  String get label => switch (this) {
        DayStatus.work => 'Смена',
        DayStatus.off => 'Выходной',
        DayStatus.vacation => 'Отпуск',
      };
}

/// Время смены сотрудника и сколько часов она засчитывается.
/// Часы указываются отдельно, потому что в смену могут входить перерывы.
class ShiftInfo {
  const ShiftInfo({
    required this.start,
    required this.end,
    required this.hours,
  });

  final TimeOfDay start;
  final TimeOfDay end;
  final int hours;

  String get range => '${_fmt(start)}–${_fmt(end)}';

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// Итоги по сотруднику за месяц.
class WorkTotals {
  const WorkTotals({
    required this.days,
    required this.hours,
    required this.offDays,
    required this.vacationDays,
  });

  final int days;
  final int hours;
  final int offDays;
  final int vacationDays;
}

/// Сколько задач команды за день выполнено в срок.
class DayTeamStats {
  const DayTeamStats({required this.total, required this.onTime});

  final int total;
  final int onTime;

  /// Доля от 0 до 1. Если задач не было, 0.
  double get share => total == 0 ? 0 : onTime / total;
}

/// Дата без времени. Нужна как ключ в календаре.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
