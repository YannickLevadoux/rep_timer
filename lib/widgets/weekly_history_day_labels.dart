import '../services/weekly_history_aggregation.dart';
import '../utils/formatters.dart';

const weeklyHistoryShortWeekdays = [
  'Lun',
  'Mar',
  'Mer',
  'Jeu',
  'Ven',
  'Sam',
  'Dim',
];

const _longWeekdays = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

const _months = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

String formatWeeklyHistoryDayDetail(WeeklyHistoryDay day) {
  final sessions = day.sessionCount > 1 ? 'séances' : 'séance';
  return '${_longWeekdays[day.date.weekday - 1]} ${day.date.day} '
      '${_months[day.date.month - 1]} — ${formatLongDuration(day.duration)} '
      '· ${day.sessionCount} $sessions';
}
