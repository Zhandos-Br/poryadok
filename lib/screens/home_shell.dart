import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import 'chat_list_screen.dart';
import 'schedule_screen.dart';
import 'team_screen.dart';
import 'today_screen.dart';

/// Нижняя навигация. Приложение построено вокруг чата: он всегда первый
/// и открывается сразу после входа.
/// Сотрудник: Чаты, Сегодня, Мой график. Рейтинг сотрудникам не показывается.
/// Руководитель и собственник: Чаты и Команда (с календарём).
/// Пользователь без компании видит только чаты и приглашения.
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
    final hasCompany = me.companyId != null;
    final isEmployee = me.role == Role.employee;

    final List<Widget> pages;
    final List<NavigationDestination> destinations;

    const chats = NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      label: 'Чаты',
    );

    if (!hasCompany) {
      pages = const [ChatListScreen()];
      destinations = const [chats];
    } else if (isEmployee) {
      pages = [
        const ChatListScreen(),
        const TodayScreen(),
        const MyScheduleScreen(),
      ];
      destinations = const [
        chats,
        NavigationDestination(
          icon: Icon(Icons.checklist),
          label: 'Сегодня',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Мой график',
        ),
      ];
    } else {
      pages = const [ChatListScreen(), TeamScreen()];
      destinations = const [
        chats,
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          label: 'Команда',
        ),
      ];
    }

    // Состав вкладок меняется, например после принятия приглашения.
    final index = _index < pages.length ? _index : 0;

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: pages.length < 2
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: destinations,
            ),
    );
  }
}
