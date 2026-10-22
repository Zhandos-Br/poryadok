/// Русские названия дней и месяцев, чтобы не зависеть от локали устройства.
const ruWeekdays = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье',
];

const ruMonthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

const ruMonthsNominative = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

/// «Среда, 22 октября».
String dayLong(DateTime d) =>
    '${ruWeekdays[d.weekday - 1]}, ${d.day} ${ruMonthsGenitive[d.month - 1]}';

/// Склонение: 1 тема, 2 темы, 5 тем.
String plural(int n, String one, String few, String many) {
  final mod100 = n % 100;
  final mod10 = n % 10;
  if (mod100 >= 11 && mod100 <= 14) return many;
  if (mod10 == 1) return one;
  if (mod10 >= 2 && mod10 <= 4) return few;
  return many;
}
