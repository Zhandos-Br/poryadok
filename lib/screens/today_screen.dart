import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
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
    final tasks = state.myTasks;
    final done = tasks.where((t) => t.done).length;
    final score = state.ratingFor(state.me.id).total.round();
    final progress = tasks.isEmpty ? 0.0 : done / tasks.length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ActionChip(
              avatar: const Icon(Icons.star, size: 18, color: brandDark),
              label: Text('Мой рейтинг $score / 100'),
              backgroundColor: brandSoft,
              side: BorderSide.none,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RatingScreen(userId: state.me.id),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Задачи на сегодня',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFDDE5EA),
                    color: brand,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$done из ${tasks.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final t in tasks) ...[
            _TaskTile(task: t),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Panel(
            borderColor: Colors.transparent,
            child: const Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: brandDark),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Каждый отчёт сразу попадает в общий чат: '
                    'его видят руководитель и собственник.',
                    style: TextStyle(color: brandDark, height: 1.35),
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
    final overdue = task.isOverdue(DateTime.now());

    late final IconData icon;
    late final Color iconBg;
    late final Color iconFg;
    late final String status;
    late final Color statusColor;

    if (task.done) {
      icon = Icons.check;
      iconBg = const Color(0xFFDDF5E7);
      iconFg = okColor;
      status = 'Сдано в ${hhmm(task.report!.submittedAt)}';
      statusColor = okColor;
    } else if (overdue) {
      icon = Icons.warning_amber_rounded;
      iconBg = const Color(0xFFFDE8E6);
      iconFg = badColor;
      status = 'Просрочено · до ${hhmm(task.due)}';
      statusColor = badColor;
    } else {
      icon = Icons.radio_button_unchecked;
      iconBg = const Color(0xFFE9EEF2);
      iconFg = const Color(0xFF3B4C5B);
      status = 'До ${hhmm(task.due)}';
      statusColor = muted;
    }

    return Panel(
      borderColor: overdue ? const Color(0xFFE4A199) : null,
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
            radius: 20,
            backgroundColor: iconBg,
            child: Icon(icon, color: iconFg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: task.done ? muted : null,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    for (final k in task.requiredKinds)
                      Tag(text: k.label, icon: k.icon),
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
