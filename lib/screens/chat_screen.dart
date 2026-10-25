import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets.dart';
import 'close_task_screen.dart';
import 'new_task_screen.dart';

/// Один чат: общий или личный. Работает одинаково для всех ролей.
/// Кнопка «+» пересылает в чат задачу или готовый отчёт.
///
/// Сверху закреплены темы чата. Тема это отдельная переписка внутри
/// группы или личного чата: сообщения темы не попадают в основную ленту.
/// Если указан [topicId], экран показывает именно эту тему.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId, this.topicId});

  final String chatId;
  final String? topicId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context
        .read<AppState>()
        .sendText(widget.chatId, text, topicId: widget.topicId);
    _controller.clear();
  }

  void _assignTask() {
    final state = context.read<AppState>();
    final personal = !isGroupChat(widget.chatId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NewTaskScreen(
          assigneeId: personal ? state.otherParticipant(widget.chatId) : null,
          chatId: widget.chatId,
          topicId: widget.topicId,
        ),
      ),
    );
  }

  Future<void> _attach() async {
    final state = context.read<AppState>();

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.checklist),
              title: const Text('Поделиться задачей'),
              subtitle: const Text('Коллега увидит срок и статус'),
              onTap: () => Navigator.pop(ctx, 'task'),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in_outlined),
              title: const Text('Поделиться отчётом'),
              subtitle: const Text('С фото, видео и комментарием'),
              onTap: () => Navigator.pop(ctx, 'report'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    final isTask = action == 'task';
    final options =
        state.tasksVisibleToMe.where((t) => isTask || t.done).toList();

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTask ? 'Нет задач' : 'Пока нет сданных отчётов'),
        ),
      );
      return;
    }

    final taskId = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(isTask ? 'Выберите задачу' : 'Выберите отчёт'),
        children: [
          for (final t in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t.id),
              child: Text(t.title),
            ),
        ],
      ),
    );
    if (taskId == null) return;

    if (isTask) {
      state.shareTask(widget.chatId, taskId, topicId: widget.topicId);
    } else {
      state.shareReport(widget.chatId, taskId, topicId: widget.topicId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isGroup = isGroupChat(widget.chatId);
    final topicId = widget.topicId;
    final topic = topicId == null ? null : state.topicById(topicId);
    final messages =
        state.messagesOf(widget.chatId, topicId: topicId).reversed.toList();

    final String title = topic != null
        ? topic.title
        : state.chatTitle(widget.chatId);
    final String subtitle = topic != null
        ? 'Тема · ${state.chatTitle(widget.chatId)}'
        : isGroup
            ? 'Все участники команды'
            : state.userById(state.otherParticipant(widget.chatId)).position;

    return Scaffold(
      backgroundColor: paletteOf(context).surface,
      appBar: AppBar(
        backgroundColor: brandDark,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFFCFE8E4)),
            ),
          ],
        ),
      ),
      body: WallpaperBox(
        index: state.wallpaperIndex,
        child: Column(
        children: [
          if (topic == null) _TopicsStrip(chatId: widget.chatId),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: messages.length,
              itemBuilder: (_, i) => _Bubble(
                message: messages[i],
                showName: isGroup,
              ),
            ),
          ),
          if (state.canAssignIn(widget.chatId))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: const Icon(Icons.add_task, size: 18, color: brandDark),
                  label: const Text('Поставить задачу'),
                  backgroundColor: paletteOf(context).card,
                  onPressed: _assignTask,
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Row(
                children: [
                  IconButton.filled(
                    onPressed: _attach,
                    tooltip: 'Прикрепить задачу или отчёт',
                    style: IconButton.styleFrom(
                      backgroundColor: paletteOf(context).card,
                      foregroundColor: brandDark,
                    ),
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: topic == null
                            ? 'Сообщение'
                            : 'Сообщение в теме',
                        filled: true,
                        fillColor: paletteOf(context).card,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    tooltip: 'Отправить',
                    style: IconButton.styleFrom(backgroundColor: brand),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

/// Полоса закреплённых тем под заголовком чата.
class _TopicsStrip extends StatelessWidget {
  const _TopicsStrip({required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final topics = state.topicsOf(chatId);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: paletteOf(context).card,
        border: Border(bottom: BorderSide(color: paletteOf(context).line)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.push_pin_outlined, size: 18, color: muted),
            const SizedBox(width: 8),
            for (final t in topics) ...[
              _TopicChip(chatId: chatId, topic: t),
              const SizedBox(width: 8),
            ],
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Новая тема'),
              onPressed: () => createTopicFlow(context, chatId),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.chatId, required this.topic});

  final String chatId;
  final ChatTopic topic;

  @override
  Widget build(BuildContext context) {
    final count = context.watch<AppState>().topicMessageCount(topic.id);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(chatId: chatId, topicId: topic.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: brandSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              topic.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: brandDark,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: brandDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Спрашивает название, создаёт тему и открывает её.
Future<void> createTopicFlow(BuildContext context, String chatId) async {
  final title = await showDialog<String>(
    context: context,
    builder: (_) => const _NewTopicDialog(),
  );
  if (title == null || title.trim().isEmpty || !context.mounted) return;

  final topic = context.read<AppState>().createTopic(chatId, title);
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ChatScreen(chatId: chatId, topicId: topic.id),
    ),
  );
}

class _NewTopicDialog extends StatefulWidget {
  const _NewTopicDialog();

  @override
  State<_NewTopicDialog> createState() => _NewTopicDialogState();
}

class _NewTopicDialogState extends State<_NewTopicDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новая тема'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Например: Новогодний корпоратив',
            ),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
          const SizedBox(height: 10),
          const Text(
            'Тема закрепится вверху чата. Её увидят все участники, '
            'а переписка в ней останется отдельно от основной.',
            style: TextStyle(fontSize: 12.5, color: muted, height: 1.4),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Создать'),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.showName});

  final ChatMessage message;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final mine = message.senderId == state.me.id;
    final sender = state.userById(message.senderId);
    final task =
        message.taskId == null ? null : state.taskById(message.taskId!);

    // Для отчёта в общем чате комментарий уже виден внутри карточки.
    final showText = message.type == MessageType.text ||
        (message.type != MessageType.report &&
            (message.text ?? '').isNotEmpty);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: mine
                ? paletteOf(context).bubbleMine
                : paletteOf(context).bubbleOther,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showName && !mine)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 4),
                  child: Text(
                    sender.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: brandDark,
                    ),
                  ),
                ),
              if (task != null)
                _SharedCard(
                  task: task,
                  isReport: message.type == MessageType.report,
                ),
              if (showText && (message.text ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
                  child: Text(
                    message.text!,
                    style: const TextStyle(fontSize: 14.5, height: 1.3),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, right: 2),
                  child: Text(
                    hhmm(message.sentAt),
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка задачи или отчёта внутри сообщения.
/// Руководитель и собственник могут поставить оценку прямо здесь.
class _SharedCard extends StatelessWidget {
  const _SharedCard({required this.task, required this.isReport});

  final TaskItem task;
  final bool isReport;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final Report? report = isReport ? task.report : null;
    final canRate = report != null && state.me.role != Role.employee;

    String status;
    Color statusColor;
    if (report != null) {
      status = task.onTime
          ? 'Сдан в ${hhmm(report.submittedAt)} · в срок'
          : 'Сдан в ${hhmm(report.submittedAt)} · с опозданием';
      statusColor = task.onTime ? okColor : badColor;
    } else if (task.done) {
      status = 'Выполнена';
      statusColor = okColor;
    } else if (task.isOverdue(DateTime.now())) {
      status = 'Просрочена · до ${hhmm(task.due)}';
      statusColor = badColor;
    } else if (!task.accepted) {
      status = '● Ожидает принятия · не в работе · до ${hhmm(task.due)}';
      statusColor = badColor;
    } else {
      status = '● В работе с ${hhmm(task.acceptedAt!)} · до ${hhmm(task.due)}';
      statusColor = warnColor;
    }

    // Свою задачу сотрудник может открыть, принять и выполнить прямо отсюда.
    final mine = !isReport && !task.done && task.assigneeId == state.me.id;

    return Material(
      color: paletteOf(context).card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: mine
            ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CloseTaskScreen(taskId: task.id),
                  ),
                )
            : null,
        child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: paletteOf(context).line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isReport
                    ? Icons.assignment_turned_in_outlined
                    : Icons.checklist,
                size: 16,
                color: brandDark,
              ),
              const SizedBox(width: 6),
              Text(
                isReport ? 'Отчёт' : 'Задача',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: brandDark,
                ),
              ),
              if (isReport) ...[
                const SizedBox(width: 6),
                Text(
                  state.userById(task.assigneeId).name,
                  style: const TextStyle(fontSize: 12.5, color: muted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            task.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          if (report != null) ...[
            const SizedBox(height: 6),
            KindChips(kinds: report.kinds),
            if (report.comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(report.comment, style: const TextStyle(fontSize: 14)),
            ],
          ],
          const SizedBox(height: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
          if (mine && !task.accepted) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => state.acceptTask(task.id),
              style: FilledButton.styleFrom(
                backgroundColor: brand,
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Принять в работу'),
            ),
          ],
          if (mine && task.accepted) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CloseTaskScreen(taskId: task.id),
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(Icons.assignment_turned_in_outlined, size: 20),
              label: const Text('Выполнить и сдать отчёт'),
            ),
          ],
          if (canRate) ...[
            const Divider(height: 16),
            Row(
              children: [
                const Text(
                  'Оценка',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 40,
                    ),
                    tooltip: 'Оценка $i из 5',
                    onPressed: () => state.rate(task.id, i),
                    icon: Icon(
                      i <= (report?.stars ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      color: const Color(0xFFB7791F),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }
}
