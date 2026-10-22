import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home_shell.dart';
import 'register_screen.dart';

/// Вход. В рабочей версии здесь вход по номеру телефона,
/// а роль назначает руководитель или собственник.
class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: brand,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Порядок',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Задачи, отчёты и рейтинг команды. Просто и под контролем.',
              style: TextStyle(fontSize: 15, color: muted, height: 1.4),
            ),
            const SizedBox(height: 36),
            const SectionLabel('Войти как'),
            const SizedBox(height: 12),
            const _RoleCard(
              role: Role.employee,
              icon: Icons.checklist,
              subtitle: 'Задачи на сегодня и сдача отчётов',
            ),
            const SizedBox(height: 10),
            const _RoleCard(
              role: Role.manager,
              icon: Icons.groups_outlined,
              subtitle: 'Ставлю задачи, проверяю и оцениваю отчёты',
            ),
            const SizedBox(height: 10),
            const _RoleCard(
              role: Role.owner,
              icon: Icons.bar_chart,
              subtitle: 'Вижу все отчёты, команду и рейтинг',
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RegisterScreen(),
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: brandDark,
                side: const BorderSide(color: brand),
              ),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
              label: const Text('Зарегистрироваться'),
            ),
          ],
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
            radius: 21,
            backgroundColor: brandSoft,
            child: Icon(icon, color: brand, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: muted),
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
