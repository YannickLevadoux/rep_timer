import 'package:flutter/foundation.dart';

import '../services/session_notification_permission_service.dart';

enum PermissionAction { notification, settings, battery }

/// Centralise les statuts et les opérations de la page des autorisations.
class PermissionsController extends ChangeNotifier {
  PermissionsController({required this.permissionService});

  final SessionNotificationPermissionService permissionService;

  SessionNotificationPermissionStatus? notificationStatus;
  BatteryOptimizationStatus? batteryStatus;
  PermissionAction? busyAction;
  bool _disposed = false;

  bool get busy => busyAction != null;

  Future<void> refresh() async {
    final notification = await permissionService.notificationPermissionStatus();
    final battery = await permissionService.batteryOptimizationStatus();
    if (_disposed) return;

    notificationStatus = notification;
    batteryStatus = battery;
    notifyListeners();
  }

  Future<void> requestNotification() async {
    await _run(PermissionAction.notification, () async {
      final status = await permissionService.requestNotificationPermission();
      if (!_disposed) notificationStatus = status;
    });
  }

  Future<void> openNotificationSettings() async {
    await _run(PermissionAction.settings, () async {
      await permissionService.openNotificationSettings();
    });
  }

  Future<void> requestBatteryExemption() async {
    await _run(PermissionAction.battery, () async {
      final status = await permissionService
          .requestBatteryOptimizationExemption();
      if (!_disposed) batteryStatus = status;
    });
  }

  Future<void> _run(
    PermissionAction action,
    Future<void> Function() operation,
  ) async {
    if (_disposed || busy) return;
    busyAction = action;
    notifyListeners();
    try {
      await operation();
    } finally {
      busyAction = null;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
