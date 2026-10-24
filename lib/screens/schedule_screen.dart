import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../ru.dart';
import '../schedule.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets.dart';

const _workBg = Color(0xFFE3F5EC);
const _offBg = Color(0xFFF0F3F6);
const _vacationBg = Color(0xFFE3EEFB);
const _vacationFg = Color(0xFF1A5FA0);

/// «Мой график» для сотрудника: свои смены, выходные, отпуск,
/// итоги месяца и то, как закрыты задачи в каждый день.
class MyScheduleScreen extends StatelessWidget {
  const MyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const ScreenTitle('Мой график'),
          const SizedBox(height: 14),
          ScheduleView(filter: state.me.id),
        ],
      ),
    );
  }
}

/// Календарь месяца, выбранный день и итоги.
/// [filter]: 'all' для всей команды или идентификатор сотрудника.
/// Руководитель и собственник могут менять дни сотрудника.
class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key, required this.filter});

  final String filter;

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _day = dateOnly(DateTime.now());

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _day = DateTime(_month.year, _month.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = dateOnly(DateTime.now());
    final team = widget.filter == 'all';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Предыдущий месяц',
              onPressed: () => _shiftMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${ruMonthsNominative[_month.month - 1]} ${_month.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        _buildGrid(state, today),
        const SizedBox(height: 10),
        _Legend(team: team),
        const SizedBox(height: 14),
        _DayPanel(day: _day, filter: widget.filter),
        const SizedBox(height: 18),
        _Totals(month: _month, filter: widget.filter),
      ],
    );
  }

  Widget _buildGrid(AppState state, DateTime today) {
    final count = DateUtils.getDaysInMonth(_month.year, _month.month);
    final offset = _month.weekday - 1; // понедельник — первая колонка
    final cells = ((offset + count + 6) ~/ 7) * 7;

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      childAspectRatio: 0.88,
      children: [
        for (var i = 0; i < cells; i++)
          _buildCell(state, today, i - offset + 1, count),
      ],
    );
  }

  Widget _buildCell(AppState state, DateTime today, int d, int count) {
    if (d < 1 || d > count) return const SizedBox.shrink();

    final filter = widget.filter;
    final day = DateTime(_month.year, _month.month, d);
    final isToday = day == today;
    final selected = day == _day;
    final past = !day.isAfter(today);

    String line;
    Color bg = paletteOf(context).card;
    Color fg = muted;
    Color? dot;

    if (filter == 'all') {
      final stats = state.teamStatsFor(day);
      if (past && stats.total > 0) {
        final pct = (stats.share * 100).round();
        final tone = toneForScore(pct);
        line = '$pct%';
        bg = tone.bg;
        fg = tone.fg;
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
      final ds = state.userDayStats(filter, day);
      if (past && ds.total > 0) dot = toneForScore(ds.share * 100).bar;
    }

    return Semantics(
      button: true,
      selected: selected,
      label: '$d ${ruMonthsGenitive[_month.month - 1]}, $line'
          '${isToday ? ', сегодня' : ''}',
      child: ExcludeSemantics(
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _day = day),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? paletteOf(context).ink
                      : isToday
                          ? brand
                          : paletteOf(context).line,
                  width: selected || isToday ? 1.6 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$d',
                          style: TextStyle(
                            fontSize: 14,
                            color: bg == paletteOf(context).card
                                ? paletteOf(context).ink
                                : const Color(0xFF1B2733),
                            fontWeight:
                                selected || isToday ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          line,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (dot != null)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: dot,
                          shape: BoxShape.circle,
                        ),
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
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: i >= 5 ? toneBad.bar : muted,
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
            ('Задачи в срок 85%+', Color(0xFFE3F5EC)),
            ('65–84%', Color(0xFFFFF1D6)),
            ('Ниже 65%', Color(0xFFFDE8E6)),
            ('Впереди: сколько человек на смене', Color(0x00000000)),
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
        for (final item in items) _LegendItem(label: item.$1, color: item.$2),
        if (!team)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in const [toneGood, toneMid, toneBad])
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(color: t.bar, shape: BoxShape.circle),
                ),
              const SizedBox(width: 3),
              const Text(
                'Точка: как закрыты задачи дня',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFC9D2DA)),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: muted)),
      ],
    );
  }
}

/// Выбранный день: кто на смене, как закрыты задачи и (для руководителя)
/// кнопки «Смена / Выходной / Отпуск».
class _DayPanel extends StatelessWidget {
  const _DayPanel({required this.day, required this.filter});

  final DateTime day;
  final String filter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = dateOnly(DateTime.now());
    final team = filter == 'all';
    final canEdit = state.me.role != Role.employee;
    final people = team ? state.employees : [state.userById(filter)];
    final stats =
        team ? state.teamStatsFor(day) : state.userDayStats(filter, day);
    final isFuture = day.isAfter(today);

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dayLong(day),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              if (day == today)
                const Tag(text: 'Сегодня', bg: brandSoft, fg: brandDark),
            ],
          ),
          const SizedBox(height: 10),
          if (!isFuture && stats.total > 0)
            _StatsLine(stats: stats, team: team)
          else if (isFuture && team)
            Text(
              'Запланировано на смене: ${state.workersOn(day)} '
              'из ${state.employees.length}',
              style: const TextStyle(fontSize: 13, color: muted),
            )
          else
            const Text(
              'За этот день задач нет',
              style: TextStyle(fontSize: 13, color: muted),
            ),
          const SizedBox(height: 6),
          for (final p in people) _PersonRow(user: p, day: day, showStats: team),
          if (canEdit && !team) ...[
            const Divider(height: 22),
            Text(
              'Отметить день: ${state.userById(filter).name}',
              style: const TextStyle(fontSize: 12.5, color: muted),
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
            const Divider(height: 22),
            const Text(
              'Выберите сотрудника выше, чтобы поставить смену, '
              'выходной или отпуск.',
              style: TextStyle(fontSize: 12.5, color: muted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsLine extends StatelessWidget {
  const _StatsLine({required this.stats, required this.team});

  final DayTeamStats stats;
  final bool team;

  @override
  Widget build(BuildContext context) {
    final pct = (stats.share * 100).round();
    final tone = toneForScore(pct);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: tone.bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$pct%',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: tone.fg,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            team
                ? '${stats.onTime} из ${stats.total} задач команды в срок'
                : '${stats.onTime} из ${stats.total} задач в срок',
            style: const TextStyle(fontSize: 13, color: muted),
          ),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.user,
    required this.day,
    required this.showStats,
  });

  final AppUser user;
  final DateTime day;
  final bool showStats;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final status = state.statusOf(user.id, day);
    final shift = state.shiftOf(user.id);
    final today = dateOnly(DateTime.now());
    final ds = state.userDayStats(user.id, day);

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
        fg = muted;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Avatar(user: user, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(meta, style: const TextStyle(fontSize: 12.5, color: muted)),
              ],
            ),
          ),
          if (showStats && !day.isAfter(today) && ds.total > 0) ...[
            Tag(
              text: '${(ds.share * 100).round()}%',
              bg: toneForScore(ds.share * 100).bg,
              fg: toneForScore(ds.share * 100).fg,
            ),
            const SizedBox(width: 6),
          ],
          Tag(text: status.label, bg: bg, fg: fg),
        ],
      ),
    );
  }
}

/// Итоги месяца: отработано и по плану. Для всей команды или одного человека.
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
    var off = 0, vac = 0;
    for (final p in people) {
      final worked =
          state.totalsFor(p.id, month.year, month.month, upTo: today);
      final plan = state.totalsFor(p.id, month.year, month.month);
      workedDays += worked.days;
      workedHours += worked.hours;
      planDays += plan.days;
      planHours += plan.hours;
      off += plan.offDays;
      vac += plan.vacationDays;
    }

    final monthStats = team
        ? state.teamStatsForMonth(month.year, month.month)
        : state.userStatsForMonth(filter, month.year, month.month);
    final pct = (monthStats.share * 100).round();
    final tone = toneForScore(pct);

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            'Итоги · ${ruMonthsNominative[month.month - 1]}'
            '${team ? ' · вся команда' : ''}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Отработано',
                  value: '$workedDays дн · $workedHours ч',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'План на месяц',
                  value: '$planDays дн · $planHours ч',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            team
                ? 'Выходных: $off · отпуск: $vac дн. (сумма по команде)'
                : 'Выходных: $off · отпуск: $vac дн.',
            style: const TextStyle(fontSize: 12.5, color: muted),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  monthStats.total == 0
                      ? 'Задач за месяц пока нет'
                      : 'Задач выполнено в срок за месяц',
                  style: const TextStyle(fontSize: 13, color: muted),
                ),
              ),
              if (monthStats.total > 0)
                Tag(text: '$pct%', bg: tone.bg, fg: tone.fg),
            ],
          ),
          if (monthStats.total > 0) ...[
            const SizedBox(height: 8),
            ScoreBar(value: monthStats.share * 100),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
