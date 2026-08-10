import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/controllers/permissions_controller.dart';
import 'package:rep_timer/services/session_notification_permission_service.dart';

void main() {
  test('restitue tous les statuts de notification et de batterie', () async {
    final platform = _FakePermissionPlatform();
    final controller = _controller(platform);
    addTearDown(controller.dispose);

    for (final status in SessionNotificationPermissionStatus.values) {
      platform.notificationStatus = status;
      await controller.refresh();
      expect(controller.notificationStatus, status);
    }

    for (final status in BatteryOptimizationStatus.values) {
      platform.batteryStatus = status;
      await controller.refresh();
      expect(controller.batteryStatus, status);
    }
  });

  test('met à jour les statuts après chaque action', () async {
    final platform = _FakePermissionPlatform();
    final controller = _controller(platform);
    addTearDown(controller.dispose);
    await controller.refresh();

    await controller.requestNotification();
    expect(
      controller.notificationStatus,
      SessionNotificationPermissionStatus.granted,
    );

    await controller.openNotificationSettings();
    expect(platform.openSettingsCalls, 1);

    await controller.requestBatteryExemption();
    expect(controller.batteryStatus, BatteryOptimizationStatus.exempt);
  });

  test(
    'bloque les opérations concurrentes et expose l’action active',
    () async {
      final requestCompleter = Completer<void>();
      final platform = _FakePermissionPlatform(
        notificationRequestCompleter: requestCompleter,
      );
      final controller = _controller(platform);
      addTearDown(controller.dispose);
      await controller.refresh();

      final notificationRequest = controller.requestNotification();
      await Future<void>.delayed(Duration.zero);
      expect(controller.busy, isTrue);
      expect(controller.busyAction, PermissionAction.notification);

      await controller.openNotificationSettings();
      await controller.requestBatteryExemption();
      expect(platform.openSettingsCalls, 0);
      expect(platform.batteryRequests, 0);

      requestCompleter.complete();
      await notificationRequest;
      expect(controller.busy, isFalse);
      expect(controller.busyAction, isNull);
    },
  );
}

PermissionsController _controller(_FakePermissionPlatform platform) =>
    PermissionsController(
      permissionService: SessionNotificationPermissionService(
        platform: platform,
      ),
    );

class _FakePermissionPlatform implements SessionNotificationPermissionPlatform {
  _FakePermissionPlatform({this.notificationRequestCompleter});

  SessionNotificationPermissionStatus notificationStatus =
      SessionNotificationPermissionStatus.denied;
  BatteryOptimizationStatus batteryStatus = BatteryOptimizationStatus.optimized;
  final Completer<void>? notificationRequestCompleter;
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
    await notificationRequestCompleter?.future;
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
