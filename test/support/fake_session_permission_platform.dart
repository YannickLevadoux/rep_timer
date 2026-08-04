import 'package:rep_timer/services/session_notification_permission_service.dart';

class GrantedSessionPermissionPlatform
    implements SessionNotificationPermissionPlatform {
  @override
  void initialize() {}

  @override
  Future<SessionNotificationPermissionStatus>
  notificationPermissionStatus() async =>
      SessionNotificationPermissionStatus.granted;

  @override
  Future<SessionNotificationPermissionStatus>
  requestNotificationPermission() async =>
      SessionNotificationPermissionStatus.granted;

  @override
  Future<bool> openNotificationSettings() async => true;

  @override
  Future<BatteryOptimizationStatus> batteryOptimizationStatus() async =>
      BatteryOptimizationStatus.exempt;

  @override
  Future<void> requestBatteryOptimizationExemption() async {}
}
