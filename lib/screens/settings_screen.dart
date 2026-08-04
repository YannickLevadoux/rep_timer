import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/notification_mode.dart';
import '../models/notification_sound.dart';
import '../services/app_settings_storage.dart';
import '../services/json_prefs_storage.dart';
import '../services/session_notification_permission_service.dart';
import '../services/step_end_notification_service.dart';
import '../services/training_export_service.dart';
import '../utils/snack.dart';
import '../widgets/settings/app_about_dialog.dart';
import '../widgets/settings/settings_sections.dart';
import 'permissions_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final SessionNotificationPermissionService? permissionService;
  final AppSettingsStorage? settingsStorage;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    this.permissionService,
    this.settingsStorage,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TrainingExportService _exportService = TrainingExportService();
  final StepEndNotificationService _notificationService =
      StepEndNotificationService();

  late final AppSettingsStorage _settingsStorage;
  late final SessionNotificationPermissionService _sessionPermissions;
  bool _busy = false;
  bool _prefillExerciseName = AppSettingsStorage.defaultPrefillExerciseName;
  NotificationMode _notificationMode =
      AppSettingsStorage.defaultNotificationMode;
  SessionNotificationPermissionStatus? _sessionPermissionStatus;

  @override
  void initState() {
    super.initState();
    _settingsStorage = widget.settingsStorage ?? AppSettingsStorage();
    _sessionPermissions =
        widget.permissionService ?? SessionNotificationPermissionService();
    _loadPrefillExerciseNameSetting();
    _loadNotificationModeSetting();
    _loadSessionPermissionStatus();
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }

  Future<void> _loadPrefillExerciseNameSetting() async {
    final value = await _settingsStorage.loadPrefillExerciseName();
    if (mounted) setState(() => _prefillExerciseName = value);
  }

  Future<void> _togglePrefillExerciseName(bool value) async {
    setState(() => _prefillExerciseName = value);
    await _settingsStorage.savePrefillExerciseName(value);
  }

  Future<void> _loadNotificationModeSetting() async {
    final value = await _settingsStorage.loadNotificationMode();
    if (mounted) setState(() => _notificationMode = value);
  }

  Future<void> _loadSessionPermissionStatus() async {
    final status = await _sessionPermissions.notificationPermissionStatus();
    if (mounted) setState(() => _sessionPermissionStatus = status);
  }

  Future<void> _cycleNotificationMode() async {
    final newMode = _notificationMode.next;
    setState(() => _notificationMode = newMode);
    await _settingsStorage.saveNotificationMode(newMode);

    switch (newMode) {
      case NotificationMode.sound:
        await _notificationService.playPreview(NotificationSound.classic);
      case NotificationMode.vibration:
        await _notificationService.vibrate();
      case NotificationMode.none:
        break;
    }
  }

  Future<void> _openPermissions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PermissionsScreen(permissionService: _sessionPermissions),
      ),
    );
    if (mounted) _loadSessionPermissionStatus();
  }

  Future<void> _handleExport() async {
    setState(() => _busy = true);
    try {
      final filePath = await _exportService.exportToFile();
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Export des séances RepTimer',
        ),
      );
    } on StorageMutationBlockedException {
      if (!mounted) return;
      showSnack(
        context,
        "Les séances enregistrées sont illisibles. L'export a été interrompu "
        'pour protéger les données.',
      );
    } catch (error) {
      if (mounted) showSnack(context, "Erreur lors de l'export : $error");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null) return;

    final path = result.files.single.path;
    if (path == null) return;
    setState(() => _busy = true);

    try {
      final content = await File(path).readAsString();
      final importResult = await _exportService.importFromJsonString(content);
      if (!mounted) return;
      showSnack(
        context,
        'Import terminé : ${importResult.importedCount} séance(s) importée(s).',
      );
    } on FormatException catch (error) {
      if (mounted) showSnack(context, error.message);
    } on StorageMutationBlockedException {
      if (!mounted) return;
      showSnack(
        context,
        "L'import est impossible car certaines séances enregistrées n'ont "
        'pas pu être lues.',
      );
    } catch (error) {
      if (mounted) showSnack(context, "Erreur lors de l'import : $error");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsContent(
      themeMode: widget.themeMode,
      onToggleTheme: widget.onToggleTheme,
      prefillExerciseName: _prefillExerciseName,
      onPrefillChanged: _togglePrefillExerciseName,
      notificationMode: _notificationMode,
      onCycleNotificationMode: _cycleNotificationMode,
      busy: _busy,
      onImport: _handleImport,
      onExport: _handleExport,
      permissionStatus: _sessionPermissionStatus,
      onOpenPermissions: _openPermissions,
      onOpenAbout: () => showRepTimerAboutDialog(context),
    );
  }
}
