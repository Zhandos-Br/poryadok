import 'dart:typed_data';

import 'package:flutter/material.dart';

enum Role { owner, manager, employee }

extension RoleX on Role {
  String get label => switch (this) {
        Role.owner => 'Собственник',
        Role.manager => 'Руководитель',
        Role.employee => 'Сотрудник',
      };
}

/// Из чего может состоять отчёт по задаче.
enum ReportKind { photo, video, audio, text }

extension ReportKindX on ReportKind {
  String get label => switch (this) {
        ReportKind.photo => 'Фото',
        ReportKind.video => 'Видео',
        ReportKind.audio => 'Голос',
        ReportKind.text => 'Текст',
      };

  IconData get icon => switch (this) {
        ReportKind.photo => Icons.photo_camera_outlined,
        ReportKind.video => Icons.videocam_outlined,
        ReportKind.audio => Icons.mic_none,
        ReportKind.text => Icons.notes,
      };
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.position,
    required this.role,
    this.nickname = '',
    this.phone = '',
    this.passport,
    this.photo,
    this.companyId,
  });

  final String id;
  final String name;
  final String position;
  final Role role;

  /// Никнейм без «@».
  final String nickname;

  /// Телефон: по нему человека находят в приложении.
  final String phone;

  /// Паспортные данные. Необязательны, это чувствительная информация.
  final String? passport;

  /// Фото профиля.
  final Uint8List? photo;

  /// Компания, в которой человек состоит. Пусто у обычного пользователя:
  /// с ним можно переписываться, но он не в графике и не в рейтинге.
  final String? companyId;

  /// Человек без компании.
  bool get external => companyId == null;

  AppUser copyWith({
    String? companyId,
    Role? role,
    String? position,
    String? passport,
  }) {
    return AppUser(
      id: id,
      name: name,
      position: position ?? this.position,
      role: role ?? this.role,
      nickname: nickname,
      phone: phone,
      passport: passport ?? this.passport,
      photo: photo,
      companyId: companyId ?? this.companyId,
    );
  }
}

class Company {
  const Company({required this.id, required this.name, required this.bin});

  final String id;
  final String name;

  /// БИН: 12 цифр. По нему сотрудники привязаны к компании.
  final String bin;
}

enum InviteStatus { pending, accepted, declined }

/// Приглашение в компанию. Его создаёт руководитель или собственник
/// на номер телефона. Если человек уже зарегистрирован, приглашение
/// придёт ему в приложение, иначе он введёт код при регистрации.
/// Шаблон повторяющейся задачи: «Открытие магазина», «Закрытие кассы».
class TaskTemplate {
  const TaskTemplate({
    required this.id,
    required this.title,
    required this.kinds,
    this.hour = 17,
    this.minute = 0,
    this.repeat = Repeat.once,
  });

  final String id;
  final String title;
  final Set<ReportKind> kinds;
  final int hour;
  final int minute;
  final Repeat repeat;
}

/// Итоги дня для руководителя и собственника.
class DayDigest {
  const DayDigest({
    required this.total,
    required this.done,
    required this.overdue,
    required this.notAccepted,
    required this.inWork,
  });

  /// Задачи, назначенные на сегодня.
  final int total;
  final int done;

  /// Просроченные и не выполненные (за любые дни).
  final List<TaskItem> overdue;

  /// Не принятые сотрудниками (из серии повторов одна ближайшая).
  final List<TaskItem> notAccepted;

  /// Принятые, ещё не просроченные и не сданные.
  final List<TaskItem> inWork;

  int get percent => total == 0 ? 0 : (done * 100 / total).round();
}

class CompanyInvite {
  CompanyInvite({
    required this.id,
    required this.companyId,
    required this.phone,
    required this.code,
    required this.role,
    required this.position,
    required this.createdById,
    required this.createdAt,
    this.status = InviteStatus.pending,
  });

  final String id;
  final String companyId;
  final String phone;
  final String code;
  final Role role;
  final String position;
  final String createdById;
  final DateTime createdAt;
  InviteStatus status;
}

/// Как часто повторяется задача.
enum Repeat { once, daily, weekdays, weekly, monthly }

extension RepeatX on Repeat {
  String get label => switch (this) {
        Repeat.once => 'Разовая',
        Repeat.daily => 'Каждый день',
        Repeat.weekdays => 'По будням',
        Repeat.weekly => 'Раз в неделю',
        Repeat.monthly => 'Раз в месяц',
      };
}

class Report {
  Report({
    required this.submittedAt,
    required this.kinds,
    this.comment = '',
    this.media = const {},
    this.stars,
  });

  final DateTime submittedAt;
  final Set<ReportKind> kinds;
  final String comment;

  /// Пути к файлам: фото, видео, голос.
  final Map<ReportKind, String> media;

  /// Оценка качества от руководителя или собственника, 1–5.
  int? stars;
}

class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    required this.assigneeId,
    required this.due,
    required this.requiredKinds,
    this.repeat = Repeat.once,
    this.assignedById,
    this.seriesId,
    this.acceptedAt,
    this.report,
  });

  final String id;
  final String title;
  String assigneeId;
  final DateTime due;

  /// Что обязательно сдать в отчёте.
  final Set<ReportKind> requiredKinds;

  /// Периодичность. Повторяющаяся задача это должностная обязанность.
  /// Повторы нужно создавать на сервере (см. README).
  final Repeat repeat;

  bool get repeatDaily => repeat != Repeat.once;

  /// Кто поставил задачу.
  String? assignedById;

  /// Общий номер повторяющихся задач одной серии.
  final String? seriesId;

  /// Когда сотрудник принял задачу в работу. Пока пусто, задача
  /// только отправлена: сам факт отправки не значит, что человек её увидел.
  DateTime? acceptedAt;

  bool get accepted => acceptedAt != null;

  Report? report;

  bool get done => report != null;

  bool isOverdue(DateTime now) => !done && now.isAfter(due);

  bool get onTime => report != null && !report!.submittedAt.isAfter(due);

  /// Сдано всё, что требовалось.
  bool get complete =>
      report != null && report!.kinds.containsAll(requiredKinds);

  DateTime get day => DateTime(due.year, due.month, due.day);
}

enum MessageType { text, task, report }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.sentAt,
    required this.type,
    this.text,
    this.taskId,
    this.topicId,
  });

  final String id;
  final String chatId;
  final String senderId;
  final DateTime sentAt;
  final MessageType type;
  final String? text;

  /// Для сообщений типа task и report: на какую задачу ссылаются.
  final String? taskId;

  /// Если сообщение написано внутри темы, здесь её идентификатор.
  final String? topicId;
}

/// Тема внутри чата: отдельная переписка, закреплённая вверху.
/// Её видят все участники чата, куда она добавлена.
class ChatTopic {
  const ChatTopic({
    required this.id,
    required this.chatId,
    required this.title,
    required this.createdById,
    required this.createdAt,
  });

  final String id;
  final String chatId;
  final String title;
  final String createdById;
  final DateTime createdAt;
}

String hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// «N12345678» → «N••••••78»: паспорт показывается скрытым, пока
/// человек сам не нажмёт «показать».
String maskPassport(String p) {
  final s = p.trim();
  if (s.length <= 3) return s;
  return s[0] + '•' * (s.length - 3) + s.substring(s.length - 2);
}
