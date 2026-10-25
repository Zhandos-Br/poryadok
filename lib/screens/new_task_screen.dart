import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets.dart';

/// Новая задача или должностная обязанность.
///
/// Обычно открывается из чата кнопкой «Поставить задачу»: тогда в личном
/// чате исполнитель уже выбран, а после «Поставить» задача приходит в этот
/// же чат сообщением. Из вкладки «Команда» исполнителей выбирают здесь,
/// и задача приходит каждому в личный чат с вами.
class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({
    super.key,
    this.assigneeId,
    this.chatId,
    this.topicId,
  });

  /// Исполнитель, если задача ставится в личном чате.
  final String? assigneeId;

  /// Чат, куда отправить сообщение с задачей.
  final String? chatId;
  final String? topicId;

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _title = TextEditingController();
  late final Set<String> _assignees = {
    if (widget.assigneeId != null) widget.assigneeId!,
  };
  final Set<ReportKind> _kinds = {ReportKind.photo};
  TimeOfDay _time = const TimeOfDay(hour: 17, minute: 0);
  Repeat _repeat = Repeat.once;
  bool _tomorrow = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool get _valid =>
      _title.text.trim().isNotEmpty &&
      _assignees.isNotEmpty &&
      _kinds.isNotEmpty;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _create() {
    final state = context.read<AppState>();
    final now = DateTime.now();
    final day = DateTime(
      now.year,
      now.month,
      now.day + (_repeat == Repeat.once && _tomorrow ? 1 : 0),
    );
    final due = DateTime(day.year, day.month, day.day, _time.hour, _time.minute);

    final created = state.addTask(
      title: _title.text.trim(),
      assigneeIds: _assignees.toList(),
      due: due,
      requiredKinds: Set.of(_kinds),
      repeat: _repeat,
    );

    // Задача приходит исполнителю сообщением в чате.
    final inChat = widget.chatId;
    for (final task in created) {
      final target = inChat ?? state.directChatId(task.assigneeId);
      state.shareTask(
        target,
        task.id,
        topicId: inChat == null ? null : widget.topicId,
      );
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created.length == 1
              ? 'Задача отправлена: ${state.userById(created.first.assigneeId).name}'
              : 'Задача отправлена: ${created.length} чел.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fixed = widget.assigneeId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Новая задача')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const _Label('Что нужно сделать'),
          TextField(
            controller: _title,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: _fieldDecoration('Например: протереть витрину'),
          ),
          const SizedBox(height: 18),
          const _Label('Кому'),
          if (fixed)
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Avatar(user: state.userById(widget.assigneeId!), size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.userById(widget.assigneeId!).name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          state.userById(widget.assigneeId!).position,
                          style: const TextStyle(fontSize: 12.5, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in state.employees)
                  FilterChip(
                    label: Text(e.name),
                    selected: _assignees.contains(e.id),
                    onSelected: (on) => setState(() {
                      if (on) {
                        _assignees.add(e.id);
                      } else {
                        _assignees.remove(e.id);
                      }
                    }),
                  ),
              ],
            ),
          const SizedBox(height: 18),
          const _Label('Как часто'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in Repeat.values)
                ChoiceChip(
                  label: Text(r.label),
                  selected: _repeat == r,
                  onSelected: (_) => setState(() => _repeat = r),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _repeat == Repeat.once
                ? 'Задача выполняется один раз.'
                : 'Станет должностной обязанностью: будет приходить '
                    'сотруднику по расписанию.',
            style: const TextStyle(fontSize: 12.5, color: muted, height: 1.4),
          ),
          if (_repeat == Repeat.once) ...[
            const SizedBox(height: 14),
            const _Label('Когда'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Сегодня'),
                  selected: !_tomorrow,
                  onSelected: (_) => setState(() => _tomorrow = false),
                ),
                ChoiceChip(
                  label: const Text('Завтра'),
                  selected: _tomorrow,
                  onSelected: (_) => setState(() => _tomorrow = true),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: const Text('Выполнить до'),
            trailing: Text(
              '${_time.hour.toString().padLeft(2, '0')}:'
              '${_time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            onTap: _pickTime,
          ),
          const SizedBox(height: 10),
          const _Label('Что сдать в отчёте'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in ReportKind.values)
                FilterChip(
                  avatar: Icon(k.icon, size: 18),
                  label: Text(k.label),
                  selected: _kinds.contains(k),
                  onSelected: (on) => setState(() {
                    if (on) {
                      _kinds.add(k);
                    } else {
                      _kinds.remove(k);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _valid ? _create : null,
              style: FilledButton.styleFrom(
                backgroundColor: brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.send),
              label: const Text(
                'Прикрепить и отправить',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: paletteOf(context).card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC5CFD8)),
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
