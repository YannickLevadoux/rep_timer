import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rep_timer/models/build_metadata.dart';
import 'package:rep_timer/widgets/settings/app_about_dialog.dart';

void main() {
  final packageInfo = PackageInfo(
    appName: 'RepTimer Test',
    packageName: 'com.example.rep_timer',
    version: '1.2.0',
    buildNumber: '3',
  );

  testWidgets('un build DEV affiche le badge et la date injectée', (
    tester,
  ) async {
    final metadata = BuildMetadata.fromValues(
      buildTimestamp: '2026-08-03T12:32:00Z',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RepTimerAboutDialog(
          packageInfo: packageInfo,
          buildMetadata: metadata,
        ),
      ),
    );

    expect(find.byType(AboutDialog), findsOneWidget);
    expect(find.byType(Chip), findsOneWidget);
    expect(find.text('DEV'), findsOneWidget);
    expect(find.text(metadata.displayText!), findsOneWidget);
    expect(find.text('1.2.0 (3)'), findsOneWidget);
  });

  testWidgets('une release n’affiche ni badge ni date', (tester) async {
    final metadata = BuildMetadata.fromValues(
      distribution: 'release',
      buildTimestamp: '2026-08-03T12:32:00Z',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RepTimerAboutDialog(
          packageInfo: packageInfo,
          buildMetadata: metadata,
        ),
      ),
    );

    expect(find.byType(Chip), findsNothing);
    expect(find.text('DEV'), findsNothing);
    expect(find.textContaining('Build local'), findsNothing);
    expect(find.text('1.2.0 (3)'), findsOneWidget);
  });

  testWidgets('un build DEV sans timestamp conserve le badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RepTimerAboutDialog(
          packageInfo: packageInfo,
          buildMetadata: BuildMetadata.fromValues(),
        ),
      ),
    );

    expect(find.text('DEV'), findsOneWidget);
    expect(find.text('Build local : date indisponible'), findsOneWidget);
  });

  testWidgets('conserve l’accès Material aux licences', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RepTimerAboutDialog(
          packageInfo: packageInfo,
          buildMetadata: BuildMetadata.fromValues(distribution: 'release'),
        ),
      ),
    );

    final context = tester.element(find.byType(AboutDialog));
    final licensesLabel = MaterialLocalizations.of(
      context,
    ).viewLicensesButtonLabel;

    expect(find.text(licensesLabel), findsOneWidget);
    await tester.tap(find.text(licensesLabel));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
