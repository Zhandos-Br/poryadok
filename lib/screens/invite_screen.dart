import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../models.dart';
import '../ru.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets.dart';

/// Приглашение в компанию по номеру телефона.
/// Приглашать может только руководитель или собственник.
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final _phone = TextEditingController();
  final _position = TextEditingController();
  Role _role = Role.employee;
  String? _error;
  InviteResult? _result;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {
          _error = null;
          _result = null;
        }));
  }

  @override
  void dispose() {
    _phone.dispose();
    _position.dispose();
    super.dispose();
  }

  bool get _valid => _phone.text.replaceAll(RegExp(r'\D'), '').length >= 10;

  void _send() {
    final result = context.read<AppState>().createInvite(
          phone: _phone.text,
          role: _role,
          position: _position.text,
        );
    setState(() {
      _error = result.error;
      _result = result.error == null ? result : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final result = _result;
    final sent = state.sentInvites;

    return Scaffold(
      appBar: AppBar(title: const Text('Пригласить в компанию')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Компания: ${state.myCompany?.name ?? ''}',
            style: const TextStyle(fontSize: 14, color: muted),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()\-]')),
            ],
            decoration: _decoration(
              'Номер телефона',
              hint: '+7 700 555 11 22',
              icon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _position,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoration(
              'Должность (необязательно)',
              hint: 'Например: продавец',
              icon: Icons.work_outline,
            ),
          ),
          const SizedBox(height: 14),
          const SectionLabel('Кого приглашаете'),
          const SizedBox(height: 8),
          SegmentedButton<Role>(
            segments: const [
              ButtonSegment(value: Role.employee, label: Text('Сотрудник')),
              ButtonSegment(value: Role.manager, label: Text('Руководитель')),
              ButtonSegment(value: Role.owner, label: Text('Собственник')),
            ],
            selected: {_role},
            onSelectionChanged: (s) => setState(() => _role = s.first),
            showSelectedIcon: false,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(fontSize: 13.5, color: badColor),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _valid ? _send : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: brand,
            ),
            icon: const Icon(Icons.send_outlined, size: 20),
            label: const Text('Отправить приглашение'),
          ),
          if (result != null && result.invite != null) ...[
            const SizedBox(height: 16),
            Panel(
              color: toneGood.bg,
              borderColor: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.userExists
                        ? 'Приглашение отправлено'
                        : 'Номер ещё не зарегистрирован',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: toneGood.fg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.userExists
                        ? 'Человек уже в приложении: приглашение придёт ему '
                            'в чаты. Когда он согласится, сразу окажется '
                            'в команде.'
                        : 'Отправьте ему этот код по SMS или в мессенджере. '
                            'Он введёт код при регистрации и сразу '
                            'окажется в команде.',
                    style: TextStyle(
                      fontSize: 13,
                      color: toneGood.fg,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          result.invite!.code,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Скопировать код',
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: result.invite!.code),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Код скопирован')),
                          );
                        },
                        icon: const Icon(Icons.copy_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        context.read<AppState>().whatsappLink(result.invite!),
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1FA855),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: const Text('Отправить ссылку в WhatsApp'),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(
                        text: context
                            .read<AppState>()
                            .inviteMessage(result.invite!),
                      ));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Приглашение скопировано')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Скопировать ссылку'),
                  ),
                ],
              ),
            ),
          ],
          if (sent.isNotEmpty) ...[
            const SizedBox(height: 24),
            SectionLabel('Отправленные · ${sent.length}'),
            const SizedBox(height: 8),
            for (final i in sent) ...[
              _InviteRow(invite: i),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: paletteOf(context).card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lineColor),
      ),
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.invite});

  final CompanyInvite invite;

  @override
  Widget build(BuildContext context) {
    final (String text, Tone tone) = switch (invite.status) {
      InviteStatus.pending => ('Ждёт ответа', toneMid),
      InviteStatus.accepted => ('В команде', toneGood),
      InviteStatus.declined => ('Отклонено', toneBad),
    };
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.phone,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${invite.role.label} · код ${invite.code} · '
                  '${invite.createdAt.day} ${ruMonthsGenitive[invite.createdAt.month - 1]}',
                  style: const TextStyle(fontSize: 12.5, color: muted),
                ),
              ],
            ),
          ),
          Tag(text: text, bg: tone.bg, fg: tone.fg),
        ],
      ),
    );
  }
}
