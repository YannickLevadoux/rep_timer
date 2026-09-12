const _frenchMonths = [
  (full: 'janvier', abbreviated: 'janv.'),
  (full: 'février', abbreviated: 'févr.'),
  (full: 'mars', abbreviated: 'mars'),
  (full: 'avril', abbreviated: 'avr.'),
  (full: 'mai', abbreviated: 'mai'),
  (full: 'juin', abbreviated: 'juin'),
  (full: 'juillet', abbreviated: 'juil.'),
  (full: 'août', abbreviated: 'août'),
  (full: 'septembre', abbreviated: 'sept.'),
  (full: 'octobre', abbreviated: 'oct.'),
  (full: 'novembre', abbreviated: 'nov.'),
  (full: 'décembre', abbreviated: 'déc.'),
];

/// Renvoie le nom français d'un mois, sous sa forme complète ou abrégée.
String frenchMonthName(int month, {bool abbreviated = false}) {
  final names = _frenchMonths[month - 1];
  return abbreviated ? names.abbreviated : names.full;
}

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

/// Formate toujours une durée en "hh:mm:ss", notamment pour les agrégats.
String formatLongDuration(Duration duration) {
  final clamped = duration.isNegative ? Duration.zero : duration;
  final hours = clamped.inHours.toString().padLeft(2, '0');
  final minutes = clamped.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = clamped.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
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
