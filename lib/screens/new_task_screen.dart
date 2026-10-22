import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

/// Новая задача или должностная обязанность (повторяется каждый день).
class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _title = TextEditingController();
  final Set<String> _assignees = {};
  final Set<ReportKind> _kinds = {ReportKind.photo};
  TimeOfDay _time = const TimeOfDay(hour: 17, minute: 0);
  bool _daily = false;

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
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _create() {
    final now = DateTime.now();
    final due = DateTime(now.year, now.month, now.day, _time.hour, _time.minute);

    context.read<AppState>().addTask(
          title: _title.text.trim(),
          assigneeIds: _assignees.toList(),
          due: due,
          requiredKinds: Set.of(_kinds),
          repeatDaily: _daily,
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Задача поставлена')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<AppState>().employees;

    return Scaffold(
      appBar: AppBar(title: const Text('Новая задача')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const _Label('Что нужно сделать'),
          TextField(
            controller: _title,
            decoration: _fieldDecoration('Например: протереть витрину'),
          ),
          const SizedBox(height: 18),
          const _Label('Кому'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in employees)
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Повторять каждый день'),
            subtitle: const Text('Станет должностной обязанностью'),
            value: _daily,
            onChanged: (v) => setState(() => _daily = v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: const Text('Выполнить до'),
            trailing: Text(
              _time.format(context),
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
            child: FilledButton(
              onPressed: _valid ? _create : null,
              style: FilledButton.styleFrom(
                backgroundColor: brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Поставить задачу',
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
        fillColor: Colors.white,
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
