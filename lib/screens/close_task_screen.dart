import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

/// Закрытие задачи: фото, видео, голос и комментарий.
/// Что обязательно, задаёт руководитель в самой задаче.
class CloseTaskScreen extends StatefulWidget {
  const CloseTaskScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<CloseTaskScreen> createState() => _CloseTaskScreenState();
}

class _CloseTaskScreenState extends State<CloseTaskScreen> {
  final _picker = ImagePicker();
  final _comment = TextEditingController();

  /// Что уже приложено: вид отчёта → путь к файлу.
  final Map<ReportKind, String> _media = {};

  @override
  void initState() {
    super.initState();
    _comment.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null) setState(() => _media[ReportKind.photo] = file.path);
  }

  Future<void> _addVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
    );
    if (file != null) setState(() => _media[ReportKind.video] = file.path);
  }

  /// Заглушка. Для настоящей записи голоса подключите пакет `record`
  /// и сохраняйте путь к файлу так же, как для фото и видео.
  void _toggleAudio() {
    setState(() {
      if (_media.containsKey(ReportKind.audio)) {
        _media.remove(ReportKind.audio);
      } else {
        _media[ReportKind.audio] = 'TODO-record-audio';
      }
    });
  }

  bool _canSend(TaskItem task) {
    return task.requiredKinds.every((k) {
      if (k == ReportKind.text) return _comment.text.trim().isNotEmpty;
      return _media.containsKey(k);
    });
  }

  void _send(TaskItem task) {
    final kinds = <ReportKind>{..._media.keys};
    if (_comment.text.trim().isNotEmpty) kinds.add(ReportKind.text);

    context.read<AppState>().submitReport(
          taskId: task.id,
          kinds: kinds,
          comment: _comment.text.trim(),
          media: Map.of(_media),
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Отчёт отправлен в общий чат')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = context.watch<AppState>().taskById(widget.taskId);
    final canSend = _canSend(task);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            task.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'До ${hhmm(task.due)}',
            style: const TextStyle(color: muted, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const Text(
            'ЧТО СДАТЬ В ОТЧЁТЕ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: muted,
            ),
          ),
          const SizedBox(height: 10),
          _MediaTile(
            kind: ReportKind.photo,
            title: 'Сделать фото',
            doneTitle: 'Фото добавлено',
            isRequired: task.requiredKinds.contains(ReportKind.photo),
            attached: _media.containsKey(ReportKind.photo),
            onTap: _addPhoto,
            onRemove: () => setState(() => _media.remove(ReportKind.photo)),
          ),
          const SizedBox(height: 10),
          _MediaTile(
            kind: ReportKind.audio,
            title: 'Записать голосовое',
            doneTitle: 'Голосовое добавлено',
            isRequired: task.requiredKinds.contains(ReportKind.audio),
            attached: _media.containsKey(ReportKind.audio),
            onTap: _toggleAudio,
            onRemove: _toggleAudio,
          ),
          const SizedBox(height: 10),
          _MediaTile(
            kind: ReportKind.video,
            title: 'Снять видео',
            doneTitle: 'Видео добавлено',
            isRequired: task.requiredKinds.contains(ReportKind.video),
            attached: _media.containsKey(ReportKind.video),
            onTap: _addVideo,
            onRemove: () => setState(() => _media.remove(ReportKind.video)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'Комментарий',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              if (task.requiredKinds.contains(ReportKind.text)) ...[
                const SizedBox(width: 8),
                const Tag(text: 'Обязательно', bg: Color(0xFFFFF1D6), fg: warnColor),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Например: убрали две позиции, остальное в норме',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFC5CFD8)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!canSend)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Добавьте всё обязательное, чтобы отправить отчёт',
                textAlign: TextAlign.center,
                style: TextStyle(color: warnColor, fontWeight: FontWeight.w500),
              ),
            ),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: canSend ? () => _send(task) : null,
              style: FilledButton.styleFrom(
                backgroundColor: brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Отправить отчёт',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.kind,
    required this.title,
    required this.doneTitle,
    required this.isRequired,
    required this.attached,
    required this.onTap,
    required this.onRemove,
  });

  final ReportKind kind;
  final String title;
  final String doneTitle;
  final bool isRequired;
  final bool attached;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (attached) {
      return Panel(
        borderColor: okColor,
        onTap: onRemove,
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFDDF5E7),
              child: Icon(Icons.check, color: okColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doneTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Нажмите, чтобы убрать',
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Panel(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE9EEF2),
            child: Icon(kind.icon, color: const Color(0xFF3B4C5B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isRequired ? 'Обязательно' : 'По желанию',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isRequired ? FontWeight.w600 : FontWeight.w400,
                    color: isRequired ? warnColor : muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
