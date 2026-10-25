import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../ru.dart';
import '../schedule.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets.dart';
import 'rating_screen.dart';

enum _Period { today, week, month, custom }

/// Сотрудник глазами руководителя и собственника: задачи на сегодня
/// и список выполненного за выбранный период с процентом исполнения.
class EmployeeTasksScreen extends StatefulWidget {
  const EmployeeTasksScreen({super.key, required this.userId});

  final String userId;

  @override
  State<EmployeeTasksScreen> createState() => _EmployeeTasksScreenState();
}

class _EmployeeTasksScreenState extends State<EmployeeTasksScreen> {
  _Period _period = _Period.month;
  DateTimeRange? _custom;

  DateTimeRange _range(DateTime today) {
    switch (_period) {
      case _Period.today:
        return DateTimeRange(start: today, end: today);
      case _Period.week:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case _Period.month:
        return DateTimeRange(
          start: DateTime(today.year, today.month, 1),
          end: today,
        );
      case _Period.custom:
        return _custom ?? DateTimeRange(start: today, end: today);
    }
  }

  Future<void> _pickCustom(DateTime today) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 1, 1, 1),
      lastDate: today,
      initialDateRange: _custom ?? _range(today),
      helpText: 'Период',
      saveText: 'Готово',
    );
    if (picked == null) return;
    setState(() {
      _custom = DateTimeRange(
        start: dateOnly(picked.start),
        end: dateOnly(picked.end),
      );
      _period = _Period.custom;
    });
  }

  String _rangeText(DateTimeRange r) {
    String f(DateTime d) => '${d.day} ${ruMonthsGenitive[d.month - 1]}';
    if (r.start == r.end) return f(r.start);
    return '${f(r.start)} — ${f(r.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.userById(widget.userId);
    final now = DateTime.now();
    final today = dateOnly(now);
    final range = _range(today);
    final score = state.ratingFor(user.id).total;

    final mine = state.tasks.where((t) => t.assigneeId == user.id).toList()
      ..sort((a, b) => a.due.compareTo(b.due));
    final todayList = mine.where((t) => t.day == today).toList();
    final periodList = mine
        .where((t) => !t.day.isBefore(range.start) && !t.day.isAfter(range.end))
        .toList()
      ..sort((a, b) => b.due.compareTo(a.due));

    final counted = periodList.where((t) => t.done || now.isAfter(t.due));
    final total = counted.length;
    final doneCount = counted.where((t) => t.done).length;
    final onTimeCount = counted.where((t) => t.onTime).length;
    final missed = total - doneCount;
    final donePct = total == 0 ? 0.0 : 100.0 * doneCount / total;
    final tone = toneForScore(donePct);

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Panel(
              child: Row(
                children: [
                  Avatar(user: user, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user.position,
                          style: const TextStyle(fontSize: 13, color: muted),
                        ),
                      ],
                    ),
                  ),
                  ScoreBadge(score: score),
                  IconButton(
                    tooltip: 'Рейтинг и разбивка',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RatingScreen(userId: user.id),
                      ),
                    ),
                    icon: const Icon(Icons.insights_outlined, color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _BindingPanel(user: user),
            const SizedBox(height: 18),
            const SectionLabel('Период'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('Сегодня', _period == _Period.today,
                      () => setState(() => _period = _Period.today)),
                  _chip('Неделя', _period == _Period.week,
                      () => setState(() => _period = _Period.week)),
                  _chip('Месяц', _period == _Period.month,
                      () => setState(() => _period = _Period.month)),
                  _chip(
                    _period == _Period.custom
                        ? _rangeText(range)
                        : 'Свой период',
                    _period == _Period.custom,
                    () => _pickCustom(today),
                    icon: Icons.date_range,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _rangeText(range),
              style: const TextStyle(fontSize: 12.5, color: muted),
            ),
            const SizedBox(height: 10),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        total == 0 ? '—' : '${donePct.round()}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: total == 0 ? muted : tone.fg,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text(
                            'процент исполнения',
                            style: TextStyle(fontSize: 13, color: muted),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ScoreBar(value: donePct, height: 8),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Tag(
                        text: 'Выполнено $doneCount из $total',
                        bg: toneGood.bg,
                        fg: toneGood.fg,
                      ),
                      Tag(text: 'В срок $onTimeCount'),
                      if (missed > 0)
                        Tag(
                          text: 'Не сдано $missed',
                          bg: toneBad.bg,
                          fg: toneBad.fg,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionLabel('Задачи на сегодня · ${todayList.length}'),
            const SizedBox(height: 8),
            if (todayList.isEmpty)
              const Panel(
                child: Text(
                  'На сегодня задач нет.',
                  style: TextStyle(color: muted),
                ),
              ),
            for (final t in todayList) ...[
              _TaskTile(task: t, now: now, showDay: false),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 14),
            SectionLabel('За период · ${periodList.length}'),
            const SizedBox(height: 8),
            if (periodList.isEmpty)
              const Panel(
                child: Text(
                  'За этот период задач нет.',
                  style: TextStyle(color: muted),
                ),
              ),
            for (final t in periodList) ...[
              _TaskTile(task: t, now: now, showDay: true),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, bool on, VoidCallback onTap, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: on ? Colors.white : paletteOf(context).ink),
              const SizedBox(width: 6),
            ],
            Text(text),
          ],
        ),
        selected: on,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: brand,
        backgroundColor: paletteOf(context).card,
        labelStyle: TextStyle(
          color: on ? Colors.white : paletteOf(context).ink,
          fontWeight: FontWeight.w500,
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.now,
    required this.showDay,
  });

  final TaskItem task;
  final DateTime now;
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final String statusText;
    final Color bg;
    final Color fg;
    final IconData icon;
    if (task.done) {
      final at = hhmm(task.report!.submittedAt);
      if (task.onTime) {
        statusText = 'Сдано в $at · в срок';
        bg = toneGood.bg;
        fg = toneGood.fg;
        icon = Icons.check_circle_outline;
      } else {
        statusText = 'Сдано в $at · с опозданием';
        bg = toneMid.bg;
        fg = toneMid.fg;
        icon = Icons.schedule;
      }
    } else if (now.isAfter(task.due)) {
      statusText = 'Просрочено';
      bg = toneBad.bg;
      fg = toneBad.fg;
      icon = Icons.error_outline;
    } else if (!task.accepted) {
      statusText = 'Ожидает принятия';
      bg = toneMid.bg;
      fg = toneMid.fg;
      icon = Icons.mark_email_unread_outlined;
    } else {
      statusText = 'В работе';
      bg = const Color(0xFFF0F3F6);
      fg = muted;
      icon = Icons.radio_button_unchecked;
    }

    final dueText = showDay
        ? '${task.day.day} ${ruMonthsGenitive[task.day.month - 1]}, до ${hhmm(task.due)}'
        : 'до ${hhmm(task.due)}';
    final report = task.report;

    return Panel(
      onTap: report == null
          ? null
          : () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (_) => _ReportSheet(task: task),
              ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dueText,
                  style: const TextStyle(fontSize: 12.5, color: muted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Tag(text: statusText, bg: bg, fg: fg),
                    if (report != null && report.kinds.isNotEmpty)
                      KindChips(kinds: report.kinds),
                    if (report?.stars != null)
                      Tag(text: '★ ${report!.stars}'),
                  ],
                ),
              ],
            ),
          ),
          if (report != null)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.chevron_right, color: muted),
            ),
        ],
      ),
    );
  }
}

class _ReportSheet extends StatelessWidget {
  const _ReportSheet({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final r = task.report!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Сдано ${dayLong(r.submittedAt)}, ${hhmm(r.submittedAt)}',
            style: const TextStyle(fontSize: 13, color: muted),
          ),
          const SizedBox(height: 12),
          KindChips(kinds: r.kinds),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(r.comment, style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
          if (r.stars != null) ...[
            const SizedBox(height: 12),
            Text(
              'Оценка качества: ${r.stars} из 5',
              style: const TextStyle(fontSize: 14, color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// К какой компании привязан сотрудник: компания, БИН, телефон, паспорт.
/// Паспорт скрыт, пока руководитель или собственник не нажмёт «показать».
class _BindingPanel extends StatefulWidget {
  const _BindingPanel({required this.user});

  final AppUser user;

  @override
  State<_BindingPanel> createState() => _BindingPanelState();
}

class _BindingPanelState extends State<_BindingPanel> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = widget.user;
    final company =
        user.companyId == null ? null : state.companyById(user.companyId!);
    final passport = user.passport;

    Widget row(String label, String value, {Widget? trailing}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 104,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: muted),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        );

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 18, color: brand),
              const SizedBox(width: 8),
              Text(
                'Привязка к компании',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: paletteOf(context).ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          row('Компания', company?.name ?? '—'),
          row('БИН', company?.bin ?? '—'),
          row('Телефон', user.phone),
          row(
            'Паспорт',
            passport == null
                ? 'Не указан'
                : (_show ? passport : maskPassport(passport)),
            trailing: passport == null
                ? null
                : IconButton(
                    tooltip: _show ? 'Скрыть' : 'Показать',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _show = !_show),
                    icon: Icon(
                      _show
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: muted,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
