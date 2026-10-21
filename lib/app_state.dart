import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils, TimeOfDay;

import 'models.dart';
import 'rating.dart';
import 'schedule.dart';

const groupChatId = 'group';

/// Всё состояние приложения в памяти. Данные демонстрационные.
/// В рабочей версии заменяется на Supabase или Firebase (см. README).
class AppState extends ChangeNotifier {
  AppState() {
    _seed();
    _seedSchedule();
  }

  final List<AppUser> users = const [
    AppUser(
      id: 'o1',
      name: 'Собственник',
      position: 'Собственник бизнеса',
      role: Role.owner,
    ),
    AppUser(
      id: 'm1',
      name: 'Руководитель',
      position: 'Руководитель',
      role: Role.manager,
    ),
    AppUser(
      id: 'e1',
      name: 'Айгерим',
      position: 'Продавец-кассир',
      role: Role.employee,
    ),
    AppUser(
      id: 'e2',
      name: 'Данияр',
      position: 'Кладовщик',
      role: Role.employee,
    ),
    AppUser(
      id: 'e3',
      name: 'Марат',
      position: 'Курьер',
      role: Role.employee,
    ),
    AppUser(
      id: 'e4',
      name: 'Светлана',
      position: 'Продавец',
      role: Role.employee,
    ),
  ];

  final List<TaskItem> tasks = [];
  final List<ChatMessage> messages = [];

  AppUser? _me;
  int _seq = 1000;

  AppUser get me => _me!;

  void signInAs(Role role) {
    _me = users.firstWhere((u) => u.role == role);
    notifyListeners();
  }

  // ---------- Пользователи и задачи ----------

  AppUser userById(String id) => users.firstWhere((u) => u.id == id);

  TaskItem taskById(String id) => tasks.firstWhere((t) => t.id == id);

  List<AppUser> get employees =>
      users.where((u) => u.role == Role.employee).toList();

  List<AppUser> get otherUsers => users.where((u) => u.id != me.id).toList();

  List<TaskItem> get myTasks {
    final list = tasks.where((t) => t.assigneeId == me.id).toList();
    list.sort((a, b) => a.due.compareTo(b.due));
    return list;
  }

  /// Сотрудник видит свои задачи, руководитель и собственник — все.
  List<TaskItem> get tasksVisibleToMe {
    if (me.role == Role.employee) return myTasks;
    final list = List<TaskItem>.of(tasks);
    list.sort((a, b) => a.due.compareTo(b.due));
    return list;
  }

  void addTask({
    required String title,
    required List<String> assigneeIds,
    required DateTime due,
    required Set<ReportKind> requiredKinds,
    bool repeatDaily = false,
  }) {
    for (final id in assigneeIds) {
      tasks.add(
        TaskItem(
          id: _nextId('t'),
          title: title,
          assigneeId: id,
          due: due,
          requiredKinds: requiredKinds,
          repeatDaily: repeatDaily,
        ),
      );
    }
    notifyListeners();
  }

  /// Сотрудник сдаёт отчёт. Он сразу дублируется в общий чат.
  void submitReport({
    required String taskId,
    required Set<ReportKind> kinds,
    required String comment,
    required Map<ReportKind, String> media,
  }) {
    final task = taskById(taskId);
    task.report = Report(
      submittedAt: DateTime.now(),
      kinds: kinds,
      comment: comment,
      media: media,
    );
    _addMessage(
      chatId: groupChatId,
      senderId: task.assigneeId,
      type: MessageType.report,
      taskId: taskId,
      text: comment,
    );
    notifyListeners();
  }

  /// Оценка качества отчёта: 1–5. Идёт в рейтинг сотрудника.
  void rate(String taskId, int stars) {
    taskById(taskId).report?.stars = stars;
    notifyListeners();
  }

  RatingBreakdown ratingFor(String userId) {
    final mine = tasks.where((t) => t.assigneeId == userId).toList();
    return calculateRating(mine, now: DateTime.now());
  }

  // ---------- Чаты ----------

  /// Идентификатор личного чата между текущим пользователем и другим.
  String directChatId(String otherId) {
    final ids = [me.id, otherId]..sort();
    return 'd:${ids[0]}:${ids[1]}';
  }

  String otherParticipant(String chatId) {
    final parts = chatId.split(':');
    return parts[1] == me.id ? parts[2] : parts[1];
  }

  String chatTitle(String chatId) {
    if (chatId == groupChatId) return 'Отчёты команды';
    return userById(otherParticipant(chatId)).name;
  }

  List<ChatMessage> messagesOf(String chatId) {
    final list = messages.where((m) => m.chatId == chatId).toList();
    list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return list;
  }

  ChatMessage? lastMessage(String chatId) {
    final list = messagesOf(chatId);
    return list.isEmpty ? null : list.last;
  }

  String previewOf(ChatMessage m) => switch (m.type) {
        MessageType.text => m.text ?? '',
        MessageType.task => 'Задача: ${taskById(m.taskId!).title}',
        MessageType.report => 'Отчёт: ${taskById(m.taskId!).title}',
      };

  void sendText(String chatId, String text) {
    _addMessage(
      chatId: chatId,
      senderId: me.id,
      type: MessageType.text,
      text: text,
    );
    notifyListeners();
  }

  /// Переслать задачу в любой чат.
  void shareTask(String chatId, String taskId) {
    _addMessage(
      chatId: chatId,
      senderId: me.id,
      type: MessageType.task,
      taskId: taskId,
    );
    notifyListeners();
  }

  /// Переслать готовый отчёт в любой чат.
  void shareReport(String chatId, String taskId) {
    _addMessage(
      chatId: chatId,
      senderId: me.id,
      type: MessageType.report,
      taskId: taskId,
    );
    notifyListeners();
  }

  // ---------- Внутреннее ----------

  String _nextId(String prefix) => '$prefix${_seq++}';

  void _addMessage({
    required String chatId,
    required String senderId,
    required MessageType type,
    String? text,
    String? taskId,
    DateTime? at,
  }) {
    messages.add(
      ChatMessage(
        id: _nextId('m'),
        chatId: chatId,
        senderId: senderId,
        sentAt: at ?? DateTime.now(),
        type: type,
        text: text,
        taskId: taskId,
      ),
    );
  }

  // ---------- График работы ----------

  /// Смена каждого сотрудника. Часы указаны отдельно от времени:
  /// в смену могут входить перерывы.
  static const _shifts = <String, ShiftInfo>{
    'e1': ShiftInfo(
      start: TimeOfDay(hour: 9, minute: 0),
      end: TimeOfDay(hour: 18, minute: 0),
      hours: 8,
    ),
    'e2': ShiftInfo(
      start: TimeOfDay(hour: 8, minute: 0),
      end: TimeOfDay(hour: 20, minute: 0),
      hours: 12,
    ),
    'e3': ShiftInfo(
      start: TimeOfDay(hour: 10, minute: 0),
      end: TimeOfDay(hour: 19, minute: 0),
      hours: 8,
    ),
    'e4': ShiftInfo(
      start: TimeOfDay(hour: 9, minute: 0),
      end: TimeOfDay(hour: 21, minute: 0),
      hours: 12,
    ),
  };

  /// Отпуска: сотрудник -> список периодов (включительно).
  /// В демо привязаны к текущему месяцу.
  final Map<String, List<(DateTime, DateTime)>> _vacations = {};

  /// Ручные изменения руководителя: 'id|yyyy-m-d' -> статус.
  final Map<String, DayStatus> _overrides = {};

  String _key(String id, DateTime d) => '$id|${d.year}-${d.month}-${d.day}';

  ShiftInfo shiftOf(String userId) => _shifts[userId]!;

  /// Статус дня без ручных правок: отпуск, затем правило недели.
  DayStatus _baseStatus(String id, DateTime day) {
    for (final v in _vacations[id] ?? const <(DateTime, DateTime)>[]) {
      if (!day.isBefore(v.$1) && !day.isAfter(v.$2)) return DayStatus.vacation;
    }
    final wd = day.weekday;
    switch (id) {
      case 'e1': // Пн–Пт
        return wd <= 5 ? DayStatus.work : DayStatus.off;
      case 'e3': // Вт–Сб
        return wd >= 2 && wd <= 6 ? DayStatus.work : DayStatus.off;
      case 'e2': // два через два
      case 'e4':
        final n = DateTime.utc(day.year, day.month, day.day)
            .difference(DateTime.utc(2026, 1, 1))
            .inDays;
        final phase = id == 'e2' ? 0 : 2;
        return ((n + phase) % 4) < 2 ? DayStatus.work : DayStatus.off;
    }
    return DayStatus.off;
  }

  DayStatus statusOf(String id, DateTime day) {
    final d = dateOnly(day);
    return _overrides[_key(id, d)] ?? _baseStatus(id, d);
  }

  /// Руководитель или собственник отмечает день: смена, выходной, отпуск.
  void setStatus(String id, DateTime day, DayStatus status) {
    final d = dateOnly(day);
    if (_baseStatus(id, d) == status) {
      _overrides.remove(_key(id, d));
    } else {
      _overrides[_key(id, d)] = status;
    }
    notifyListeners();
  }

  /// Итоги за месяц. С [upTo] считаются только дни до этой даты включительно
  /// (сколько уже отработано), без него весь месяц (план).
  /// Отпуск и выходные всегда считаются за весь месяц.
  WorkTotals totalsFor(String id, int year, int month, {DateTime? upTo}) {
    final count = DateUtils.getDaysInMonth(year, month);
    final limit = upTo == null ? null : dateOnly(upTo);
    final hours = shiftOf(id).hours;
    var days = 0, off = 0, vac = 0;
    for (var d = 1; d <= count; d++) {
      final day = DateTime(year, month, d);
      switch (statusOf(id, day)) {
        case DayStatus.work:
          if (limit == null || !day.isAfter(limit)) days++;
        case DayStatus.off:
          off++;
        case DayStatus.vacation:
          vac++;
      }
    }
    return WorkTotals(
      days: days,
      hours: days * hours,
      offDays: off,
      vacationDays: vac,
    );
  }

  /// Сколько сотрудников в этот день на смене.
  int workersOn(DateTime day) =>
      employees.where((e) => statusOf(e.id, day) == DayStatus.work).length;

  /// Задачи команды за день: сколько всего и сколько закрыто в срок.
  DayTeamStats teamStatsFor(DateTime day) {
    final d = dateOnly(day);
    final list = tasks.where((t) => t.day == d);
    return DayTeamStats(
      total: list.length,
      onTime: list.where((t) => t.onTime).length,
    );
  }

  DayTeamStats teamStatsForMonth(int year, int month) {
    final list =
        tasks.where((t) => t.day.year == year && t.day.month == month);
    return DayTeamStats(
      total: list.length,
      onTime: list.where((t) => t.onTime).length,
    );
  }

  void _seedSchedule() {
    final now = DateTime.now();
    DateTime d(int n) => DateTime(now.year, now.month, n);
    final last = DateUtils.getDaysInMonth(now.year, now.month);
    _vacations['e3'] = [(d(5), d(9))];
    _vacations['e4'] = [(d(last < 26 ? 1 : 26), d(last))];
  }

  void _seed() {
    final today = DateTime.now();
    DateTime at(int h, [int m = 0]) =>
        DateTime(today.year, today.month, today.day, h, m);

    tasks.addAll([
      TaskItem(
        id: 't1',
        title: 'Открыть точку и включить оборудование',
        assigneeId: 'e1',
        due: at(9),
        requiredKinds: {ReportKind.photo},
        repeatDaily: true,
        report: Report(
          submittedAt: at(8, 57),
          kinds: {ReportKind.photo},
          stars: 5,
        ),
      ),
      TaskItem(
        id: 't2',
        title: 'Проверить сроки годности на витрине',
        assigneeId: 'e1',
        due: at(10),
        requiredKinds: {ReportKind.photo},
      ),
      TaskItem(
        id: 't3',
        title: 'Протереть витрину и пол в зале',
        assigneeId: 'e1',
        due: at(13),
        requiredKinds: {ReportKind.photo, ReportKind.text},
      ),
      TaskItem(
        id: 't4',
        title: 'Пересчитать кассу в конце смены',
        assigneeId: 'e1',
        due: at(21),
        requiredKinds: {ReportKind.photo, ReportKind.text},
        repeatDaily: true,
      ),
      TaskItem(
        id: 't5',
        title: 'Закрыть точку и поставить на охрану',
        assigneeId: 'e1',
        due: at(22),
        requiredKinds: {ReportKind.video, ReportKind.audio},
        repeatDaily: true,
      ),
      TaskItem(
        id: 't6',
        title: 'Принять товар от поставщика',
        assigneeId: 'e2',
        due: at(10),
        requiredKinds: {ReportKind.audio},
        report: Report(
          submittedAt: at(9, 20),
          kinds: {ReportKind.audio},
          stars: 4,
        ),
      ),
      TaskItem(
        id: 't7',
        title: 'Доставить заказы по списку',
        assigneeId: 'e3',
        due: at(18),
        requiredKinds: {ReportKind.photo},
      ),
      TaskItem(
        id: 't8',
        title: 'Разложить товар по полкам',
        assigneeId: 'e4',
        due: at(12),
        requiredKinds: {ReportKind.photo},
      ),
    ]);

    _addMessage(
      chatId: groupChatId,
      senderId: 'e1',
      type: MessageType.report,
      taskId: 't1',
      text: 'Открыла, всё работает',
      at: at(8, 57),
    );
    _addMessage(
      chatId: groupChatId,
      senderId: 'e2',
      type: MessageType.report,
      taskId: 't6',
      at: at(9, 20),
    );
    _addMessage(
      chatId: groupChatId,
      senderId: 'o1',
      type: MessageType.text,
      text: 'Данияр, накладная сошлась?',
      at: at(10, 58),
    );

    _addMessage(
      chatId: 'd:e1:e2',
      senderId: 'e2',
      type: MessageType.text,
      text: 'Привет! Сможешь глянуть витрину? Я на приёмке товара',
      at: at(9, 31),
    );
    _addMessage(
      chatId: 'd:e1:e2',
      senderId: 'e1',
      type: MessageType.task,
      taskId: 't2',
      at: at(9, 35),
    );
    _addMessage(
      chatId: 'd:e1:m1',
      senderId: 'm1',
      type: MessageType.text,
      text: 'Принято, спасибо. Оценку поставил.',
      at: at(10, 50),
    );
  }
}
