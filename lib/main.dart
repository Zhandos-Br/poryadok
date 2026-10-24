import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'screens/home_shell.dart';
import 'screens/register_screen.dart';
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
    final mode = context.select<AppState, ThemeMode>((s) => s.themeMode);
    final scale = context.select<AppState, double>((s) => s.textSize.scale);
    return MaterialApp(
      title: 'Порядок',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildTheme(dark: true),
      themeMode: mode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const _AuthGate(),
    );
  }
}

/// Не вошли в аккаунт: первым открывается регистрация.
/// Вошли: сразу открывается чат.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<AppState, bool>((s) => s.signedIn);
    return signedIn ? const HomeShell() : const RegisterScreen();
  }
}
