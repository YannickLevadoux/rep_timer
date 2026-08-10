import 'package:flutter/material.dart';

import '../controllers/permissions_controller.dart';
import '../services/session_notification_permission_service.dart';
import '../widgets/permissions_screen_view.dart';

class PermissionsScreen extends StatefulWidget {
  final SessionNotificationPermissionService? permissionService;

  const PermissionsScreen({super.key, this.permissionService});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  late final PermissionsController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = PermissionsController(
      permissionService:
          widget.permissionService ?? SessionNotificationPermissionService(),
    );
    _controller.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.refresh();
  }

  Future<void> _confirmBatteryExemption() async {
    if (_controller.busy) return;

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
    if (confirmed == true && mounted) {
      await _controller.requestBatteryExemption();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => PermissionsScreenView(
        notificationStatus: _controller.notificationStatus,
        batteryStatus: _controller.batteryStatus,
        busyAction: _controller.busyAction,
        onRefresh: _controller.refresh,
        onRequestNotification: _controller.requestNotification,
        onOpenNotificationSettings: _controller.openNotificationSettings,
        onRequestBatteryExemption: _confirmBatteryExemption,
      ),
    );
  }
}
