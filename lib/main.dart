import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'screens/role_screen.dart';
import 'theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const PoryadokApp(),
    ),
  );
}

class PoryadokApp extends StatelessWidget {
  const PoryadokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Порядок',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const RoleScreen(),
    );
  }
}
