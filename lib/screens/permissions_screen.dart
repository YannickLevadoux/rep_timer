import 'package:flutter/material.dart';

import '../services/session_notification_permission_service.dart';

enum _PermissionAction { notification, settings, battery }

class PermissionsScreen extends StatefulWidget {
  final SessionNotificationPermissionService? permissionService;

  const PermissionsScreen({super.key, this.permissionService});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  late final SessionNotificationPermissionService _permissionService;
  SessionNotificationPermissionStatus? _notificationStatus;
  BatteryOptimizationStatus? _batteryStatus;
  _PermissionAction? _busyAction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _permissionService =
        widget.permissionService ?? SessionNotificationPermissionService();
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final notification = await _permissionService
        .notificationPermissionStatus();
    final battery = await _permissionService.batteryOptimizationStatus();
    if (!mounted) return;
    setState(() {
      _notificationStatus = notification;
      _batteryStatus = battery;
    });
  }

  Future<void> _requestNotification() async {
    if (_busyAction != null) return;
    setState(() => _busyAction = _PermissionAction.notification);
    try {
      final status = await _permissionService.requestNotificationPermission();
      if (mounted) setState(() => _notificationStatus = status);
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _openNotificationSettings() async {
    if (_busyAction != null) return;
    setState(() => _busyAction = _PermissionAction.settings);
    try {
      await _permissionService.openNotificationSettings();
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _requestBatteryExemption() async {
    if (_busyAction != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Améliorer la fiabilité ?'),
        content: const SingleChildScrollView(
          child: Text(
            "Cette option est facultative. Elle ouvre une demande Android "
            "pour désactiver l'optimisation batterie de RepTimer et peut "
            "améliorer le chronomètre en arrière-plan sur certains appareils. "
            "Elle n'est pas nécessaire pour démarrer une séance.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyAction = _PermissionAction.battery);
    try {
      final status = await _permissionService
          .requestBatteryOptimizationExemption();
      if (mounted) setState(() => _batteryStatus = status);
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  String get _notificationStatusLabel => switch (_notificationStatus) {
    SessionNotificationPermissionStatus.granted => 'Autorisées',
    SessionNotificationPermissionStatus.denied => 'Refusées',
    SessionNotificationPermissionStatus.permanentlyDenied =>
      'Refusées définitivement',
    SessionNotificationPermissionStatus.unavailable => 'État indisponible',
    null => 'Consultation en cours',
  };

  String get _batteryStatusLabel => switch (_batteryStatus) {
    BatteryOptimizationStatus.optimized => 'Fiabilité standard',
    BatteryOptimizationStatus.exempt => 'Fiabilité renforcée',
    BatteryOptimizationStatus.unavailable => 'État indisponible',
    null => 'Consultation en cours',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autorisations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PermissionCard(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications de séance',
            description:
                "Elles affichent la progression et le chronomètre pendant "
                "l'utilisation d'une autre application, avec les actions "
                "pause et reprise.",
            statusLabel: _notificationStatusLabel,
            statusLoading: _notificationStatus == null,
            action: _notificationAction(),
          ),
          const SizedBox(height: 16),
          _PermissionCard(
            icon: Icons.battery_saver_outlined,
            title: 'Fonctionnement en arrière-plan',
            description:
                "Facultatif : désactiver l'optimisation batterie peut "
                "améliorer la fiabilité du chronomètre en arrière-plan sur "
                "certains appareils. Ce n'est jamais nécessaire pour "
                "démarrer une séance.",
            statusLabel: _batteryStatusLabel,
            statusLoading: _batteryStatus == null,
            action: _batteryAction(),
          ),
        ],
      ),
    );
  }

  Widget? _notificationAction() {
    final busy = _busyAction != null;
    return switch (_notificationStatus) {
      SessionNotificationPermissionStatus.denied => FilledButton(
        onPressed: busy ? null : _requestNotification,
        child: Text(
          _busyAction == _PermissionAction.notification
              ? 'Demande en cours…'
              : 'Autoriser',
          textAlign: TextAlign.center,
        ),
      ),
      SessionNotificationPermissionStatus.permanentlyDenied => FilledButton(
        onPressed: busy ? null : _openNotificationSettings,
        child: Text(
          _busyAction == _PermissionAction.settings
              ? 'Ouverture…'
              : 'Ouvrir les réglages Android',
          textAlign: TextAlign.center,
        ),
      ),
      SessionNotificationPermissionStatus.unavailable => OutlinedButton(
        onPressed: busy ? null : _refresh,
        child: const Text('Actualiser'),
      ),
      SessionNotificationPermissionStatus.granted || null => null,
    };
  }

  Widget? _batteryAction() {
    final busy = _busyAction != null;
    return switch (_batteryStatus) {
      BatteryOptimizationStatus.optimized => FilledButton(
        onPressed: busy ? null : _requestBatteryExemption,
        child: Text(
          _busyAction == _PermissionAction.battery
              ? 'Demande en cours…'
              : 'Améliorer la fiabilité',
          textAlign: TextAlign.center,
        ),
      ),
      BatteryOptimizationStatus.unavailable => OutlinedButton(
        onPressed: busy ? null : _refresh,
        child: const Text('Actualiser'),
      ),
      BatteryOptimizationStatus.exempt || null => null,
    };
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String statusLabel;
  final bool statusLoading;
  final Widget? action;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.statusLoading,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '$title, $statusLabel',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(description),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (statusLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.circle,
                        size: 10,
                        color: colorScheme.primary,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              if (action != null) ...[
                const SizedBox(height: 16),
                Semantics(button: true, child: action!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
