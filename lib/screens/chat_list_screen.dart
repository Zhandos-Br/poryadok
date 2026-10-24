import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../ru.dart';
import '../theme.dart';
import '../widgets.dart';
import 'chat_screen.dart';
import 'invite_screen.dart';
import 'new_chat_screen.dart';

/// Группа «Отчёты команды» и личные чаты с каждым участником.
/// Сотрудники могут писать друг другу, руководителю и собственнику,
/// а также найти человека по номеру телефона и начать новый чат.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final groupId = state.myGroupChatId;
    final invites = state.pendingInvitesForMe;
    final partners = state.chatPartners;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: ScreenTitle(
                  state.myCompany == null ? 'Чаты' : state.myCompany!.name,
                ),
              ),
              IconButton(
                tooltip: 'Новый чат',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const NewChatScreen()),
                ),
                icon: const Icon(Icons.edit_outlined),
              ),
              PopupMenuButton<String>(
                tooltip: 'Меню',
                onSelected: (v) {
                  if (v == 'logout') {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    context.read<AppState>().signOut();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text('${state.me.name} · ${state.me.role.label}'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Выйти из аккаунта'),
                  ),
                ],
              ),
            ],
          ),
          if (state.myCompany != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${state.me.role.label} · ${state.me.name}',
                style: const TextStyle(fontSize: 13, color: muted),
              ),
            ),
          const SizedBox(height: 14),
          for (final invite in invites) ...[
            _InviteCard(invite: invite),
            const SizedBox(height: 10),
          ],
          if (state.canManage) ...[
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const InviteScreen()),
              ),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: const Text('Пригласить сотрудника по номеру'),
            ),
            const SizedBox(height: 14),
          ],
          if (groupId != null) ...[
            const SectionLabel('Группа'),
            const SizedBox(height: 8),
            _ChatTile(
              chatId: groupId,
              leading: const CircleAvatar(
                radius: 22,
                backgroundColor: brandDark,
                child: Icon(Icons.groups_outlined, color: Colors.white),
              ),
            ),
            const SizedBox(height: 18),
          ],
          const SectionLabel('Личные'),
          const SizedBox(height: 8),
          if (partners.isEmpty)
            const Panel(
              child: Text(
                'Чатов пока нет. Нажмите карандаш сверху и найдите человека '
                'по номеру телефона.',
                style: TextStyle(fontSize: 13.5, color: muted, height: 1.4),
              ),
            ),
          for (final user in partners) ...[
            _ChatTile(
              chatId: state.directChatId(user.id),
              leading: Avatar(user: user, size: 44),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Text(
            state.canManage
                ? 'Задачи ставятся в чате: откройте чат с сотрудником и '
                    'нажмите «Поставить задачу». В любой чат можно переслать '
                    'отчёт и создать тему, которая закрепится сверху.'
                : state.me.companyId == null
                    ? 'Вы пока не в компании. Попросите руководителя или '
                        'собственника пригласить вас по номеру '
                        '${state.me.phone}.'
                    : 'Новые задачи приходят сюда, в чат. Отчёты по ним '
                        'сдаются во вкладке «Сегодня».',
            style: const TextStyle(fontSize: 12.5, color: muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.invite});

  final CompanyInvite invite;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final company = state.companyById(invite.companyId);
    final from = state.userById(invite.createdById);

    return Panel(
      color: brandSoft,
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline, color: brandDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Приглашение в «${company?.name ?? ''}»',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: brandDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${from.name} приглашает вас как: ${invite.role.label.toLowerCase()}. '
            'После согласия вы сразу окажетесь в команде.',
            style: const TextStyle(fontSize: 13, color: brandDark, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => state.acceptInvite(invite.id),
                  style: FilledButton.styleFrom(backgroundColor: brand),
                  child: const Text('Принять'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => state.declineInvite(invite.id),
                  child: const Text('Отклонить'),
                ),
              ),
            ],
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
    final isGroup = isGroupChat(chatId);
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
