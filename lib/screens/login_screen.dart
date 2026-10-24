import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets.dart';

/// Вход для тех, кто уже зарегистрирован. В рабочей версии здесь
/// подтверждение кодом из SMS. В демо достаточно номера.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool get _valid => _phone.text.replaceAll(RegExp(r'\D'), '').length >= 10;

  void _finish() => Navigator.of(context).popUntil((r) => r.isFirst);

  void _signIn() {
    final error = context.read<AppState>().signInByPhone(_phone.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    _finish();
  }

  void _demo(String userId) {
    context.read<AppState>().signInAsUser(userId);
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'Введите номер, на который зарегистрирован аккаунт.',
            style: TextStyle(fontSize: 14, color: muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()\-]')),
            ],
            decoration: InputDecoration(
              labelText: 'Номер телефона',
              hintText: '+7 701 100 00 03',
              prefixIcon: const Icon(Icons.phone_outlined),
              filled: true,
              fillColor: paletteOf(context).card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: lineColor),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(fontSize: 13.5, color: badColor),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _valid ? _signIn : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: brand,
            ),
            child: const Text('Войти'),
          ),
          const SizedBox(height: 28),
          const SectionLabel('Демо: войти как'),
          const SizedBox(height: 10),
          _DemoTile(
            icon: Icons.bar_chart,
            title: 'Собственник',
            subtitle: 'Видит отчёты, команду и рейтинг',
            onTap: () => _demo('o1'),
          ),
          const SizedBox(height: 8),
          _DemoTile(
            icon: Icons.groups_outlined,
            title: 'Руководитель',
            subtitle: 'Ставит задачи из чата, оценивает отчёты',
            onTap: () => _demo('m1'),
          ),
          const SizedBox(height: 8),
          _DemoTile(
            icon: Icons.checklist,
            title: 'Сотрудник Айгерим',
            subtitle: 'Задачи на сегодня и отчёты',
            onTap: () => _demo('e1'),
          ),
          const SizedBox(height: 8),
          _DemoTile(
            icon: Icons.mail_outline,
            title: 'Ерлан, без компании',
            subtitle: 'Его пригласили в «Рассвет»: можно принять приглашение',
            onTap: () => _demo('x1'),
          ),
        ],
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: brandSoft,
            child: Icon(icon, color: brand, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12.5, color: muted),
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
