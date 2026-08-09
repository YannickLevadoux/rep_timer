import '../services/monthly_history_aggregation.dart';
import '../utils/formatters.dart';

String formatMonthlyCountSummary(MonthlyHistorySummary summary) {
  if (summary.totalCount == 0) return '0 séance';
  return '${summary.totalCount} ${monthlyHistoryPlural(summary.totalCount, 'séance')} — '
      '${summary.completedCount} '
      '${monthlyHistoryPlural(summary.completedCount, 'terminée')} · '
      '${summary.incompleteCount} '
      '${monthlyHistoryPlural(summary.incompleteCount, 'incomplète')}';
}

String formatMonthlySemanticSummary(
  MonthlyHistorySummary summary, {
  required bool showDuration,
}) {
  final month = formatLocalMonthLabel(summary.month);
  if (!showDuration) {
    return 'Bilan mensuel de $month : ${formatMonthlyCountSummary(summary)}';
  }
  return 'Bilan mensuel de $month : '
      '${formatLongDuration(summary.totalDuration)} au total, '
      '${summary.totalCount} '
      '${monthlyHistoryPlural(summary.totalCount, 'séance')}';
}

String formatMonthlyWeekDetail(
  MonthlyHistoryWeekBucket bucket, {
  required bool showDuration,
  required bool isFuture,
}) {
  final period = formatMonthlyBucketPeriod(bucket);
  final detail = showDuration
      ? '$period — ${formatLongDuration(bucket.totalDuration)} · '
            '${bucket.totalCount} '
            '${monthlyHistoryPlural(bucket.totalCount, 'séance')}'
      : '$period — ${bucket.totalCount} '
            '${monthlyHistoryPlural(bucket.totalCount, 'séance')} · '
            '${bucket.completedCount} '
            '${monthlyHistoryPlural(bucket.completedCount, 'terminée')} · '
            '${bucket.incompleteCount} '
            '${monthlyHistoryPlural(bucket.incompleteCount, 'incomplète')}';
  return isFuture ? '$detail. Semaine à venir' : detail;
}

String monthlyHistoryPlural(int count, String singular) =>
    count > 1 ? '${singular}s' : singular;
