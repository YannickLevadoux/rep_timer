import 'package:flutter/material.dart';

import '../controllers/settings_preferences_controller.dart';
import '../services/app_settings_storage.dart';
import '../services/session_notification_permission_service.dart';
import '../services/settings_transfer_service.dart';
import '../utils/snack.dart';
import '../widgets/settings/app_about_dialog.dart';
import '../widgets/settings/settings_sections.dart';
import '../widgets/dialogs/pre_session_countdown_dialog.dart';
import 'export_screen.dart';
import 'import_screen.dart';
import 'permissions_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final Future<ThemeMode> Function() onToggleTheme;
  final SessionNotificationPermissionService? permissionService;
  final AppSettingsStorage? settingsStorage;
  final SettingsTransferService? transferService;
  final ValueChanged<ThemeMode>? onThemeRestored;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    this.permissionService,
    this.settingsStorage,
    this.transferService,
    this.onThemeRestored,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsTransferService _transferService;
  late final AppSettingsStorage _settingsStorage;
  late final SettingsPreferencesController _preferences;
  late final SessionNotificationPermissionService _sessionPermissions;
  late ThemeMode _themeMode;
  bool _savingTheme = false;
  SessionNotificationPermissionStatus? _sessionPermissionStatus;

  @override
  void initState() {
    super.initState();
    _settingsStorage = widget.settingsStorage ?? AppSettingsStorage();
    _preferences = SettingsPreferencesController(_settingsStorage)
      ..addListener(_preferencesChanged)
      ..load();
    _transferService = widget.transferService ?? SettingsTransferService();
    _themeMode = widget.themeMode;
    _sessionPermissions =
        widget.permissionService ?? SessionNotificationPermissionService();
    _loadSessionPermissionStatus();
  }

  @override
  void dispose() {
    _preferences
      ..removeListener(_preferencesChanged)
      ..dispose();
    super.dispose();
  }

  void _preferencesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _cycleThemeMode() async {
    if (_savingTheme) return;
    setState(() => _savingTheme = true);
    try {
      final newMode = await widget.onToggleTheme();
      if (mounted) setState(() => _themeMode = newMode);
    } on Object {
      if (mounted) {
        showSnack(context, "Le thème n'a pas pu être enregistré. Réessayez.");
      }
    } finally {
      if (mounted) setState(() => _savingTheme = false);
    }
  }

  Future<void> _loadSessionPermissionStatus() async {
    final status = await _sessionPermissions.notificationPermissionStatus();
    if (mounted) setState(() => _sessionPermissionStatus = status);
  }

  Future<void> _editPreSessionCountdown() async {
    final value = await showPreSessionCountdownDialog(
      context,
      initialValue: _preferences.preSessionCountdownSeconds,
    );
    if (value == null || !mounted) return;
    try {
      await _preferences.setPreSessionCountdownSeconds(value);
    } on AppSettingsWriteException {
      if (mounted) {
        showSnack(context, "Le compte à rebours n'a pas pu être enregistré.");
      }
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

  void _applyRestoredSettings(ExportableAppSettings settings) {
    setState(() => _themeMode = settings.themeMode);
    _preferences.applyRestored(settings);
    widget.onThemeRestored?.call(settings.themeMode);
  }

  void _openImport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImportScreen(
          transferService: _transferService,
          onSettingsRestored: _applyRestoredSettings,
        ),
      ),
    );
  }

  void _openExport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExportScreen(transferService: _transferService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsContent(
      themeMode: _themeMode,
      onToggleTheme: _savingTheme ? null : _cycleThemeMode,
      prefillExerciseName: _preferences.prefillExerciseName,
      onPrefillChanged: _preferences.setPrefillExerciseName,
      notificationMode: _preferences.notificationMode,
      onCycleNotificationMode: _preferences.cycleNotificationMode,
      preSessionCountdownSeconds: _preferences.preSessionCountdownSeconds,
      onEditPreSessionCountdown: _editPreSessionCountdown,
      onImport: _openImport,
      onExport: _openExport,
      permissionStatus: _sessionPermissionStatus,
      onOpenPermissions: _openPermissions,
      onOpenAbout: () => showRepTimerAboutDialog(context),
    );
  }
}
