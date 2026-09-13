String formatRepetitionSequence(List<int> values) => values.join(' → ');

String formatRepetitionSequenceTourCount(List<int> values) {
  final count = values.length;
  return '$count ${count == 1 ? 'tour' : 'tours'}';
}

String formatRepetitionSequenceValuesSummary(List<int> values) {
  if (values.isEmpty) return 'Suite à définir';
  return formatRepetitionSequence(values);
}

String formatRepetitionSequenceSummary(List<int> values) {
  if (values.isEmpty) return formatRepetitionSequenceValuesSummary(values);
  return '${formatRepetitionSequenceTourCount(values)} · '
      '${formatRepetitionSequenceValuesSummary(values)}';
}
