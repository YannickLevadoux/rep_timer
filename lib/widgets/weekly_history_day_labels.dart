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
  return '${_formatDayDate(day)}\n${_formatWeeklyHistoryDurationBreakdown(day)}';
}

String formatWeeklyHistoryDurationDaySemantic(WeeklyHistoryDay day) {
  return '${_formatDayDate(day)} — '
      '${_formatWeeklyHistoryDurationBreakdown(day)}';
}

String _formatWeeklyHistoryDurationBreakdown(WeeklyHistoryDay day) {
  return '${formatLongDuration(day.duration)} '
      '· ${day.sessionCount} '
      '${weeklyHistoryPlural(day.sessionCount, 'séance')}';
}

String formatWeeklyHistoryCountSummary(WeeklyHistorySummary summary) {
  if (summary.totalCount == 0) return '0 séance';
  return '${summary.totalCount} '
      '${weeklyHistoryPlural(summary.totalCount, 'séance')} — '
      '${summary.completedCount} '
      '${weeklyHistoryPlural(summary.completedCount, 'terminée')} · '
      '${summary.incompleteCount} '
      '${weeklyHistoryPlural(summary.incompleteCount, 'incomplète')}';
}

String formatWeeklyHistoryCountSemanticSummary(WeeklyHistorySummary summary) =>
    'Bilan hebdomadaire : ${formatWeeklyHistoryCountSummary(summary)}';

String formatWeeklyHistoryCountDayDetail(WeeklyHistoryDay day) =>
    '${_formatDayDate(day)}\n${_formatWeeklyHistoryCountBreakdown(day)}';

String formatWeeklyHistoryCountDaySemantic(WeeklyHistoryDay day) =>
    '${_formatDayDate(day)} — ${_formatWeeklyHistoryCountBreakdown(day)}';

String _formatWeeklyHistoryCountBreakdown(WeeklyHistoryDay day) =>
    '${day.sessionCount} '
    '${weeklyHistoryPlural(day.sessionCount, 'séance')} · '
    '${day.completedCount} '
    '${weeklyHistoryPlural(day.completedCount, 'terminée')} · '
    '${day.incompleteCount} '
    '${weeklyHistoryPlural(day.incompleteCount, 'incomplète')}';

String weeklyHistoryPlural(int count, String singular) =>
    count > 1 ? '${singular}s' : singular;

String _formatDayDate(WeeklyHistoryDay day) =>
    '${_longWeekdays[day.date.weekday - 1]} ${day.date.day} '
    '${_months[day.date.month - 1]}';
