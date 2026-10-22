import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'chat_screen.dart';

/// Новый чат: человека находят по номеру телефона.
/// Это может быть коллега или любой, кто зарегистрирован в приложении.
class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _phone = TextEditingController();
  AppUser? _found;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool get _valid => _phone.text.replaceAll(RegExp(r'\D'), '').length >= 10;

  void _search() {
    final user = context.read<AppState>().findUserByPhone(_phone.text);
    setState(() {
      _found = user;
      _searched = true;
    });
  }

  void _open(AppUser user) {
    final chatId = context.read<AppState>().startDirectChat(user.id);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => ChatScreen(chatId: chatId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().me;
    final found = _found;

    return Scaffold(
      appBar: AppBar(title: const Text('Новый чат')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'Введите номер телефона человека. Он должен быть '
            'зарегистрирован в приложении.',
            style: TextStyle(fontSize: 13.5, color: muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()\-]')),
            ],
            onSubmitted: (_) {
              if (_valid) _search();
            },
            decoration: InputDecoration(
              labelText: 'Номер телефона',
              hintText: '+7 777 123 45 67',
              prefixIcon: const Icon(Icons.phone_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: lineColor),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _valid ? _search : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: brand,
            ),
            child: const Text('Найти'),
          ),
          const SizedBox(height: 18),
          if (_searched && found == null)
            const Panel(
              color: Color(0xFFFFF8F7),
              borderColor: Color(0xFFF1C7C2),
              child: Row(
                children: [
                  Icon(Icons.person_search_outlined, color: badColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Пользователь с таким номером не найден. '
                      'Возможно, он ещё не зарегистрирован в приложении.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: badColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (found != null)
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Avatar(user: found, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              found.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              found.nickname.isEmpty
                                  ? found.position
                                  : '@${found.nickname} · ${found.position}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (found.id == me.id)
                    const Text(
                      'Это ваш номер.',
                      style: TextStyle(fontSize: 13.5, color: muted),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => _open(found),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        backgroundColor: brand,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Написать'),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            'Для проверки введите +7 777 123 45 67: это демонстрационный '
            'контакт вне вашей команды.',
            style: TextStyle(fontSize: 12.5, color: muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
