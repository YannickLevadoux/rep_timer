import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/services/session_notification_permission_service.dart';

void main() {
  test('demande uniquement les autorisations manquantes', () async {
    final platform = _FakePermissionPlatform(
      notificationGranted: false,
      ignoringBatteryOptimizations: false,
    );
    final service = SessionNotificationPermissionService(platform: platform);

    await service.requestPermissions();

    expect(platform.initializeCalls, 1);
    expect(platform.notificationRequestCalls, 1);
    expect(platform.batteryRequestCalls, 1);
  });

  test('ne redemande pas les autorisations déjà accordées', () async {
    final platform = _FakePermissionPlatform(
      notificationGranted: true,
      ignoringBatteryOptimizations: true,
    );
    final service = SessionNotificationPermissionService(platform: platform);

    await service.requestPermissions();

    expect(platform.notificationRequestCalls, 0);
    expect(platform.batteryRequestCalls, 0);
  });
}

class _FakePermissionPlatform implements SessionNotificationPermissionPlatform {
  _FakePermissionPlatform({
    required this.notificationGranted,
    required this.ignoringBatteryOptimizations,
  });

  final bool notificationGranted;
  final bool ignoringBatteryOptimizations;
  int initializeCalls = 0;
  int notificationRequestCalls = 0;
  int batteryRequestCalls = 0;

  @override
  void initialize() => initializeCalls++;

  @override
  Future<bool> hasNotificationPermission() async => notificationGranted;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async =>
      ignoringBatteryOptimizations;

  @override
  Future<void> requestNotificationPermission() async {
    notificationRequestCalls++;
  }

  @override
  Future<void> requestIgnoreBatteryOptimization() async {
    batteryRequestCalls++;
  }
}
