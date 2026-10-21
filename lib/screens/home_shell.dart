import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import 'chat_list_screen.dart';
import 'rating_screen.dart';
import 'schedule_screen.dart';
import 'team_screen.dart';
import 'today_screen.dart';

/// Нижняя навигация. У сотрудника: Сегодня, Чаты, Мой график, Рейтинг.
/// У руководителя и собственника: Команда, Чаты, График.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().me;
    final isEmployee = me.role == Role.employee;

    final pages = isEmployee
        ? <Widget>[
            const TodayScreen(),
            const ChatListScreen(),
            const ScheduleScreen(),
            RatingScreen(userId: me.id, embedded: true),
          ]
        : <Widget>[
            const TeamScreen(),
            const ChatListScreen(),
            const ScheduleScreen(),
          ];

    final destinations = isEmployee
        ? const [
            NavigationDestination(
              icon: Icon(Icons.checklist),
              label: 'Сегодня',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Чаты',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Мой график',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart),
              label: 'Рейтинг',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              label: 'Команда',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Чаты',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'График',
            ),
          ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
