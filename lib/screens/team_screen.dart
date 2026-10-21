import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'new_task_screen.dart';
import 'rating_screen.dart';

/// Главный экран руководителя и собственника: команда и рейтинги.
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final employees = state.employees;
    final scores = {
      for (final e in employees) e.id: state.ratingFor(e.id).total,
    };
    final average = scores.isEmpty
        ? 0.0
        : scores.values.reduce((a, b) => a + b) / scores.length;

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
            const Text(
              'Команда',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Panel(
              child: Row(
                children: [
                  Text(
                    average.round().toString(),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    ' / 100',
                    style: TextStyle(fontSize: 15, color: muted),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Средний рейтинг команды',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'СОТРУДНИКИ · ${employees.length}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: muted,
              ),
            ),
            const SizedBox(height: 10),
            for (final e in employees) ...[
              _EmployeeTile(
                name: e.name,
                position: e.position,
                score: scores[e.id]!,
                avatar: Avatar(user: e, size: 44),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RatingScreen(userId: e.id),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const Text(
              'Рейтинг по 100 баллам: 50 в срок, 20 полнота отчёта, '
              '20 качество, 10 дисциплина.',
              style: TextStyle(fontSize: 13, color: muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({
    required this.name,
    required this.position,
    required this.score,
    required this.avatar,
    required this.onTap,
  });

  final String name;
  final String position;
  final double score;
  final Widget avatar;
  final VoidCallback onTap;

  Color get _color {
    if (score >= 85) return brand;
    if (score >= 65) return const Color(0xFFB7791F);
    return const Color(0xFFC0392B);
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      position,
                      style: const TextStyle(fontSize: 14, color: muted),
                    ),
                  ],
                ),
              ),
              Text(
                score.round().toString(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const Icon(Icons.chevron_right, color: muted),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFDDE5EA),
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
