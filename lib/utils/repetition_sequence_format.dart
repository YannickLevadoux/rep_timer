String formatRepetitionSequence(List<int> values) => values.join(' → ');

String formatRepetitionSequenceSummary(List<int> values) {
  return _formatRepetitionSequenceSummary(
    values,
    tourCount: values.length == 1 ? '1 tour' : '${values.length} tours',
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
