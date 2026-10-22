import 'package:flutter_test/flutter_test.dart';
import 'package:poryadok/app_state.dart';
import 'package:poryadok/models.dart';

void main() {
  group('темы в чатах', () {
    test('сообщения темы не попадают в основную переписку', () {
      final state = AppState()..signInAs(Role.employee);
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
      final state = AppState()..signInAs(Role.employee);
      final employeeSide = state.topicsOf('d:e1:m1').length;
      expect(employeeSide, greaterThan(0));

      state.signInAs(Role.manager);
      expect(state.topicsOf(state.directChatId('e1')).length, employeeSide);
    });
  });

  group('поиск по телефону', () {
    test('номер находится при любом написании', () {
      final state = AppState()..signInAs(Role.employee);
      expect(state.findUserByPhone('+7 777 123 45 67')?.id, 'x1');
      expect(state.findUserByPhone('8 (777) 123-45-67')?.id, 'x1');
      expect(state.findUserByPhone('+7 700 000 00 00'), isNull);
      expect(state.findUserByPhone('123'), isNull);
    });

    test('внешний контакт появляется в списке чатов после старта чата', () {
      final state = AppState()..signInAs(Role.employee);
      expect(state.chatPartners.any((u) => u.id == 'x1'), isFalse);

      state.startDirectChat('x1');
      expect(state.chatPartners.any((u) => u.id == 'x1'), isTrue);
    });
  });

  group('регистрация', () {
    test('без кода это личный аккаунт вне команды', () {
      final state = AppState();
      final teamBefore = state.employees.length;

      final error = state.register(
        fullName: 'Иванов Иван Иванович',
        nickname: '@ivan_i',
        phone: '+7 701 555 44 33',
      );

      expect(error, isNull);
      expect(state.me.name, 'Иванов Иван Иванович');
      expect(state.me.nickname, 'ivan_i');
      expect(state.me.external, isTrue);
      expect(state.employees.length, teamBefore);
    });

    test('с кодом приглашения человек попадает в команду', () {
      final state = AppState();
      final teamBefore = state.employees.length;

      final error = state.register(
        fullName: 'Петрова Анна',
        nickname: 'anna_p',
        phone: '+7 701 222 11 00',
        invite: 'poryadok',
      );

      expect(error, isNull);
      expect(state.employees.length, teamBefore + 1);
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
