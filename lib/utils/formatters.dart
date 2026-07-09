/// Formate une durée en "mm:ss", ou "hh:mm:ss" au-delà d'une heure.
/// Les valeurs négatives sont ramenées à zéro par sécurité.
String formatDuration(Duration duration) {
  final clamped = duration.isNegative ? Duration.zero : duration;
  final hours = clamped.inHours;
  final minutes = clamped.inMinutes.remainder(60);
  final seconds = clamped.inSeconds.remainder(60);

  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');

  return hours > 0 ? "${hours.toString().padLeft(2, '0')}:$mm:$ss" : "$mm:$ss";
}

/// Formate une date/heure en "jj/mm/aaaa à hh:mm".
String formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return "$day/$month/$year à $hour:$minute";
}