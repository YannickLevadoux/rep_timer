enum DistributionChannel { dev, release }

/// Métadonnées injectées à la compilation avec `--dart-define`.
///
/// Seul le canal explicite `release` désigne une distribution officielle.
/// Toute valeur absente ou inconnue conserve donc le comportement DEV.
class BuildMetadata {
  const BuildMetadata._({required this.channel, this.buildTimestamp});

  static const distributionDefine = 'REP_TIMER_DISTRIBUTION';
  static const buildTimestampDefine = 'REP_TIMER_BUILD_TIMESTAMP';

  factory BuildMetadata.fromEnvironment() {
    const distribution = String.fromEnvironment(
      distributionDefine,
      defaultValue: 'dev',
    );
    const buildTimestamp = String.fromEnvironment(buildTimestampDefine);

    return BuildMetadata.fromValues(
      distribution: distribution,
      buildTimestamp: buildTimestamp,
    );
  }

  /// Constructeur injectable utilisé par les tests et les aperçus d'interface.
  factory BuildMetadata.fromValues({
    String distribution = 'dev',
    String? buildTimestamp,
  }) {
    final normalizedDistribution = distribution.trim().toLowerCase();
    final normalizedTimestamp = buildTimestamp?.trim();

    return BuildMetadata._(
      channel: normalizedDistribution == 'release'
          ? DistributionChannel.release
          : DistributionChannel.dev,
      buildTimestamp: normalizedTimestamp == null || normalizedTimestamp.isEmpty
          ? null
          : DateTime.tryParse(normalizedTimestamp),
    );
  }

  final DistributionChannel channel;
  final DateTime? buildTimestamp;

  bool get isDevelopment => channel == DistributionChannel.dev;

  String? get displayText {
    if (!isDevelopment) return null;

    final timestamp = buildTimestamp;
    if (timestamp == null) return 'Build local : date indisponible';

    return 'Build local : ${formatLocalDateTime(timestamp)}';
  }

  static String formatLocalDateTime(DateTime timestamp) {
    final localTimestamp = timestamp.toLocal();
    final day = localTimestamp.day.toString().padLeft(2, '0');
    final month = localTimestamp.month.toString().padLeft(2, '0');
    final hour = localTimestamp.hour.toString().padLeft(2, '0');
    final minute = localTimestamp.minute.toString().padLeft(2, '0');

    return '$day/$month/${localTimestamp.year} à $hour:$minute';
  }
}
