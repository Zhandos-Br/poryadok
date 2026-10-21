import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../schedule.dart';
import '../theme.dart';
import '../widgets.dart';

const _weekdays = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье',
];

const _monthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

const _monthsNominative = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

const _workBg = Color(0xFFDDF5E7);
const _vacationBg = Color(0xFFE3EEFB);
const _vacationFg = Color(0xFF1A5FA0);
const _offBg = Color(0xFFEEF2F5);

/// График работы: календарь месяца, смены, выходные и отпуска.
/// Руководитель и собственник видят всю команду и могут менять дни.
/// Сотрудник видит только свой график.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _day = dateOnly(DateTime.now());

  /// 'all' или идентификатор сотрудника.
  String _filter = 'all';

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _day = DateTime(_month.year, _month.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isEmployee = state.me.role == Role.employee;
    final filter = isEmployee ? state.me.id : _filter;
    final today = dateOnly(DateTime.now());

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Text(
            isEmployee ? 'Мой график' : 'График',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (!isEmployee) ...[
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip('all', 'Вся команда', filter),
                  for (final e in state.employees)
                    _filterChip(e.id, e.name, filter),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              IconButton(
                tooltip: 'Предыдущий месяц',
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${_monthsNominative[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Следующий месяц',
                onPressed: () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const _WeekdayHeader(),
          const SizedBox(height: 4),
          _buildGrid(state, filter, today),
          const SizedBox(height: 10),
          _Legend(team: filter == 'all'),
          const SizedBox(height: 12),
          _DayPanel(
            day: _day,
            filter: filter,
            canEdit: !isEmployee,
          ),
          const SizedBox(height: 16),
          _Totals(month: _month, filter: filter),
        ],
      ),
    );
  }

  Widget _filterChip(String id, String label, String current) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: current == id,
        onSelected: (_) => setState(() => _filter = id),
      ),
    );
  }

  Widget _buildGrid(AppState state, String filter, DateTime today) {
    final count = DateUtils.getDaysInMonth(_month.year, _month.month);
    final offset = _month.weekday - 1; // понедельник — первая колонка
    final cells = ((offset + count + 6) ~/ 7) * 7;

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 0.85,
      children: [
        for (var i = 0; i < cells; i++)
          _buildCell(state, filter, today, i - offset + 1, count),
      ],
    );
  }

  Widget _buildCell(
    AppState state,
    String filter,
    DateTime today,
    int d,
    int count,
  ) {
    if (d < 1 || d > count) return const SizedBox.shrink();

    final day = DateTime(_month.year, _month.month, d);
    final isToday = day == today;
    final selected = day == _day;

    String line;
    Color bg = Colors.white;
    Color fg = muted;

    if (filter == 'all') {
      final stats = state.teamStatsFor(day);
      if (!day.isAfter(today) && stats.total > 0) {
        final pct = (stats.share * 100).round();
        final tone = _tone(pct);
        line = '$pct%';
        bg = tone.$1;
        fg = tone.$2;
      } else {
        final n = state.workersOn(day);
        line = n == 0 ? '—' : '$n чел.';
      }
    } else {
      switch (state.statusOf(filter, day)) {
        case DayStatus.work:
          line = '${state.shiftOf(filter).hours} ч';
          bg = _workBg;
          fg = okColor;
        case DayStatus.vacation:
          line = 'Отпуск';
          bg = _vacationBg;
          fg = _vacationFg;
        case DayStatus.off:
          line = 'Вых.';
          bg = _offBg;
          fg = muted;
      }
    }

    return Semantics(
      button: true,
      selected: selected,
      label: '$d ${_monthsGenitive[_month.month - 1]}, $line'
          '${isToday ? ', сегодня' : ''}',
      child: ExcludeSemantics(
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _day = day),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF0F1B26)
                      : isToday
                          ? brand
                          : lineColor,
                  width: selected || isToday ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$d',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          selected || isToday ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    line,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Цвета по доле задач, выполненных в срок: (фон, текст).
(Color, Color) _tone(int pct) {
  if (pct >= 90) return (_workBg, okColor);
  if (pct >= 75) return (const Color(0xFFFFF1D6), warnColor);
  return (const Color(0xFFFDE8E6), badColor);
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Row(
      children: [
        for (var i = 0; i < names.length; i++)
          Expanded(
            child: Text(
              names[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: i >= 5 ? badColor : muted,
              ),
            ),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.team});

  final bool team;

  @override
  Widget build(BuildContext context) {
    final items = team
        ? const [
            ('В срок 90% и выше', _workBg),
            ('75–89%', Color(0xFFFFF1D6)),
            ('Ниже 75%', Color(0xFFFDE8E6)),
            ('Дальше: человек на смене', Colors.white),
          ]
        : const [
            ('Смена, часы', _workBg),
            ('Выходной', _offBg),
            ('Отпуск', _vacationBg),
          ];

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item.$2,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFC5CFD8)),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                item.$1,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF3B4C5B),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Выбранный день: кто на смене, статистика команды и (для руководителя)
/// кнопки «Смена / Выходной / Отпуск».
class _DayPanel extends StatelessWidget {
  const _DayPanel({
    required this.day,
    required this.filter,
    required this.canEdit,
  });

  final DateTime day;
  final String filter;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = dateOnly(DateTime.now());
    final team = filter == 'all';
    final people = team
        ? state.employees
        : [state.userById(filter)];
    final stats = state.teamStatsFor(day);
    final isFuture = day.isAfter(today);

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_weekdays[day.weekday - 1]}, '
                  '${day.day} ${_monthsGenitive[day.month - 1]}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (day == today)
                const Tag(text: 'Сегодня', bg: brandSoft, fg: brandDark),
            ],
          ),
          const SizedBox(height: 8),
          if (!isFuture && stats.total > 0)
            Row(
              children: [
                _PctBadge(pct: (stats.share * 100).round()),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${stats.onTime} из ${stats.total} задач команды '
                    'выполнено в срок',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF3B4C5B)),
                  ),
                ),
              ],
            )
          else if (isFuture)
            Text(
              'Запланировано на смене: ${state.workersOn(day)} '
              'из ${state.employees.length} сотрудников',
              style: const TextStyle(fontSize: 14, color: Color(0xFF3B4C5B)),
            ),
          const SizedBox(height: 6),
          for (final p in people) _PersonRow(user: p, day: day),
          if (canEdit && !team) ...[
            const Divider(height: 20),
            Text(
              'Отметить день для: ${state.userById(filter).name}',
              style: const TextStyle(fontSize: 13, color: muted),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<DayStatus>(
                showSelectedIcon: false,
                segments: [
                  for (final s in DayStatus.values)
                    ButtonSegment(value: s, label: Text(s.label)),
                ],
                selected: {state.statusOf(filter, day)},
                onSelectionChanged: (set) =>
                    state.setStatus(filter, day, set.first),
              ),
            ),
          ],
          if (canEdit && team) ...[
            const Divider(height: 20),
            const Text(
              'Выберите сотрудника сверху, чтобы поставить смену, '
              'выходной или отпуск.',
              style: TextStyle(fontSize: 13, color: muted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _PctBadge extends StatelessWidget {
  const _PctBadge({required this.pct});

  final int pct;

  @override
  Widget build(BuildContext context) {
    final tone = _tone(pct);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: tone.$1,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: tone.$2,
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.user, required this.day});

  final AppUser user;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final status = state.statusOf(user.id, day);
    final shift = state.shiftOf(user.id);

    final String meta;
    final Color bg;
    final Color fg;
    switch (status) {
      case DayStatus.work:
        meta = '${shift.range} · ${shift.hours} ч';
        bg = _workBg;
        fg = okColor;
      case DayStatus.vacation:
        meta = 'В отпуске';
        bg = _vacationBg;
        fg = _vacationFg;
      case DayStatus.off:
        meta = 'Не работает';
        bg = _offBg;
        fg = const Color(0xFF3B4C5B);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Avatar(user: user, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(meta, style: const TextStyle(fontSize: 13, color: muted)),
              ],
            ),
          ),
          Tag(text: status.label, bg: bg, fg: fg),
        ],
      ),
    );
  }
}

/// Итоги месяца: сколько дней и часов отработано и сколько по плану.
class _Totals extends StatelessWidget {
  const _Totals({required this.month, required this.filter});

  final DateTime month;
  final String filter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = dateOnly(DateTime.now());
    final team = filter == 'all';
    final people = team ? state.employees : [state.userById(filter)];

    var workedDays = 0, workedHours = 0, planDays = 0, planHours = 0;
    final cards = <Widget>[];

    for (final p in people) {
      final worked =
          state.totalsFor(p.id, month.year, month.month, upTo: today);
      final plan = state.totalsFor(p.id, month.year, month.month);
      workedDays += worked.days;
      workedHours += worked.hours;
      planDays += plan.days;
      planHours += plan.hours;

      cards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Avatar(user: p, size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${p.position} · смена ${state.shiftOf(p.id).range}',
                            style: const TextStyle(fontSize: 13, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Отработано',
                        value: '${worked.days} дн · ${worked.hours} ч',
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'План на месяц',
                        value: '${plan.days} дн · ${plan.hours} ч',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Выходных: ${plan.offDays} · Отпуск: ${plan.vacationDays} дн.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF3B4C5B)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final monthStats = state.teamStatsForMonth(month.year, month.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ИТОГИ · ${_monthsNominative[month.month - 1].toUpperCase()}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: muted,
          ),
        ),
        const SizedBox(height: 10),
        if (team) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: brandDark,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Вся команда',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFCFE8E4),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Отработано',
                        value: '$workedDays дн · $workedHours ч',
                        light: true,
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'План на месяц',
                        value: '$planDays дн · $planHours ч',
                        light: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  monthStats.total == 0
                      ? 'Задач за месяц пока нет'
                      : 'Задач выполнено в срок за месяц: '
                          '${(monthStats.share * 100).round()}%',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        ...cards,
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.light = false});

  final String label;
  final String value;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: light ? const Color(0xFFCFE8E4) : muted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: light ? 20 : 16,
            fontWeight: FontWeight.w700,
            color: light ? Colors.white : null,
          ),
        ),
      ],
    );
  }
}
