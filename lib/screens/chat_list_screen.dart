import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'chat_screen.dart';

/// Группа «Отчёты команды» и личные чаты с каждым участником.
/// Сотрудники могут писать друг другу, руководителю и собственнику.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const Text(
            'Чаты',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Группа'),
          const SizedBox(height: 8),
          _ChatTile(
            chatId: groupChatId,
            leading: const CircleAvatar(
              radius: 23,
              backgroundColor: brandDark,
              child: Icon(Icons.groups_outlined, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Личные'),
          const SizedBox(height: 8),
          for (final user in state.otherUsers) ...[
            _ChatTile(
              chatId: state.directChatId(user.id),
              leading: Avatar(user: user, size: 46),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          const Text(
            'Сотрудники пишут друг другу и руководителям. '
            'В любой чат можно переслать задачу или готовый отчёт.',
            style: TextStyle(fontSize: 13, color: muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: muted,
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.chatId, required this.leading});

  final String chatId;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final last = state.lastMessage(chatId);
    final isGroup = chatId == groupChatId;

    String preview = 'Пока нет сообщений';
    if (last != null) {
      final text = state.previewOf(last);
      preview = isGroup && last.type == MessageType.text
          ? '${state.userById(last.senderId).name}: $text'
          : text;
    }

    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(chatId: chatId),
        ),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.chatTitle(chatId),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (last != null)
                      Text(
                        hhmm(last.sentAt),
                        style: const TextStyle(fontSize: 12.5, color: muted),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
