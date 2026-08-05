String formatRepetitionSequence(List<int> values) => values.join(' → ');

String formatRepetitionSequenceSummary(List<int> values) {
  final tours = values.length == 1 ? '1 tour' : '${values.length} tours';
  if (values.isEmpty) return 'Suite à définir';
  return '$tours · ${formatRepetitionSequence(values)}';
}
