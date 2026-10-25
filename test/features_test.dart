import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:poryadok/app_state.dart';
import 'package:poryadok/models.dart';
import 'package:poryadok/settings.dart';

void main() {
  group('темы в чатах', () {
    test('сообщения темы не попадают в основную переписку', () {
      final state = AppState()..signInAsUser('e1');
      final chatId = state.directChatId('m1');

      final mainBefore = state.messagesOf(chatId).length;
      final topic = state.createTopic(chatId, 'Новогодний корпоратив');
      state.sendText(chatId, 'Предлагаю 27 декабря', topicId: topic.id);

      expect(state.messagesOf(chatId).length, mainBefore);
      // Первое сообщение о создании темы и наше.
      expect(state.messagesOf(chatId, topicId: topic.id).length, 2);
      expect(state.topicsOf(chatId).any((t) => t.id == topic.id), isTrue);
    });

    test('тема видна обоим участникам личного чата', () {
      final state = AppState()..signInAsUser('e1');
      final employeeSide = state.topicsOf('d:e1:m1').length;
      expect(employeeSide, greaterThan(0));

      state.signInAsUser('m1');
      expect(state.topicsOf(state.directChatId('e1')).length, employeeSide);
    });
  });

  group('поиск по телефону', () {
    test('номер находится при любом написании', () {
      final state = AppState()..signInAsUser('e1');
      expect(state.findUserByPhone('+7 777 123 45 67')?.id, 'x1');
      expect(state.findUserByPhone('8 (777) 123-45-67')?.id, 'x1');
      expect(state.findUserByPhone('+7 700 000 00 00'), isNull);
      expect(state.findUserByPhone('123'), isNull);
    });

    test('внешний контакт появляется в списке чатов после старта чата', () {
      final state = AppState()..signInAsUser('e1');
      expect(state.chatPartners.any((u) => u.id == 'x1'), isFalse);

      state.startDirectChat('x1');
      expect(state.chatPartners.any((u) => u.id == 'x1'), isTrue);
    });
  });

  group('регистрация и компании', () {
    test('без кода это личный аккаунт вне команды', () {
      final state = AppState();
      final teamBefore = state.users.where((u) => u.companyId == 'c1').length;

      final error = state.register(
        fullName: 'Иванов Иван Иванович',
        nickname: '@ivan_i',
        phone: '+7 701 555 44 33',
      );

      expect(error, isNull);
      expect(state.signedIn, isTrue);
      expect(state.me.nickname, 'ivan_i');
      expect(state.me.external, isTrue);
      expect(state.employees, isEmpty);
      expect(state.myGroupChatId, isNull);
      expect(state.users.where((u) => u.companyId == 'c1').length, teamBefore);
    });

    test('руководитель или собственник создаёт компанию', () {
      final state = AppState();
      final companies = state.companies.length;

      final error = state.register(
        fullName: 'Сидоров Пётр',
        nickname: 'petr_s',
        phone: '+7 701 333 22 11',
        isBusiness: true,
        companyName: 'Кофейня «Утро»',
        bin: '987654321098',
        businessRole: Role.owner,
      );

      expect(error, isNull);
      expect(state.companies.length, companies + 1);
      expect(state.me.role, Role.owner);
      expect(state.canManage, isTrue);
      expect(state.myCompany?.name, 'Кофейня «Утро»');
      expect(state.myCompany?.bin, '987654321098');
      expect(state.myGroupChatId, isNotNull);
      expect(state.employees, isEmpty);
    });

    test('без названия и БИН регистрация бизнеса отклоняется', () {
      final state = AppState();
      Object? try_({String name = '', String bin = ''}) => state.register(
            fullName: 'Сидоров Пётр',
            nickname: 'petr_s',
            phone: '+7 701 333 22 11',
            isBusiness: true,
            companyName: name,
            bin: bin,
          );

      expect(try_(), isNotNull);
      expect(try_(name: 'Кофейня'), isNotNull); // нет БИН
      expect(try_(name: 'Кофейня', bin: '12345'), isNotNull); // короткий БИН
      // БИН уже принадлежит «Рассвету»: нужно приглашение, а не новая компания.
      expect(try_(name: 'Копия', bin: '123456789012'), isNotNull);
      expect(try_(name: 'Кофейня', bin: '123 456 789 000'), isNull);
    });

    test('код приглашения вводится с номером, на который он выдан', () {
      final state = AppState();
      final teamBefore = state.users.where((u) => u.companyId == 'c1').length;

      // Чужой номер с верным кодом не подходит.
      expect(
        state.register(
          fullName: 'Чужой Человек',
          nickname: 'chuzhoy',
          phone: '+7 701 000 11 22',
          invite: 'RASSVET',
        ),
        isNotNull,
      );

      // Без паспорта в компанию не вступить.
      expect(
        state.register(
          fullName: 'Петрова Анна',
          nickname: 'anna_p',
          phone: '+7 700 555 11 22',
          invite: 'rassvet',
        ),
        isNotNull,
      );

      final error = state.register(
        fullName: 'Петрова Анна',
        nickname: 'anna_p',
        phone: '+7 700 555 11 22',
        passport: 'N12345670',
        invite: 'rassvet',
      );

      expect(error, isNull);
      expect(state.me.companyId, 'c1');
      expect(state.me.role, Role.employee);
      expect(state.me.passport, 'N12345670');
      expect(state.users.where((u) => u.companyId == 'c1').length,
          teamBefore + 1);
      expect(state.employees.any((u) => u.id == state.me.id), isTrue);
      // Для нового сотрудника график считается без ошибок.
      final now = DateTime.now();
      final totals = state.totalsFor(state.me.id, now.year, now.month);
      expect(totals.days + totals.offDays + totals.vacationDays,
          DateTime(now.year, now.month + 1, 0).day);
    });

    test('повторный номер и неверный код отклоняются', () {
      final state = AppState();

      expect(
        state.register(
          fullName: 'Другой Человек',
          nickname: 'other_one',
          phone: '+7 701 100 00 03', // телефон Айгерим
        ),
        isNotNull,
      );
      expect(
        state.register(
          fullName: 'Другой Человек',
          nickname: 'other_one',
          phone: '+7 701 999 88 77',
          invite: 'WRONG',
        ),
        isNotNull,
      );
    });

    test('вход по номеру и выход', () {
      final state = AppState();
      expect(state.signedIn, isFalse);
      expect(state.signInByPhone('8 701 100 00 03'), isNull);
      expect(state.me.id, 'e1');
      state.signOut();
      expect(state.signedIn, isFalse);
      expect(state.signInByPhone('+7 701 000 00 00'), isNotNull);
    });
  });

  group('приглашения', () {
    test('зарегистрированному человеку приглашение приходит в приложение', () {
      final state = AppState()..signInAsUser('x1');
      expect(state.pendingInvitesForMe.length, 1);
      expect(state.me.companyId, isNull);

      final id = state.pendingInvitesForMe.first.id;
      expect(state.needsPassport, isTrue);
      // Без паспорта вступить нельзя.
      expect(state.acceptInvite(id), isNotNull);
      expect(state.me.companyId, isNull);

      expect(state.acceptInvite(id, passport: 'N77777777'), isNull);

      expect(state.me.passport, 'N77777777');
      expect(state.me.companyId, 'c1');
      expect(state.me.role, Role.employee);
      expect(state.pendingInvitesForMe, isEmpty);
      expect(state.myGroupChatId, groupChatId);
    });

    test('приглашать может только руководитель или собственник', () {
      final state = AppState()..signInAsUser('e1');
      expect(
        state.createInvite(phone: '+7 700 111 22 33', role: Role.employee).error,
        isNotNull,
      );

      state.signInAsUser('m1');
      final result =
          state.createInvite(phone: '+7 700 111 22 33', role: Role.employee);
      expect(result.error, isNull);
      expect(result.userExists, isFalse);
      expect(result.invite!.code.length, 6);

      // Повторное приглашение на тот же номер возвращает то же.
      expect(
        state.createInvite(phone: '8 700 111 22 33', role: Role.employee)
            .invite!.id,
        result.invite!.id,
      );
      // Человек из команды уже в компании.
      expect(
        state.createInvite(phone: '+7 701 100 00 03', role: Role.employee).error,
        isNotNull,
      );
    });

    test('руководитель и собственник приглашаются как отдельные люди', () {
      final state = AppState();
      state.register(
        fullName: 'Руководитель Новый',
        nickname: 'mgr_new',
        phone: '+7 701 777 66 55',
        isBusiness: true,
        companyName: 'Новая Компания',
        bin: '111222333444',
        businessRole: Role.manager,
      );
      final owner = state.createInvite(
        phone: '+7 701 888 99 00',
        role: Role.owner,
      );
      state.signOut();
      expect(
        state.register(
          fullName: 'Собственник Новый',
          nickname: 'own_new',
          phone: '+7 701 888 99 00',
          passport: 'N55555555',
          invite: owner.invite!.code,
        ),
        isNull,
      );
      expect(state.me.role, Role.owner);
      expect(state.myCompany?.name, 'Новая Компания');
    });
  });

  group('привязка к компании', () {
    test('у сотрудников паспорт и БИН компании на месте', () {
      final state = AppState()..signInAsUser('m1');
      final company = state.companyById(state.userById('e1').companyId!)!;
      expect(company.bin.length, 12);
      expect(state.userById('e1').passport, isNotNull);
      expect(maskPassport('N00000003'), 'N••••••03');
    });
  });

  group('настройки', () {
    test('тема, размер текста и обои меняются', () {
      final state = AppState();
      state.setThemeMode(ThemeMode.dark);
      state.setTextSize(TextSize.large);
      state.setWallpaper(3);
      expect(state.themeMode, ThemeMode.dark);
      expect(state.textSize.scale, 1.15);
      expect(state.wallpaperIndex, 3);
    });
  });

  group('принятие задачи', () {
    TaskItem create(AppState s) => s.addTask(
          title: 'Протереть витрины',
          assigneeIds: ['e1'],
          due: DateTime.now().add(const Duration(hours: 2)),
          requiredKinds: {ReportKind.photo},
          repeat: Repeat.daily,
        ).first;

    test('новая задача не принята, пока сотрудник не нажал', () {
      final s = AppState()..signInAsUser('m1');
      final t = create(s);
      expect(t.accepted, isFalse);
      expect(s.unacceptedTasks.any((x) => x.id == t.id), isTrue);
    });

    test('сотрудник принимает серию и руководитель получает сообщение', () {
      final s = AppState()..signInAsUser('m1');
      final t = create(s);
      s.signInAsUser('e1');
      final before = s.messagesOf(s.directChatId('m1')).length;
      s.acceptTask(t.id);
      expect(s.taskById(t.id).accepted, isTrue);
      expect(
        s.tasks.where((x) => x.seriesId == t.seriesId).every((x) => x.accepted),
        isTrue,
      );
      expect(s.messagesOf(s.directChatId('m1')).length, before + 1);
      s.signInAsUser('m1');
      expect(s.unacceptedTasks.any((x) => x.id == t.id), isFalse);
    });

    test('чужую задачу принять нельзя', () {
      final s = AppState()..signInAsUser('m1');
      final t = create(s);
      s.acceptTask(t.id);
      expect(s.taskById(t.id).accepted, isFalse);
    });
  });

  group('переназначение', () {
    AppState setup() => AppState()..signInAsUser('m1');

    test('невыполненную задачу можно передать другому сотруднику', () {
      final s = setup();
      final t = s.addTask(
        title: 'Инвентаризация',
        assigneeIds: ['e1'],
        due: DateTime.now().add(const Duration(hours: 3)),
        requiredKinds: {ReportKind.photo},
      ).first;
      final other = s.employees.firstWhere((e) => e.id != 'e1');
      expect(s.reassignTask(t.id, other.id), isNull);
      expect(s.taskById(t.id).assigneeId, other.id);
      expect(s.taskById(t.id).accepted, isFalse);
      expect(s.messagesOf(s.directChatId(other.id)).last.taskId, t.id);
    });

    test('сотрудник переназначать не может', () {
      final s = setup();
      final t = s.addTask(
        title: 'Касса',
        assigneeIds: ['e1'],
        due: DateTime.now().add(const Duration(hours: 3)),
        requiredKinds: {ReportKind.photo},
      ).first;
      s.signInAsUser('e1');
      expect(s.reassignTask(t.id, 'm1'), isNotNull);
      expect(s.taskById(t.id).assigneeId, 'e1');
    });
  });

  group('задачи из чата', () {
    test('разовая задача создаётся одна и уходит сообщением в чат', () {
      final state = AppState()..signInAsUser('m1');
      final chatId = state.directChatId('e1');
      expect(state.canAssignIn(chatId), isTrue);

      final before = state.tasks.length;
      final created = state.addTask(
        title: 'Проверить кассу',
        assigneeIds: ['e1'],
        due: DateTime.now().add(const Duration(hours: 2)),
        requiredKinds: {ReportKind.photo},
      );
      state.shareTask(chatId, created.first.id);

      expect(state.tasks.length, before + 1);
      expect(state.messagesOf(chatId).last.taskId, created.first.id);

      state.signInAsUser('e1');
      expect(state.canAssignIn(state.directChatId('m1')), isFalse);
    });

    test('периодическая задача создаётся по расписанию', () {
      final state = AppState()..signInAsUser('m1');
      final before = state.tasks.length;
      final due = DateTime.now().add(const Duration(hours: 1));

      state.addTask(
        title: 'Ежедневная уборка',
        assigneeIds: ['e1'],
        due: due,
        requiredKinds: {ReportKind.photo},
        repeat: Repeat.daily,
      );
      expect(state.tasks.length, before + 31);

      final weekly = state.tasks.length;
      state.addTask(
        title: 'Инвентаризация',
        assigneeIds: ['e2'],
        due: due,
        requiredKinds: {ReportKind.text},
        repeat: Repeat.weekly,
      );
      final added = state.tasks.length - weekly;
      expect(added, inInclusiveRange(4, 5));

      state.addTask(
        title: 'Будни',
        assigneeIds: ['e3'],
        due: due,
        requiredKinds: {ReportKind.text},
        repeat: Repeat.weekdays,
      );
      expect(
        state.tasks
            .where((t) => t.title == 'Будни')
            .every((t) => t.due.weekday <= 5),
        isTrue,
      );
    });
  });

  group('успеваемость по дням', () {
    test('история задач даёт процент по прошедшим дням', () {
      final state = AppState();
      final now = DateTime.now();
      if (now.day < 3) return; // в начале месяца истории ещё нет

      var days = 0;
      for (var d = 1; d < now.day; d++) {
        final stats = state.teamStatsFor(DateTime(now.year, now.month, d));
        if (stats.total > 0) {
          days++;
          expect(stats.share, inInclusiveRange(0.0, 1.0));
        }
      }
      expect(days, greaterThan(0));
    });

    test('рейтинги разные: у сильного сотрудника выше, чем у слабого', () {
      final state = AppState();
      final now = DateTime.now();
      if (now.day < 5) return;

      expect(
        state.ratingFor('e2').total,
        greaterThan(state.ratingFor('e4').total),
      );
    });
  });
}
