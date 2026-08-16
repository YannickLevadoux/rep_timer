import 'package:flutter/material.dart';

import '../models/session_step.dart';
import '../models/training.dart';
import '../models/training_item.dart';
import 'app_settings_storage.dart';
import 'session_notification_permission_service.dart';

bool sessionNeedsBackgroundTracking(Training training) {
  return buildSessionSteps(training).any((step) {
    final item = step.item;
    if (item.type == ItemType.rest) return item.duration != null;
    return item.duration != null || item.isFreeDuration;
  });
}

/// Orchestre uniquement l'explication précédant le premier lancement. La
/// navigation reste sous la responsabilité de l'écran appelant.
class SessionStartPermissionGate {
  SessionStartPermissionGate({
    SessionNotificationPermissionService? permissionService,
    SessionPermissionPromptStorage? settingsStorage,
    AppSettingsStorage? countdownStorage,
  }) : _permissionService =
           permissionService ?? SessionNotificationPermissionService() {
    final defaultStorage = AppSettingsStorage();
    _settingsStorage = settingsStorage ?? defaultStorage;
    _countdownStorage =
        countdownStorage ??
        (settingsStorage is AppSettingsStorage
            ? settingsStorage
            : settingsStorage == null
            ? defaultStorage
            : null);
  }

  final SessionNotificationPermissionService _permissionService;
  late final SessionPermissionPromptStorage _settingsStorage;
  late final AppSettingsStorage? _countdownStorage;

  Future<int> prepare(BuildContext context, Training training) async {
    await _preparePermission(context, training);
    return _countdownStorage?.loadPreSessionCountdownSeconds() ??
        AppSettingsStorage.defaultPreSessionCountdownSeconds;
  }

  Future<void> _preparePermission(
    BuildContext context,
    Training training,
  ) async {
    if (!sessionNeedsBackgroundTracking(training)) return;

    final permission = await _permissionService.notificationPermissionStatus();
    if (!context.mounted ||
        permission == SessionNotificationPermissionStatus.granted ||
        permission == SessionNotificationPermissionStatus.unavailable) {
      return;
    }

    final alreadyPresented = await _loadPresentedBestEffort();
    if (!context.mounted || alreadyPresented) return;

    final shouldRequest = await _showExplanation(context);
    if (!context.mounted || shouldRequest == null) return;

    await _savePresentedBestEffort();
    if (shouldRequest) {
      await _permissionService.requestNotificationPermission();
    }
  }

  Future<bool> _loadPresentedBestEffort() async {
    try {
      return await _settingsStorage
          .loadSessionNotificationExplanationPresented();
    } on Object catch (error) {
      debugPrint(
        "Impossible de lire l'état de l'explication des notifications : "
        '$error',
      );
      return false;
    }
  }

  Future<void> _savePresentedBestEffort() async {
    try {
      await _settingsStorage.saveSessionNotificationExplanationPresented(true);
    } on Object catch (error) {
      debugPrint(
        "Impossible d'enregistrer l'état de l'explication des "
        'notifications : $error',
      );
    }
  }

  Future<bool?> _showExplanation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined),
        title: const Text('Suivre la séance en arrière-plan'),
        content: const SingleChildScrollView(
          child: Text(
            "RepTimer peut afficher la progression de la séance pendant "
            "l'utilisation d'une autre application. La notification permet "
            "de suivre le chronomètre et de mettre en pause ou reprendre la "
            "séance.\n\nTu peux refuser : la séance démarrera quand même.",
          ),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Pas maintenant, démarrer sans notification',
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Pas maintenant'),
            ),
          ),
          Semantics(
            button: true,
            label: "Autoriser les notifications de séance",
            child: FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Autoriser'),
            ),
          ),
        ],
      ),
    );
  }
}
