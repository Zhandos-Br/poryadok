import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

/// Один чат: общий или личный. Работает одинаково для всех ролей.
/// Кнопка «+» пересылает в чат задачу или готовый отчёт.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final String chatId;

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
    context.read<AppState>().sendText(widget.chatId, text);
    _controller.clear();
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
      state.shareTask(widget.chatId, taskId);
    } else {
      state.shareReport(widget.chatId, taskId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isGroup = widget.chatId == groupChatId;
    final messages = state.messagesOf(widget.chatId).reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFE5ECE9),
      appBar: AppBar(
        backgroundColor: brandDark,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.chatTitle(widget.chatId),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            Text(
              isGroup
                  ? 'Все участники команды'
                  : state.userById(state.otherParticipant(widget.chatId)).position,
              style: const TextStyle(fontSize: 13, color: Color(0xFFCFE8E4)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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
                      backgroundColor: Colors.white,
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
                        hintText: 'Сообщение',
                        filled: true,
                        fillColor: Colors.white,
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
            color: mine ? const Color(0xFFD5F0E4) : Colors.white,
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
                      fontWeight: FontWeight.w600,
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
                    style: const TextStyle(fontSize: 15, height: 1.3),
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
    } else {
      status = 'До ${hhmm(task.due)} · в работе';
      statusColor = warnColor;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: lineColor),
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
                  fontWeight: FontWeight.w600,
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          if (canRate) ...[
            const Divider(height: 16),
            Row(
              children: [
                const Text(
                  'Оценка',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
    );
  }
}
