import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../ru.dart';
import '../theme.dart';
import '../widgets.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

/// Группа «Отчёты команды» и личные чаты с каждым участником.
/// Сотрудники могут писать друг другу, руководителю и собственнику,
/// а также найти человека по номеру телефона и начать новый чат.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Row(
            children: [
              const Expanded(child: ScreenTitle('Чаты')),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const NewChatScreen()),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Новый чат'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionLabel('Группа'),
          const SizedBox(height: 8),
          _ChatTile(
            chatId: groupChatId,
            leading: const CircleAvatar(
              radius: 22,
              backgroundColor: brandDark,
              child: Icon(Icons.groups_outlined, color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel('Личные'),
          const SizedBox(height: 8),
          for (final user in state.chatPartners) ...[
            _ChatTile(
              chatId: state.directChatId(user.id),
              leading: Avatar(user: user, size: 44),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          const Text(
            'В любой чат можно переслать задачу или готовый отчёт '
            'и создать тему, которая закрепится сверху.',
            style: TextStyle(fontSize: 12.5, color: muted, height: 1.45),
          ),
        ],
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
    final topicCount = state.topicsOf(chatId).length;

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
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (last != null)
                      Text(
                        hhmm(last.sentAt),
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: muted),
                ),
                if (topicCount > 0) ...[
                  const SizedBox(height: 6),
                  Tag(
                    icon: Icons.push_pin_outlined,
                    text: '$topicCount '
                        '${plural(topicCount, 'тема', 'темы', 'тем')}',
                    bg: brandSoft,
                    fg: brandDark,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
