import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/build_metadata.dart';

void main() {
  group('BuildMetadata', () {
    test('utilise le canal DEV par défaut', () {
      final metadata = BuildMetadata.fromValues();
      final environmentMetadata = BuildMetadata.fromEnvironment();

      expect(metadata.channel, DistributionChannel.dev);
      expect(metadata.isDevelopment, isTrue);
      expect(environmentMetadata.channel, DistributionChannel.dev);
    });

    test('reconnaît le canal release explicite', () {
      final metadata = BuildMetadata.fromValues(distribution: 'release');

      expect(metadata.channel, DistributionChannel.release);
      expect(metadata.isDevelopment, isFalse);
      expect(metadata.displayText, isNull);
    });

    test('parse un timestamp ISO 8601 valide', () {
      final metadata = BuildMetadata.fromValues(
        buildTimestamp: '2026-08-03T12:32:00Z',
      );

      expect(metadata.buildTimestamp, DateTime.utc(2026, 8, 3, 12, 32));
    });

    test('convertit le timestamp UTC dans le fuseau local avant affichage', () {
      final utcTimestamp = DateTime.utc(2026, 8, 3, 12, 32);
      final localTimestamp = utcTimestamp.toLocal();
      final metadata = BuildMetadata.fromValues(
        buildTimestamp: utcTimestamp.toIso8601String(),
      );
      final expectedDay = localTimestamp.day.toString().padLeft(2, '0');
      final expectedMonth = localTimestamp.month.toString().padLeft(2, '0');
      final expectedHour = localTimestamp.hour.toString().padLeft(2, '0');
      final expectedMinute = localTimestamp.minute.toString().padLeft(2, '0');

      expect(
        metadata.displayText,
        'Build local : $expectedDay/$expectedMonth/${localTimestamp.year} '
        'à $expectedHour:$expectedMinute',
      );
    });

    test('tolère un timestamp absent ou invalide', () {
      final missing = BuildMetadata.fromValues();
      final invalid = BuildMetadata.fromValues(buildTimestamp: 'pas-une-date');

      expect(missing.buildTimestamp, isNull);
      expect(invalid.buildTimestamp, isNull);
      expect(missing.displayText, 'Build local : date indisponible');
      expect(invalid.displayText, 'Build local : date indisponible');
    });

    test('considère un canal inconnu comme DEV', () {
      final metadata = BuildMetadata.fromValues(distribution: 'preview');

      expect(metadata.channel, DistributionChannel.dev);
    });
  });
}
