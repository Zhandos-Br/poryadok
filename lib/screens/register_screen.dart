import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets.dart';
import 'login_screen.dart';

/// Первый экран приложения. Все регистрируются одинаково, как обычные
/// пользователи: ФИО, никнейм, телефон, фото, при желании паспорт.
/// Телефон это идентификатор: по нему человека находят и приглашают.
///
/// Дальше два пути:
/// 1. Руководитель или собственник ставит галочку и указывает компанию.
/// 2. Сотрудник вводит код приглашения от руководителя или собственника.
///    Без кода остаётся личный аккаунт, приглашение можно принять позже.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _nick = TextEditingController();
  final _phone = TextEditingController();
  final _passport = TextEditingController();
  final _invite = TextEditingController();
  final _company = TextEditingController();
  final _bin = TextEditingController();
  Uint8List? _photo;
  String? _error;
  bool _business = false;
  Role _businessRole = Role.owner;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _nick, _phone, _company, _bin, _passport, _invite]) {
      c.addListener(() => setState(() => _error = null));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nick.dispose();
    _phone.dispose();
    _passport.dispose();
    _invite.dispose();
    _company.dispose();
    _bin.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().split(RegExp(r'\s+')).length >= 2 &&
      _nick.text.trim().replaceFirst('@', '').length >= 3 &&
      _phone.text.replaceAll(RegExp(r'\D'), '').length >= 10 &&
      (!_business ||
          (_company.text.trim().isNotEmpty && _bin.text.length == 12)) &&
      (!_needPassport || _passport.text.trim().length >= 6);

  /// Паспорт обязателен тем, кто вступает в компанию по коду.
  bool get _needPassport => !_business && _invite.text.trim().isNotEmpty;

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _photo = bytes);
  }

  void _submit() {
    final error = context.read<AppState>().register(
          fullName: _name.text,
          nickname: _nick.text,
          phone: _phone.text,
          passport: _passport.text,
          invite: _invite.text,
          photo: _photo,
          isBusiness: _business,
          companyName: _company.text,
          bin: _bin.text,
          businessRole: _businessRole,
        );
    if (error != null) setState(() => _error = error);
    // При успехе приложение само откроет чат.
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
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lineColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: brand,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Порядок',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Регистрация',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Телефон — ваш идентификатор. По нему вас найдут коллеги '
              'и пригласят в компанию.',
              style: TextStyle(fontSize: 14, color: muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: brandSoft,
                    backgroundImage:
                        _photo == null ? null : MemoryImage(_photo!),
                    child: _photo == null
                        ? const Icon(Icons.person_outline,
                            size: 36, color: brandDark)
                        : null,
                  ),
                  TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(
                      _photo == null ? 'Добавить фото' : 'Изменить фото',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _decoration(
                'ФИО',
                hint: 'Фамилия Имя Отчество',
                icon: Icons.badge_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nick,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_.@]')),
              ],
              decoration: _decoration(
                'Никнейм',
                hint: 'например, aigerim_k',
                icon: Icons.alternate_email,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()\-]')),
              ],
              decoration: _decoration(
                'Номер телефона',
                hint: '+7 777 123 45 67',
                icon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passport,
              decoration: _decoration(
                _needPassport
                    ? 'Паспортные данные (обязательно)'
                    : 'Паспортные данные (необязательно)',
                hint: 'Серия и номер',
                icon: Icons.credit_card_outlined,
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Для обычного аккаунта паспорт не нужен. Чтобы стать сотрудником '
                'компании, его нужно указать: он закрепляется за компанией '
                'вместе с номером телефона. В рабочей версии он хранится '
                'зашифрованным.',
                style: TextStyle(fontSize: 12, color: muted, height: 1.4),
              ),
            ),
            const SizedBox(height: 18),
            Panel(
              padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.only(left: 10),
                controlAffinity: ListTileControlAffinity.leading,
                value: _business,
                onChanged: (v) => setState(() {
                  _business = v ?? false;
                  _error = null;
                }),
                title: const Text(
                  'Я руководитель или собственник бизнеса',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Создам компанию и приглашу сотрудников',
                  style: TextStyle(fontSize: 12.5, color: muted),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_business) ...[
              TextField(
                controller: _company,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  'Название компании',
                  hint: 'Например: Магазин «Рассвет»',
                  icon: Icons.storefront_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bin,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: _decoration(
                  'БИН компании',
                  hint: '12 цифр',
                  icon: Icons.numbers,
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Укажите БИН компании, которой вы владеете или которой '
                  'управляете. Сотрудники будут привязаны к ней по этому БИН.',
                  style: TextStyle(fontSize: 12, color: muted, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<Role>(
                segments: const [
                  ButtonSegment(
                    value: Role.owner,
                    label: Text('Собственник'),
                    icon: Icon(Icons.bar_chart),
                  ),
                  ButtonSegment(
                    value: Role.manager,
                    label: Text('Руководитель'),
                    icon: Icon(Icons.groups_outlined),
                  ),
                ],
                selected: {_businessRole},
                onSelectionChanged: (s) =>
                    setState(() => _businessRole = s.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Собственник и руководитель могут быть разными людьми: '
                  'второго можно пригласить в компанию по номеру телефона. '
                  'Оба видят отчёты и рейтинг.',
                  style: TextStyle(fontSize: 12, color: muted, height: 1.4),
                ),
              ),
            ] else ...[
              TextField(
                controller: _invite,
                textCapitalization: TextCapitalization.characters,
                decoration: _decoration(
                  'Код приглашения (если есть)',
                  hint: 'Код от руководителя',
                  icon: Icons.vpn_key_outlined,
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Код присылает руководитель или собственник на ваш номер. '
                  'Введите его, и вы сразу окажетесь в команде. '
                  'Если вас уже пригласили на этот номер, приглашение '
                  'придёт в чаты после регистрации.',
                  style: TextStyle(fontSize: 12, color: muted, height: 1.4),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(fontSize: 13.5, color: badColor),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _valid ? _submit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: brand,
              ),
              child: const Text('Зарегистрироваться'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              ),
              child: const Text('Уже есть аккаунт? Войти по номеру'),
            ),
          ],
        ),
      ),
    );
  }
}
