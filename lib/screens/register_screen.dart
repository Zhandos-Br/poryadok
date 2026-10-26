import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets.dart';
import 'login_screen.dart';

/// Первый экран приложения. Регистрация короткая, в два шага:
/// 1. Номер телефона и код из SMS.
/// 2. Имя. Руководитель и собственник ещё указывают название компании.
/// Паспорт и БИН не спрашиваются сразу: приложение попросит их позже,
/// когда они действительно понадобятся.
///
/// Если человек пришёл по ссылке из WhatsApp, код приглашения и номер
/// подставляются сами (параметры invite и phone в адресе).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _invite = TextEditingController();
  final _company = TextEditingController();
  bool _codeSent = false;
  bool _confirmed = false;
  bool _business = false;
  Role _businessRole = Role.owner;
  String? _error;

  @override
  void initState() {
    super.initState();
    final q = Uri.base.queryParameters;
    _invite.text = (q['invite'] ?? '').toUpperCase();
    _phone.text = q['phone'] == null ? '' : '+${q['phone']}';
    for (final c in [_phone, _code, _name, _invite, _company]) {
      c.addListener(() => setState(() => _error = null));
    }
    _phone.addListener(() => _codeSent = false);
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _name.dispose();
    _invite.dispose();
    _company.dispose();
    super.dispose();
  }

  bool get _phoneOk => _phone.text.replaceAll(RegExp(r'\D'), '').length >= 10;

  bool get _nameOk =>
      _name.text.trim().length >= 2 &&
      (!_business || _company.text.trim().isNotEmpty);

  void _sendCode() => setState(() => _codeSent = true);

  void _confirm() {
    if (_code.text.trim() != AppState.demoSmsCode) {
      setState(() => _error = 'Неверный код из SMS');
      return;
    }
    setState(() => _confirmed = true);
  }

  void _submit() {
    final error = context.read<AppState>().register(
          fullName: _name.text,
          nickname: '',
          phone: _phone.text,
          invite: _invite.text,
          isBusiness: _business,
          companyName: _company.text,
          businessRole: _businessRole,
          quick: true,
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
    final fromLink = _invite.text.isNotEmpty;
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
            Text(
              _confirmed ? 'Как вас зовут?' : 'Вход по номеру телефона',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _confirmed
                  ? 'Это всё. Остальное приложение спросит позже, если понадобится.'
                  : fromLink
                      ? 'Вас пригласили в команду. Подтвердите номер, и вы '
                          'сразу окажетесь в ней.'
                      : 'Телефон — ваш идентификатор. По нему вас найдут '
                          'коллеги и пригласят в компанию.',
              style: const TextStyle(fontSize: 14, color: muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            if (!_confirmed) ...[
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()\-]')),
                ],
                decoration: _decoration(
                  'Номер телефона',
                  hint: '+7 777 123 45 67',
                  icon: Icons.phone_outlined,
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: _decoration(
                    'Код из SMS',
                    hint: 'В демо: ${AppState.demoSmsCode}',
                    icon: Icons.sms_outlined,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 13.5, color: badColor),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: !_phoneOk
                    ? null
                    : !_codeSent
                        ? _sendCode
                        : _code.text.length == 4
                            ? _confirm
                            : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: brand,
                ),
                child: Text(_codeSent ? 'Подтвердить' : 'Получить код'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Уже есть аккаунт? Войти'),
              ),
            ] else ...[
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(
                  'Имя и фамилия',
                  hint: 'Например: Айгерим Касымова',
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(height: 14),
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
                    'БИН компании можно указать позже в настройках. '
                    'Собственник и руководитель могут быть разными людьми: '
                    'второго можно пригласить по номеру телефона.',
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
                onPressed: _nameOk ? _submit : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: brand,
                ),
                child: const Text('Готово'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
