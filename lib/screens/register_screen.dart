import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home_shell.dart';

/// Регистрация: ФИО, никнейм, телефон, фото, при необходимости паспорт.
/// Телефон это идентификатор: по нему человека находят другие участники.
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
  Uint8List? _photo;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _nick, _phone]) {
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
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().split(RegExp(r'\s+')).length >= 2 &&
      _nick.text.trim().replaceFirst('@', '').length >= 3 &&
      _phone.text.replaceAll(RegExp(r'\D'), '').length >= 10;

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
        );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeShell()),
      (route) => route.isFirst,
    );
  }

  InputDecoration _decoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
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
      appBar: AppBar(title: const Text('Регистрация')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: brandSoft,
                  backgroundImage: _photo == null ? null : MemoryImage(_photo!),
                  child: _photo == null
                      ? const Icon(Icons.person_outline,
                          size: 40, color: brandDark)
                      : null,
                ),
                TextButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: Text(_photo == null ? 'Добавить фото' : 'Изменить фото'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
            controller: _invite,
            textCapitalization: TextCapitalization.characters,
            decoration: _decoration(
              'Код приглашения (необязательно)',
              hint: 'Код от руководителя',
              icon: Icons.vpn_key_outlined,
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'С кодом вы попадёте в команду. Без кода получите личный '
              'аккаунт для переписки. Для проверки: PORYADOK.',
              style: TextStyle(fontSize: 12, color: muted, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passport,
            decoration: _decoration(
              'Паспортные данные (необязательно)',
              hint: 'Серия и номер',
              icon: Icons.credit_card_outlined,
            ),
          ),
          const SizedBox(height: 8),
          const Panel(
            color: brandSoft,
            borderColor: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 18, color: brandDark),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Паспортные данные нужны только если их требует '
                    'работодатель. В рабочей версии их нужно хранить '
                    'зашифрованными и показывать только собственнику.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: brandDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
              minimumSize: const Size.fromHeight(50),
              backgroundColor: brand,
            ),
            child: const Text('Зарегистрироваться'),
          ),
        ],
      ),
    );
  }
}
