import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

/// Итоги дня для руководителя и собственника: что выполнено,
/// что просрочено и кто ещё не принял задачу.
/// В рабочей версии этот же текст сервер присылает каждый вечер
/// push-уведомлением и сообщением в WhatsApp.
class DigestScreen extends StatelessWidget {
  const DigestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final d = state.digest;
    final tone = toneForScore(d.percent);

    return Scaffold(
      appBar: AppBar(title: const Text('Итоги дня')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Panel(
            child: Row(
              children: [
                ScoreBadge(score: d.percent.toDouble(), big: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Выполнено ${d.done} из ${d.total}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        verdictForScore(d.percent),
                        style: TextStyle(fontSize: 13, color: tone.fg),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _Group(
            title: 'Просрочено',
            tasks: d.overdue,
            tone: toneBad,
            empty: 'Просроченных задач нет',
          ),
          const SizedBox(height: 18),
          _Group(
            title: 'Не приняли задачу',
            tasks: d.notAccepted,
            tone: toneMid,
            empty: 'Все задачи приняты',
          ),
          const SizedBox(height: 18),
          _Group(
            title: 'В работе',
            tasks: d.inWork,
            tone: toneGood,
            empty: 'Сейчас в работе ничего нет',
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: state.digestText()));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Сводка скопирована')),
              );
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Скопировать сводку'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Автоматическая отправка сводки каждый вечер push-уведомлением и '
            'в WhatsApp появится вместе с серверной частью.',
            style: TextStyle(fontSize: 12.5, color: muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.tasks,
    required this.tone,
    required this.empty,
  });

  final String title;
  final List<TaskItem> tasks;
  final Tone tone;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('$title · ${tasks.length}'),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          Text(empty, style: const TextStyle(fontSize: 13.5, color: muted)),
        for (final t in tasks) ...[
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: tone.bar,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${state.userById(t.assigneeId).name} · '
                        'до ${hhmm(t.due)}',
                        style: const TextStyle(fontSize: 12.5, color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
