import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home_shell.dart';

/// Вход. В рабочей версии здесь вход по номеру телефона,
/// а роль назначает руководитель или собственник.
class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: brand,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Порядок',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Задачи, отчёты и рейтинг команды. Просто и под контролем.',
                style: TextStyle(fontSize: 17, color: muted, height: 1.4),
              ),
              const Spacer(),
              const Text(
                'ВОЙТИ КАК',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: muted,
                ),
              ),
              const SizedBox(height: 12),
              const _RoleCard(
                role: Role.employee,
                icon: Icons.checklist,
                subtitle: 'Задачи на сегодня и сдача отчётов',
              ),
              const SizedBox(height: 12),
              const _RoleCard(
                role: Role.manager,
                icon: Icons.groups_outlined,
                subtitle: 'Ставлю задачи, проверяю и оцениваю отчёты',
              ),
              const SizedBox(height: 12),
              const _RoleCard(
                role: Role.owner,
                icon: Icons.bar_chart,
                subtitle: 'Вижу все отчёты, команду и рейтинг',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.icon,
    required this.subtitle,
  });

  final Role role;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: () {
        context.read<AppState>().signInAs(role);
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HomeShell()),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: brandSoft,
            child: Icon(icon, color: brand),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: muted),
        ],
      ),
    );
  }
}
