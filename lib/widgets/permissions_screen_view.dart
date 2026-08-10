import 'package:flutter/material.dart';

import '../controllers/permissions_controller.dart';
import '../services/session_notification_permission_service.dart';
import 'permission_card.dart';

class PermissionsScreenView extends StatelessWidget {
  final SessionNotificationPermissionStatus? notificationStatus;
  final BatteryOptimizationStatus? batteryStatus;
  final PermissionAction? busyAction;
  final VoidCallback onRefresh;
  final VoidCallback onRequestNotification;
  final VoidCallback onOpenNotificationSettings;
  final VoidCallback onRequestBatteryExemption;

  const PermissionsScreenView({
    super.key,
    required this.notificationStatus,
    required this.batteryStatus,
    required this.busyAction,
    required this.onRefresh,
    required this.onRequestNotification,
    required this.onOpenNotificationSettings,
    required this.onRequestBatteryExemption,
  });

  bool get _busy => busyAction != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autorisations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PermissionCard(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications de séance',
            description:
                "Elles affichent la progression et le chronomètre pendant "
                "l'utilisation d'une autre application, avec les actions "
                "pause et reprise.",
            statusLabel: _notificationStatusLabel,
            statusLoading: notificationStatus == null,
            action: _notificationAction(),
          ),
          const SizedBox(height: 16),
          PermissionCard(
            icon: Icons.battery_saver_outlined,
            title: 'Fonctionnement en arrière-plan',
            description:
                "Facultatif : désactiver l'optimisation batterie peut "
                "améliorer la fiabilité du chronomètre en arrière-plan sur "
                "certains appareils. Ce n'est jamais nécessaire pour "
                "démarrer une séance.",
            statusLabel: _batteryStatusLabel,
            statusLoading: batteryStatus == null,
            action: _batteryAction(),
          ),
        ],
      ),
    );
  }

  String get _notificationStatusLabel => switch (notificationStatus) {
    SessionNotificationPermissionStatus.granted => 'Autorisées',
    SessionNotificationPermissionStatus.denied => 'Refusées',
    SessionNotificationPermissionStatus.permanentlyDenied =>
      'Refusées définitivement',
    SessionNotificationPermissionStatus.unavailable => 'État indisponible',
    null => 'Consultation en cours',
  };

  String get _batteryStatusLabel => switch (batteryStatus) {
    BatteryOptimizationStatus.optimized => 'Fiabilité standard',
    BatteryOptimizationStatus.exempt => 'Fiabilité renforcée',
    BatteryOptimizationStatus.unavailable => 'État indisponible',
    null => 'Consultation en cours',
  };

  Widget? _notificationAction() => switch (notificationStatus) {
    SessionNotificationPermissionStatus.denied => FilledButton(
      onPressed: _busy ? null : onRequestNotification,
      child: Text(
        busyAction == PermissionAction.notification
            ? 'Demande en cours…'
            : 'Autoriser',
        textAlign: TextAlign.center,
      ),
    ),
    SessionNotificationPermissionStatus.permanentlyDenied => FilledButton(
      onPressed: _busy ? null : onOpenNotificationSettings,
      child: Text(
        busyAction == PermissionAction.settings
            ? 'Ouverture…'
            : 'Ouvrir les réglages Android',
        textAlign: TextAlign.center,
      ),
    ),
    SessionNotificationPermissionStatus.unavailable => OutlinedButton(
      onPressed: _busy ? null : onRefresh,
      child: const Text('Actualiser'),
    ),
    SessionNotificationPermissionStatus.granted || null => null,
  };

  Widget? _batteryAction() => switch (batteryStatus) {
    BatteryOptimizationStatus.optimized => FilledButton(
      onPressed: _busy ? null : onRequestBatteryExemption,
      child: Text(
        busyAction == PermissionAction.battery
            ? 'Demande en cours…'
            : 'Améliorer la fiabilité',
        textAlign: TextAlign.center,
      ),
    ),
    BatteryOptimizationStatus.unavailable => OutlinedButton(
      onPressed: _busy ? null : onRefresh,
      child: const Text('Actualiser'),
    ),
    BatteryOptimizationStatus.exempt || null => null,
  };
}
