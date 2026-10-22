import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../schedule.dart';
import '../theme.dart';
import '../widgets.dart';
import 'new_task_screen.dart';
import 'employee_tasks_screen.dart';
import 'schedule_screen.dart';

/// Главный экран руководителя и собственника.
/// Сверху сотрудники с рейтингом и итогами месяца, ниже календарь:
/// вся команда или выбранный сотрудник, с успеваемостью по дням.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  /// null: показываем всю команду.
  String? _selected;
  final _calendarKey = GlobalKey();

  void _select(String id) {
    final selecting = _selected != id;
    setState(() => _selected = selecting ? id : null);
    if (!selecting) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _calendarKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final employees = state.employees;
    final today = dateOnly(DateTime.now());
    final scores = {
      for (final e in employees) e.id: state.ratingFor(e.id).total,
    };
    final average = scores.isEmpty
        ? 0.0
        : scores.values.reduce((a, b) => a + b) / scores.length;
    final tone = toneForScore(average);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NewTaskScreen()),
        ),
        backgroundColor: brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Задача'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
          children: [
            const ScreenTitle('Команда'),
            const SizedBox(height: 14),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ScoreBadge(score: average, big: true),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Средний рейтинг команды',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              verdictForScore(average),
                              style: TextStyle(fontSize: 12.5, color: tone.fg),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ScoreBar(value: average, height: 7),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionLabel('Сотрудники · ${employees.length}'),
            const SizedBox(height: 10),
            for (final e in employees) ...[
              _EmployeeCard(
                user: e,
                score: scores[e.id]!,
                selected: _selected == e.id,
                today: today,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EmployeeTasksScreen(userId: e.id),
                  ),
                ),
                onCalendar: () => _select(e.id),
              ),
              const SizedBox(height: 10),
            ],
            const Text(
              'Нажмите на сотрудника, чтобы открыть его задачи и выполнение за период. '
              'Значок календаря показывает его смены ниже. '
              'Рейтинг по 100 баллам: 50 в срок, 20 полнота отчёта, '
              '20 качество, 10 дисциплина.',
              style: TextStyle(fontSize: 12.5, color: muted, height: 1.45),
            ),
            const SizedBox(height: 22),
            Container(
              key: _calendarKey,
              child: Row(
                children: [
                  Expanded(
                    child: SectionLabel(
                      _selected == null
                          ? 'Календарь · вся команда'
                          : 'Календарь · ${state.userById(_selected!).name}',
                    ),
                  ),
                  if (_selected != null)
                    TextButton(
                      onPressed: () => setState(() => _selected = null),
                      child: const Text('Вся команда'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ScheduleView(filter: _selected ?? 'all'),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({
    required this.user,
    required this.score,
    required this.selected,
    required this.today,
    required this.onTap,
    required this.onCalendar,
  });

  final AppUser user;
  final double score;
  final bool selected;
  final DateTime today;
  final VoidCallback onTap;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tone = toneForScore(score);
    final shift = state.shiftOf(user.id);
    final status = state.statusOf(user.id, today);
    final worked =
        state.totalsFor(user.id, today.year, today.month, upTo: today);
    final plan = state.totalsFor(user.id, today.year, today.month);

    final String statusText;
    final Color statusBg;
    final Color statusFg;
    switch (status) {
      case DayStatus.work:
        statusText = 'Сегодня смена ${shift.range}';
        statusBg = const Color(0xFFE3F5EC);
        statusFg = okColor;
      case DayStatus.vacation:
        statusText = 'Сегодня в отпуске';
        statusBg = const Color(0xFFE3EEFB);
        statusFg = const Color(0xFF1A5FA0);
      case DayStatus.off:
        statusText = 'Сегодня выходной';
        statusBg = const Color(0xFFF0F3F6);
        statusFg = muted;
    }

    return Panel(
      onTap: onTap,
      borderColor: selected ? brand : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(user: user, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      user.position,
                      style: const TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ],
                ),
              ),
              ScoreBadge(score: score),
              IconButton(
                tooltip: 'Показать в календаре',
                onPressed: onCalendar,
                icon: Icon(
                  Icons.calendar_month_outlined,
                  color: selected ? brand : muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ScoreBar(value: score),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Tag(text: statusText, bg: statusBg, fg: statusFg),
              Tag(
                text: 'Отработано ${worked.days} из ${plan.days} дн · '
                    '${worked.hours} ч',
              ),
              if (plan.vacationDays > 0)
                Tag(
                  text: 'Отпуск ${plan.vacationDays} дн.',
                  bg: const Color(0xFFE3EEFB),
                  fg: const Color(0xFF1A5FA0),
                ),
              if (score < 65)
                Tag(text: verdictForScore(score), bg: tone.bg, fg: tone.fg),
            ],
          ),
        ],
      ),
    );
  }
}
