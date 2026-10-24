import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../ru.dart';
import '../theme.dart';
import '../widgets.dart';
import 'close_task_screen.dart';
import 'rating_screen.dart';

/// Главный экран сотрудника: задачи на сегодня списком.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tasks = state.todayTasks;
    final done = tasks.where((t) => t.done).length;
    final score = state.ratingFor(state.me.id).total;
    final tone = toneForScore(score);
    final progress = tasks.isEmpty ? 0.0 : done / tasks.length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayLong(DateTime.now()),
                      style: const TextStyle(fontSize: 13, color: muted),
                    ),
                    const SizedBox(height: 2),
                    const ScreenTitle('Задачи на сегодня'),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RatingScreen(userId: state.me.id),
                  ),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: tone.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 18, color: tone.bar),
                      const SizedBox(width: 4),
                      Text(
                        '${score.round()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: tone.fg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE6EBEF),
                      color: toneGood.bar,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Сделано $done из ${tasks.length}',
                  style: const TextStyle(fontSize: 13, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (tasks.isEmpty)
            const Panel(
              child: Text(
                'На сегодня задач нет.',
                style: TextStyle(fontSize: 14, color: muted),
              ),
            ),
          for (final t in tasks) ...[
            _TaskTile(task: t),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          const Panel(
            color: brandSoft,
            borderColor: Colors.transparent,
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: brandDark, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Каждый отчёт сразу попадает в общий чат: '
                    'его видят руководитель и собственник.',
                    style: TextStyle(
                      fontSize: 13,
                      color: brandDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final overdue = task.isOverdue(now);
    final soon = !task.done &&
        !overdue &&
        task.due.difference(now) < const Duration(hours: 2);

    late final IconData icon;
    late final Tone tone;
    late final String status;
    Color? cardColor;
    Color? borderColor;

    if (task.done) {
      icon = Icons.check_rounded;
      tone = toneGood;
      status = 'Сдано в ${hhmm(task.report!.submittedAt)}';
    } else if (overdue) {
      icon = Icons.priority_high_rounded;
      tone = toneBad;
      status = 'Просрочено · до ${hhmm(task.due)}';
      cardColor = const Color(0xFFFFF8F7);
      borderColor = const Color(0xFFF1C7C2);
    } else if (!task.accepted) {
      icon = Icons.mark_email_unread_outlined;
      tone = toneMid;
      status = 'Новая: примите · до ${hhmm(task.due)}';
    } else if (soon) {
      icon = Icons.schedule;
      tone = toneMid;
      status = 'Скоро · до ${hhmm(task.due)}';
    } else {
      icon = Icons.radio_button_unchecked;
      tone = const Tone(
        bar: Color(0xFF8FA0B0),
        bg: Color(0xFFF0F3F6),
        fg: Color(0xFF3B4C5B),
      );
      status = 'До ${hhmm(task.due)}';
    }

    return Panel(
      color: cardColor,
      borderColor: borderColor,
      onTap: task.done
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CloseTaskScreen(taskId: task.id),
                ),
              ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: tone.bg,
            child: Icon(icon, color: tone.fg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: task.done ? muted : ink,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Tag(text: status, bg: tone.bg, fg: tone.fg),
                    for (final k in task.requiredKinds)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(k.icon, size: 14, color: muted),
                          const SizedBox(width: 3),
                          Text(
                            k.label,
                            style: const TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (!task.done) const Icon(Icons.chevron_right, color: muted),
        ],
      ),
    );
  }
}
