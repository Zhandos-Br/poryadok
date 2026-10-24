import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils, ThemeMode, TimeOfDay;

import 'models.dart';
import 'rating.dart';
import 'schedule.dart';
import 'settings.dart' show TextSize;

/// Общий чат демо-компании «Рассвет». У других компаний свой: 'g:<id>'.
const groupChatId = 'group';

String groupChatOf(String companyId) =>
    companyId == 'c1' ? groupChatId : 'g:$companyId';

bool isGroupChat(String chatId) =>
    chatId == groupChatId || chatId.startsWith('g:');

/// Всё состояние приложения в памяти. Данные демонстрационные.
/// В рабочей версии заменяется на Supabase или Firebase (см. README).
class AppState extends ChangeNotifier {
  AppState() {
    _seed();
    _seedSchedule();
    _seedHistory();
    _seedTopics();
  }

  final List<AppUser> users = [
    AppUser(
      id: 'o1',
      companyId: 'c1',
      passport: 'N00000001',
      name: 'Собственник',
      position: 'Собственник бизнеса',
      role: Role.owner,
      nickname: 'owner',
      phone: '+7 701 100 00 01',
    ),
    AppUser(
      id: 'm1',
      companyId: 'c1',
      passport: 'N00000002',
      name: 'Руководитель',
      position: 'Руководитель',
      role: Role.manager,
      nickname: 'manager',
      phone: '+7 701 100 00 02',
    ),
    AppUser(
      id: 'e1',
      companyId: 'c1',
      passport: 'N00000003',
      name: 'Айгерим',
      position: 'Продавец-кассир',
      role: Role.employee,
      nickname: 'aigerim',
      phone: '+7 701 100 00 03',
    ),
    AppUser(
      id: 'e2',
      companyId: 'c1',
      passport: 'N00000004',
      name: 'Данияр',
      position: 'Кладовщик',
      role: Role.employee,
      nickname: 'daniyar',
      phone: '+7 701 100 00 04',
    ),
    AppUser(
      id: 'e3',
      companyId: 'c1',
      passport: 'N00000005',
      name: 'Марат',
      position: 'Курьер',
      role: Role.employee,
      nickname: 'marat',
      phone: '+7 701 100 00 05',
    ),
    AppUser(
      id: 'e4',
      companyId: 'c1',
      passport: 'N00000006',
      name: 'Светлана',
      position: 'Продавец',
      role: Role.employee,
      nickname: 'svetlana',
      phone: '+7 701 100 00 06',
    ),
    AppUser(
      id: 'x1',
      name: 'Ерлан Бектасов',
      position: 'Внешний контакт',
      role: Role.employee,
      nickname: 'erlan_b',
      phone: '+7 777 123 45 67',
    ),
  ];

  final List<Company> companies = const [
    Company(id: 'c1', name: 'Магазин «Рассвет»', bin: '123456789012'),
  ].toList();
  final List<CompanyInvite> invites = [];
  final List<TaskItem> tasks = [];
  final List<ChatMessage> messages = [];

  AppUser? _me;
  int _seq = 1000;

  AppUser get me => _me!;

  bool get signedIn => _me != null;

  void signInAsUser(String userId) {
    _me = userById(userId);
    notifyListeners();
  }

  /// Вход по номеру телефона. Возвращает текст ошибки или null.
  /// В рабочей версии здесь будет код из SMS.
  String? signInByPhone(String phone) {
    final user = findUserByPhone(phone);
    if (user == null) {
      return 'Такой номер не зарегистрирован. Зарегистрируйтесь.';
    }
    _me = user;
    notifyListeners();
    return null;
  }

  void signOut() {
    _me = null;
    notifyListeners();
  }

  // ---------- Внешний вид ----------

  ThemeMode themeMode = ThemeMode.light;
  TextSize textSize = TextSize.normal;
  int wallpaperIndex = 0;

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  void setTextSize(TextSize size) {
    textSize = size;
    notifyListeners();
  }

  void setWallpaper(int index) {
    wallpaperIndex = index;
    notifyListeners();
  }

  // ---------- Компания и приглашения ----------

  Company? companyById(String id) {
    for (final c in companies) {
      if (c.id == id) return c;
    }
    return null;
  }

  Company? get myCompany =>
      me.companyId == null ? null : companyById(me.companyId!);

  /// Руководитель или собственник компании.
  bool get canManage => me.companyId != null && me.role != Role.employee;

  /// Можно ли поставить задачу прямо из этого чата: в общем чате
  /// своей компании или в личном чате с её сотрудником.
  bool canAssignIn(String chatId) {
    if (!canManage) return false;
    if (isGroupChat(chatId)) return chatId == myGroupChatId;
    final other = userById(otherParticipant(chatId));
    return other.companyId == me.companyId && other.role == Role.employee;
  }

  /// Общий чат компании, в которой состоит текущий пользователь.
  String? get myGroupChatId =>
      me.companyId == null ? null : groupChatOf(me.companyId!);

  static bool _samePhone(String a, String b) {
    final x = _digits(a), y = _digits(b);
    if (x.length < 10 || y.length < 10) return false;
    return x.substring(x.length - 10) == y.substring(y.length - 10);
  }

  /// Приглашения, которые ждут решения текущего пользователя.
  List<CompanyInvite> get pendingInvitesForMe {
    if (me.companyId != null) return const [];
    return invites
        .where((i) =>
            i.status == InviteStatus.pending && _samePhone(i.phone, me.phone))
        .toList();
  }

  /// Приглашения, отправленные от лица компании текущего пользователя.
  List<CompanyInvite> get sentInvites {
    final list = invites.where((i) => i.companyId == me.companyId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _newCode() {
    final rnd = Random();
    while (true) {
      final code = List.generate(
        6,
        (_) => _codeAlphabet[rnd.nextInt(_codeAlphabet.length)],
      ).join();
      if (!invites.any((i) => i.code == code)) return code;
    }
  }

  /// Руководитель или собственник приглашает человека по номеру.
  /// Если номер уже зарегистрирован, приглашение придёт человеку
  /// в приложение. Иначе ему нужно отправить код: его вводят при регистрации.
  InviteResult createInvite({
    required String phone,
    required Role role,
    String position = '',
  }) {
    if (!canManage) {
      return const InviteResult(error: 'Приглашать может руководитель или собственник');
    }
    if (_digits(phone).length < 10) {
      return const InviteResult(error: 'Введите номер полностью');
    }
    final existing = findUserByPhone(phone);
    if (existing != null && existing.companyId != null) {
      return const InviteResult(error: 'Этот человек уже состоит в компании');
    }
    for (final i in invites) {
      if (i.status == InviteStatus.pending &&
          i.companyId == me.companyId &&
          _samePhone(i.phone, phone)) {
        return InviteResult(invite: i, userExists: existing != null);
      }
    }
    final invite = CompanyInvite(
      id: _nextId('i'),
      companyId: me.companyId!,
      phone: phone.trim(),
      code: _newCode(),
      role: role,
      position: position.trim(),
      createdById: me.id,
      createdAt: DateTime.now(),
    );
    invites.add(invite);
    notifyListeners();
    return InviteResult(invite: invite, userExists: existing != null);
  }

  String _positionFor(Role role, String position) {
    if (position.trim().isNotEmpty) return position.trim();
    return switch (role) {
      Role.owner => 'Собственник бизнеса',
      Role.manager => 'Руководитель',
      Role.employee => 'Сотрудник',
    };
  }

  void _replaceUser(AppUser updated) {
    final i = users.indexWhere((u) => u.id == updated.id);
    if (i >= 0) users[i] = updated;
    if (_me?.id == updated.id) _me = updated;
  }

  void _announceJoin(AppUser user, String companyId) {
    _addMessage(
      chatId: groupChatOf(companyId),
      senderId: user.id,
      type: MessageType.text,
      text: 'Вступил(а) в команду',
    );
  }

  static bool _validPassport(String? p) => (p ?? '').trim().length >= 6;

  /// Паспортные данные не заполнены: их надо ввести до вступления в компанию.
  bool get needsPassport => !_validPassport(me.passport);

  /// Человек принимает приглашение и сразу попадает в команду.
  /// Для вступления в компанию паспортные данные обязательны:
  /// если их ещё нет, их нужно передать в [passport].
  /// Возвращает текст ошибки или null.
  String? acceptInvite(String inviteId, {String passport = ''}) {
    final invite = invites.firstWhere((i) => i.id == inviteId);
    final given = _validPassport(passport) ? passport.trim() : null;
    if (needsPassport && given == null) {
      return 'Для вступления в компанию укажите паспортные данные';
    }
    invite.status = InviteStatus.accepted;
    final joined = me.copyWith(
      companyId: invite.companyId,
      role: invite.role,
      position: _positionFor(invite.role, invite.position),
      passport: given,
    );
    _replaceUser(joined);
    _announceJoin(joined, invite.companyId);
    notifyListeners();
    return null;
  }

  void declineInvite(String inviteId) {
    invites.firstWhere((i) => i.id == inviteId).status = InviteStatus.declined;
    notifyListeners();
  }

  // ---------- Пользователи и задачи ----------

  AppUser userById(String id) => users.firstWhere((u) => u.id == id);

  TaskItem taskById(String id) => tasks.firstWhere((t) => t.id == id);

  /// Сотрудники команды: они есть в графике и рейтинге.
  List<AppUser> get employees => users
      .where((u) =>
          u.role == Role.employee &&
          u.companyId != null &&
          u.companyId == _me?.companyId)
      .toList();

  List<AppUser> get otherUsers => users.where((u) => u.id != me.id).toList();

  /// Кого показывать в списке личных чатов: команду и тех внешних людей,
  /// с кем уже начат разговор.
  List<AppUser> get chatPartners => users
      .where((u) =>
          u.id != me.id &&
          ((u.companyId != null && u.companyId == me.companyId) ||
              hasChat(directChatId(u.id))))
      .toList();

  List<TaskItem> get myTasks {
    final list = tasks.where((t) => t.assigneeId == me.id).toList();
    list.sort((a, b) => a.due.compareTo(b.due));
    return list;
  }

  /// Задачи сотрудника на сегодня.
  List<TaskItem> get todayTasks {
    final today = dateOnly(DateTime.now());
    final list =
        tasks.where((t) => t.assigneeId == me.id && t.day == today).toList();
    list.sort((a, b) => a.due.compareTo(b.due));
    return list;
  }

  /// Сегодняшние задачи: свои у сотрудника, все у руководителя и собственника.
  List<TaskItem> get tasksVisibleToMe {
    final today = dateOnly(DateTime.now());
    final list = tasks
        .where((t) =>
            t.day == today &&
            (me.role == Role.employee
                ? t.assigneeId == me.id
                : userById(t.assigneeId).companyId == me.companyId))
        .toList();
    list.sort((a, b) => a.due.compareTo(b.due));
    return list;
  }

  /// Ставит задачу. Повторяющаяся задача создаётся на 30 дней вперёд:
  /// в рабочей версии повторы создаёт сервер.
  /// Возвращает по одной (ближайшей) задаче на каждого исполнителя.
  List<TaskItem> addTask({
    required String title,
    required List<String> assigneeIds,
    required DateTime due,
    required Set<ReportKind> requiredKinds,
    Repeat repeat = Repeat.once,
  }) {
    final start = dateOnly(due);
    final first = <TaskItem>[];
    for (final id in assigneeIds) {
      TaskItem? head;
      final span = repeat == Repeat.once ? 0 : 30;
      for (var offset = 0; offset <= span; offset++) {
        final day = DateTime(start.year, start.month, start.day + offset);
        if (!_occurs(repeat, start, day)) continue;
        final task = TaskItem(
          id: _nextId('t'),
          title: title,
          assigneeId: id,
          due: DateTime(day.year, day.month, day.day, due.hour, due.minute),
          requiredKinds: requiredKinds,
          repeat: repeat,
        );
        tasks.add(task);
        head ??= task;
      }
      if (head != null) first.add(head);
    }
    notifyListeners();
    return first;
  }

  static bool _occurs(Repeat repeat, DateTime start, DateTime day) {
    switch (repeat) {
      case Repeat.once:
        return day == start;
      case Repeat.daily:
        return true;
      case Repeat.weekdays:
        return day.weekday <= 5;
      case Repeat.weekly:
        return day.weekday == start.weekday;
      case Repeat.monthly:
        return day.day == start.day;
    }
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
    final companyId = userById(task.assigneeId).companyId;
    if (companyId != null) {
      _addMessage(
        chatId: groupChatOf(companyId),
        senderId: task.assigneeId,
        type: MessageType.report,
        taskId: taskId,
        text: comment,
      );
    }
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

  /// Темы внутри чатов.
  final List<ChatTopic> topics = [];

  /// Личные чаты, начатые до первого сообщения (например, по номеру).
  final Set<String> _startedChats = {};

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
    if (isGroupChat(chatId)) return 'Отчёты команды';
    return userById(otherParticipant(chatId)).name;
  }

  bool hasChat(String chatId) =>
      _startedChats.contains(chatId) ||
      messages.any((m) => m.chatId == chatId);

  /// Сообщения чата. Без [topicId] только основная переписка,
  /// с [topicId] только переписка внутри темы.
  List<ChatMessage> messagesOf(String chatId, {String? topicId}) {
    final list = messages
        .where((m) => m.chatId == chatId && m.topicId == topicId)
        .toList();
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

  // ----- Темы -----

  List<ChatTopic> topicsOf(String chatId) {
    final list = topics.where((t) => t.chatId == chatId).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  ChatTopic topicById(String id) => topics.firstWhere((t) => t.id == id);

  int topicMessageCount(String topicId) =>
      messages.where((m) => m.topicId == topicId).length;

  /// Создаёт тему в чате. Её увидят все участники этого чата.
  ChatTopic createTopic(String chatId, String title) {
    final topic = ChatTopic(
      id: _nextId('c'),
      chatId: chatId,
      title: title.trim(),
      createdById: me.id,
      createdAt: DateTime.now(),
    );
    topics.add(topic);
    _addMessage(
      chatId: chatId,
      topicId: topic.id,
      senderId: me.id,
      type: MessageType.text,
      text: 'Создал(а) тему «${topic.title}»',
    );
    notifyListeners();
    return topic;
  }

  // ----- Сообщения -----

  void sendText(String chatId, String text, {String? topicId}) {
    _addMessage(
      chatId: chatId,
      topicId: topicId,
      senderId: me.id,
      type: MessageType.text,
      text: text,
    );
    notifyListeners();
  }

  /// Переслать задачу в любой чат.
  void shareTask(String chatId, String taskId, {String? topicId}) {
    _addMessage(
      chatId: chatId,
      topicId: topicId,
      senderId: me.id,
      type: MessageType.task,
      taskId: taskId,
    );
    notifyListeners();
  }

  /// Переслать готовый отчёт в любой чат.
  void shareReport(String chatId, String taskId, {String? topicId}) {
    _addMessage(
      chatId: chatId,
      topicId: topicId,
      senderId: me.id,
      type: MessageType.report,
      taskId: taskId,
    );
    notifyListeners();
  }

  // ----- Поиск по телефону и регистрация -----

  static String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  /// Ищет пользователя по номеру. Сравниваются последние 10 цифр,
  /// поэтому «+7 777 123 45 67» и «8 (777) 123-45-67» — один номер.
  AppUser? findUserByPhone(String input) {
    final d = _digits(input);
    if (d.length < 10) return null;
    final tail = d.substring(d.length - 10);
    for (final u in users) {
      final p = _digits(u.phone);
      if (p.length >= 10 && p.substring(p.length - 10) == tail) return u;
    }
    return null;
  }

  /// Начинает личный чат. Он появится в списке, даже если пока пустой.
  String startDirectChat(String userId) {
    final id = directChatId(userId);
    _startedChats.add(id);
    notifyListeners();
    return id;
  }

  /// Регистрирует человека и входит под ним. Возвращает текст ошибки
  /// или null, если всё получилось.
  ///
  /// Все регистрируются одинаково, как обычные пользователи.
  /// Дальше есть два пути:
  /// - руководитель или собственник бизнеса ставит галочку, указывает
  ///   название компании и свою роль, компания создаётся;
  /// - сотрудник вводит код приглашения, который прислал руководитель
  ///   или собственник на его номер, и попадает в команду.
  /// Без кода остаётся личный аккаунт: приглашение можно принять позже.
  String? register({
    required String fullName,
    required String nickname,
    required String phone,
    String passport = '',
    String invite = '',
    Uint8List? photo,
    bool isBusiness = false,
    String companyName = '',
    String bin = '',
    Role businessRole = Role.owner,
  }) {
    if (findUserByPhone(phone) != null) {
      return 'Этот номер уже зарегистрирован. Войдите по номеру.';
    }
    final nick = nickname.trim().replaceFirst(RegExp(r'^@'), '');
    if (users.any((u) => u.nickname.toLowerCase() == nick.toLowerCase())) {
      return 'Такой никнейм уже занят';
    }
    if (isBusiness) {
      if (companyName.trim().isEmpty) return 'Укажите название компании';
      if (_digits(bin).length != 12) return 'БИН состоит из 12 цифр';
      if (companies.any((c) => c.bin == _digits(bin))) {
        return 'Компания с таким БИН уже зарегистрирована. '
            'Попросите её руководителя или собственника пригласить вас.';
      }
    }
    if (!isBusiness && invite.trim().isNotEmpty && !_validPassport(passport)) {
      return 'Для вступления в компанию нужны паспортные данные';
    }

    CompanyInvite? byCode;
    final code = invite.trim().toUpperCase();
    if (!isBusiness && code.isNotEmpty) {
      for (final i in invites) {
        if (i.status == InviteStatus.pending &&
            i.code == code &&
            _samePhone(i.phone, phone)) {
          byCode = i;
        }
      }
      if (byCode == null) {
        return 'Код не подошёл. Проверьте код и номер, на который он был отправлен.';
      }
    }

    String? companyId;
    var role = Role.employee;
    var position = 'Личный аккаунт';
    if (isBusiness) {
      companyId = _nextId('c');
      companies.add(
        Company(id: companyId, name: companyName.trim(), bin: _digits(bin)),
      );
      role = businessRole;
      position = _positionFor(role, '');
    } else if (byCode != null) {
      companyId = byCode.companyId;
      role = byCode.role;
      position = _positionFor(role, byCode.position);
    }

    final user = AppUser(
      id: _nextId('u'),
      name: fullName.trim(),
      position: position,
      role: role,
      nickname: nick,
      phone: phone.trim(),
      passport: passport.trim().isEmpty ? null : passport.trim(),
      photo: photo,
      companyId: companyId,
    );
    users.add(user);
    byCode?.status = InviteStatus.accepted;
    _me = user;
    if (companyId != null) {
      if (isBusiness) {
        _addMessage(
          chatId: groupChatOf(companyId),
          senderId: user.id,
          type: MessageType.text,
          text: 'Компания «${companyName.trim()}» создана. Приглашайте сотрудников.',
        );
      } else {
        _announceJoin(user, companyId);
      }
    }
    notifyListeners();
    return null;
  }

  // ---------- Внутреннее ----------

  String _nextId(String prefix) => '$prefix${_seq++}';

  void _addMessage({
    required String chatId,
    required String senderId,
    required MessageType type,
    String? text,
    String? taskId,
    String? topicId,
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
        topicId: topicId,
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

  static const _defaultShift = ShiftInfo(
    start: TimeOfDay(hour: 9, minute: 0),
    end: TimeOfDay(hour: 18, minute: 0),
    hours: 8,
  );

  ShiftInfo shiftOf(String userId) => _shifts[userId] ?? _defaultShift;

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
    // Новые сотрудники по умолчанию работают с понедельника по пятницу.
    return wd <= 5 ? DayStatus.work : DayStatus.off;
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

  bool _counts(TaskItem t) => t.done || DateTime.now().isAfter(t.due);

  DayTeamStats _statsOf(Iterable<TaskItem> list) {
    final counted = list.where(_counts).toList();
    return DayTeamStats(
      total: counted.length,
      onTime: counted.where((t) => t.onTime).length,
    );
  }

  /// Задачи команды за день: сколько учтено и сколько закрыто в срок.
  /// Учитываются задачи, срок которых уже наступил, и уже сданные.
  DayTeamStats teamStatsFor(DateTime day) {
    final d = dateOnly(day);
    return _statsOf(tasks.where((t) => t.day == d));
  }

  /// То же для одного сотрудника.
  DayTeamStats userDayStats(String userId, DateTime day) {
    final d = dateOnly(day);
    return _statsOf(tasks.where((t) => t.assigneeId == userId && t.day == d));
  }

  DayTeamStats teamStatsForMonth(int year, int month) => _statsOf(
      tasks.where((t) => t.day.year == year && t.day.month == month));

  DayTeamStats userStatsForMonth(String userId, int year, int month) =>
      _statsOf(tasks.where((t) =>
          t.assigneeId == userId &&
          t.day.year == year &&
          t.day.month == month));

  void _seedSchedule() {
    final now = DateTime.now();
    DateTime d(int n) => DateTime(now.year, now.month, n);
    final last = DateUtils.getDaysInMonth(now.year, now.month);
    _vacations['e3'] = [(d(5), d(9))];
    _vacations['e4'] = [(d(last < 26 ? 1 : 26), d(last))];
  }

  /// Задачи за прошлые дни месяца, чтобы в календаре была история.
  /// Результаты условные, но одинаковые при каждом запуске.
  void _seedHistory() {
    final now = DateTime.now();
    const share = <String, double>{'e1': 0.95, 'e2': 0.9, 'e3': 0.65, 'e4': 0.45};
    const titles = <String, List<String>>{
      'e1': ['Открыть точку и включить оборудование', 'Пересчитать кассу'],
      'e2': ['Принять товар от поставщика', 'Сверить остатки на складе'],
      'e3': ['Доставить заказы по списку', 'Сдать выручку курьера'],
      'e4': ['Разложить товар по полкам', 'Протереть витрину и пол'],
    };
    var n = 0;
    for (var d = 1; d < now.day; d++) {
      final day = DateTime(now.year, now.month, d);
      for (final entry in share.entries) {
        if (_baseStatus(entry.key, day) != DayStatus.work) continue;
        final shift = shiftOf(entry.key);
        for (var k = 0; k < 2; k++) {
          n++;
          final hour = k == 0 ? shift.start.hour + 1 : shift.end.hour - 1;
          final due = DateTime(now.year, now.month, d, hour);
          final roll = ((d * 37 + n * 53) % 100) / 100;
          Report? report;
          if (roll < entry.value) {
            report = Report(
              submittedAt: due.subtract(const Duration(minutes: 20)),
              kinds: {ReportKind.photo},
              stars: 4 + (n % 2),
            );
          } else if (roll < entry.value + 0.25) {
            report = Report(
              submittedAt: due.add(const Duration(minutes: 40)),
              kinds: {ReportKind.photo},
              stars: 3,
            );
          }
          tasks.add(
            TaskItem(
              id: 'h$n',
              title: titles[entry.key]![k],
              assigneeId: entry.key,
              due: due,
              requiredKinds: {ReportKind.photo},
              report: report,
            ),
          );
        }
      }
    }
  }

  void _seedTopics() {
    final now = DateTime.now();
    DateTime ago(int hours) => now.subtract(Duration(hours: hours));

    topics.addAll([
      ChatTopic(
        id: 'c1',
        chatId: groupChatId,
        title: 'Новогодний корпоратив',
        createdById: 'o1',
        createdAt: ago(30),
      ),
      ChatTopic(
        id: 'c2',
        chatId: groupChatId,
        title: 'Дни рождения',
        createdById: 'm1',
        createdAt: ago(20),
      ),
      ChatTopic(
        id: 'c3',
        chatId: 'd:e1:m1',
        title: 'Рабочие моменты',
        createdById: 'm1',
        createdAt: ago(10),
      ),
    ]);

    _addMessage(
      chatId: groupChatId,
      topicId: 'c1',
      senderId: 'o1',
      type: MessageType.text,
      text: 'Обсуждаем новогодний корпоратив: дату, место и бюджет.',
      at: ago(30),
    );
    _addMessage(
      chatId: groupChatId,
      topicId: 'c1',
      senderId: 'e2',
      type: MessageType.text,
      text: 'Предлагаю 27 декабря, после закрытия.',
      at: ago(28),
    );
    _addMessage(
      chatId: groupChatId,
      topicId: 'c1',
      senderId: 'e4',
      type: MessageType.text,
      text: 'Поддерживаю. Могу найти зал.',
      at: ago(27),
    );
    _addMessage(
      chatId: groupChatId,
      topicId: 'c2',
      senderId: 'm1',
      type: MessageType.text,
      text: 'Здесь собираем даты и поздравления.',
      at: ago(20),
    );
    _addMessage(
      chatId: 'd:e1:m1',
      topicId: 'c3',
      senderId: 'm1',
      type: MessageType.text,
      text: 'Тут будем договариваться по сменам и заменам.',
      at: ago(10),
    );
  }

  void _seed() {
    final today = DateTime.now();
    invites.addAll([
      // Ерлан уже зарегистрирован: приглашение придёт ему в приложение.
      CompanyInvite(
        id: 'i1',
        companyId: 'c1',
        phone: '+7 777 123 45 67',
        code: 'ERLAN1',
        role: Role.employee,
        position: 'Продавец',
        createdById: 'm1',
        createdAt: today,
      ),
      // Для проверки регистрации по коду.
      CompanyInvite(
        id: 'i2',
        companyId: 'c1',
        phone: '+7 700 555 11 22',
        code: 'RASSVET',
        role: Role.employee,
        position: 'Продавец',
        createdById: 'm1',
        createdAt: today,
      ),
    ]);
    DateTime at(int h, [int m = 0]) =>
        DateTime(today.year, today.month, today.day, h, m);

    tasks.addAll([
      TaskItem(
        id: 't1',
        title: 'Открыть точку и включить оборудование',
        assigneeId: 'e1',
        due: at(9),
        requiredKinds: {ReportKind.photo},
        repeat: Repeat.daily,
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
        repeat: Repeat.daily,
      ),
      TaskItem(
        id: 't5',
        title: 'Закрыть точку и поставить на охрану',
        assigneeId: 'e1',
        due: at(22),
        requiredKinds: {ReportKind.video, ReportKind.audio},
        repeat: Repeat.daily,
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

/// Результат приглашения: либо ошибка, либо созданное приглашение.
class InviteResult {
  const InviteResult({this.error, this.invite, this.userExists = false});

  final String? error;
  final CompanyInvite? invite;

  /// Человек уже зарегистрирован: приглашение придёт ему в приложение.
  final bool userExists;
}
