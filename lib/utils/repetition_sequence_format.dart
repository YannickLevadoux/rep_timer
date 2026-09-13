String formatRepetitionSequence(List<int> values) => values.join(' → ');

String formatRepetitionSequenceTourCount(List<int> values) {
  final count = values.length;
  return '$count ${count == 1 ? 'tour' : 'tours'}';
}

String formatRepetitionSequenceSummary(List<int> values) {
  return _formatRepetitionSequenceSummary(
    values,
    tourCount: formatRepetitionSequenceTourCount(values),
  );
}

String formatCompactRepetitionSequenceSummary(List<int> values) {
  return _formatRepetitionSequenceSummary(
    values,
    tourCount: '${values.length} t.',
  );
}

String _formatRepetitionSequenceSummary(
  List<int> values, {
  required String tourCount,
}) {
  if (values.isEmpty) return 'Suite à définir';
  return '$tourCount · ${formatRepetitionSequence(values)}';
}
