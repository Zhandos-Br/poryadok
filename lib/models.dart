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
    this.external = false,
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

  /// Человек не из команды: с ним можно переписываться, но он не в графике
  /// и не в рейтинге.
  final bool external;
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
    this.repeatDaily = false,
    this.report,
  });

  final String id;
  final String title;
  final String assigneeId;
  final DateTime due;

  /// Что обязательно сдать в отчёте.
  final Set<ReportKind> requiredKinds;

  /// Должностная обязанность: повторяется каждый день.
  /// Сам повтор нужно реализовать на сервере (см. README).
  final bool repeatDaily;

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
