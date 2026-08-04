import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/screens/permissions_screen.dart';
import 'package:rep_timer/screens/settings_screen.dart';
import 'package:rep_timer/services/session_notification_permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('sépare les deux sujets et masque les actions inutiles', (
    tester,
  ) async {
    final platform = _FakePlatform(
      notificationStatus: SessionNotificationPermissionStatus.granted,
      batteryStatus: BatteryOptimizationStatus.exempt,
    );
    await _pumpPermissions(tester, platform);

    expect(find.text('Notifications de séance'), findsOneWidget);
    expect(find.text('Fonctionnement en arrière-plan'), findsOneWidget);
    expect(find.text('Autorisées'), findsOneWidget);
    expect(find.text('Fiabilité renforcée'), findsOneWidget);
    expect(find.text('Autoriser'), findsNothing);
    expect(find.text('Améliorer la fiabilité'), findsNothing);
  });

  testWidgets('le refus définitif ouvre les réglages injectés', (tester) async {
    final platform = _FakePlatform(
      notificationStatus: SessionNotificationPermissionStatus.permanentlyDenied,
    );
    await _pumpPermissions(tester, platform);

    expect(find.text('Refusées définitivement'), findsOneWidget);
    await tester.tap(find.text('Ouvrir les réglages Android'));
    await tester.pump();

    expect(platform.openSettingsCalls, 1);
  });

  testWidgets('actualise le statut au retour dans l’application', (
    tester,
  ) async {
    final platform = _FakePlatform(
      notificationStatus: SessionNotificationPermissionStatus.permanentlyDenied,
    );
    await _pumpPermissions(tester, platform);
    platform.notificationStatus = SessionNotificationPermissionStatus.granted;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Autorisées'), findsOneWidget);
    expect(find.text('Ouvrir les réglages Android'), findsNothing);
  });

  testWidgets('confirme la demande batterie et la présente comme facultative', (
    tester,
  ) async {
    final platform = _FakePlatform();
    await _pumpPermissions(tester, platform);

    await tester.tap(find.text('Améliorer la fiabilité'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cette option est facultative'), findsOneWidget);
    expect(platform.batteryRequests, 0);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(platform.batteryRequests, 1);
    expect(find.text('Fiabilité renforcée'), findsOneWidget);
  });

  testWidgets('désactive l’action pendant une demande de notification', (
    tester,
  ) async {
    final requestCompleter = Completer<void>();
    final platform = _FakePlatform(requestCompleter: requestCompleter);
    await _pumpPermissions(tester, platform);

    await tester.tap(find.text('Autoriser'));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Demande en cours…'),
    );
    expect(button.onPressed, isNull);
    expect(platform.notificationRequests, 1);

    requestCompleter.complete();
    await tester.pumpAndSettle();
    expect(find.text('Autorisées'), findsOneWidget);
  });

  testWidgets('la ligne compacte remplace l’ancien bouton et ouvre la page', (
    tester,
  ) async {
    final platform = _FakePlatform();
    final service = SessionNotificationPermissionService(platform: platform);
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          themeMode: ThemeMode.system,
          onToggleTheme: () {},
          permissionService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Activer les notifications de séance'), findsNothing);
    expect(find.text('Autorisations'), findsOneWidget);
    expect(find.text('Notifications désactivées'), findsOneWidget);

    await tester.tap(find.text('Autorisations'));
    await tester.pumpAndSettle();
    expect(find.byType(PermissionsScreen), findsOneWidget);
  });

  testWidgets('ne déborde pas sur une petite largeur et un texte agrandi', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(240, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final platform = _FakePlatform(
      notificationStatus: SessionNotificationPermissionStatus.permanentlyDenied,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: PermissionsScreen(
            permissionService: SessionNotificationPermissionService(
              platform: platform,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPermissions(
  WidgetTester tester,
  _FakePlatform platform,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PermissionsScreen(
        permissionService: SessionNotificationPermissionService(
          platform: platform,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakePlatform implements SessionNotificationPermissionPlatform {
  _FakePlatform({
    this.notificationStatus = SessionNotificationPermissionStatus.denied,
    this.batteryStatus = BatteryOptimizationStatus.optimized,
    this.requestCompleter,
  });

  SessionNotificationPermissionStatus notificationStatus;
  BatteryOptimizationStatus batteryStatus;
  final Completer<void>? requestCompleter;
  int notificationRequests = 0;
  int batteryRequests = 0;
  int openSettingsCalls = 0;

  @override
  void initialize() {}

  @override
  Future<SessionNotificationPermissionStatus>
  notificationPermissionStatus() async => notificationStatus;

  @override
  Future<SessionNotificationPermissionStatus>
  requestNotificationPermission() async {
    notificationRequests++;
    await requestCompleter?.future;
    notificationStatus = SessionNotificationPermissionStatus.granted;
    return notificationStatus;
  }

  @override
  Future<bool> openNotificationSettings() async {
    openSettingsCalls++;
    return true;
  }

  @override
  Future<BatteryOptimizationStatus> batteryOptimizationStatus() async =>
      batteryStatus;

  @override
  Future<void> requestBatteryOptimizationExemption() async {
    batteryRequests++;
    batteryStatus = BatteryOptimizationStatus.exempt;
  }
}
