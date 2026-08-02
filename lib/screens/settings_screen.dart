import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../models/notification_mode.dart';
import '../models/notification_sound.dart';
import '../services/app_settings_storage.dart';
import '../services/session_notification_service.dart';
import '../services/step_end_notification_service.dart';
import '../services/training_export_service.dart';
import '../utils/notification_mode_icons.dart';
import '../utils/snack.dart';
import '../widgets/settings_section.dart';

// Copyright affiché dans la boîte de dialogue "À propos". Aucun autre
// endroit dans le projet ne porte cette information : c'est ici, et
// uniquement ici, qu'il faut la modifier.
const String _copyright = "© 2026 Yannick Levadoux";

// Icône de l'application, réutilisée pour la boîte de dialogue "À
// propos". Doit être déclarée dans pubspec.yaml sous flutter: assets:
// (voir la documentation fournie avec cette fonctionnalité).
const String _appIconAsset = "assets/icon/app_icon.png";

/// Écran centralisant les paramètres de l'application, organisé en
/// sections pour faciliter l'ajout de nouveaux réglages à l'avenir.
class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TrainingExportService _exportService = TrainingExportService();
  final AppSettingsStorage _settingsStorage = AppSettingsStorage();
  final StepEndNotificationService _notificationService =
      StepEndNotificationService();
  final SessionNotificationService _sessionNotificationService =
      SessionNotificationService();

  // Désactive le bouton pendant la demande de permissions (peut ouvrir un
  // écran système et prendre quelques secondes), pour éviter tout
  // double-déclenchement.
  bool _requestingSessionNotificationPermissions = false;

  // Désactive les actions Importer/Exporter pendant qu'une opération est
  // en cours, pour éviter tout double-déclenchement.
  bool _busy = false;

  // Reflète la préférence persistée (voir AppSettingsStorage) ; valeur
  // par défaut identique à celle du storage le temps du chargement
  // asynchrone initial, pour éviter un flash à une valeur incorrecte.
  bool _prefillExerciseName = AppSettingsStorage.defaultPrefillExerciseName;

  // Configuration globale des notifications de fin d'exercice/pause :
  // c'est cette valeur que SessionController relit au démarrage de
  // chaque nouvelle séance (voir sa configuration de session).
  NotificationMode _notificationMode =
      AppSettingsStorage.defaultNotificationMode;

  @override
  void initState() {
    super.initState();
    _loadPrefillExerciseNameSetting();
    _loadNotificationModeSetting();
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }

  // Relit systématiquement la valeur enregistrée (plutôt que de la
  // supposer inchangée) : c'est ce qui garantit la synchronisation avec
  // le dialogue de réglages du GroupEditor, qui pilote la même
  // préférence.
  Future<void> _loadPrefillExerciseNameSetting() async {
    final value = await _settingsStorage.loadPrefillExerciseName();
    if (!mounted) return;
    setState(() => _prefillExerciseName = value);
  }

  // Bascule et persiste immédiatement (comme le bouton de thème
  // ci-dessous) : pas de confirmation nécessaire sur cet écran, une
  // simple ligne de réglage suffit.
  Future<void> _togglePrefillExerciseName(bool value) async {
    setState(() => _prefillExerciseName = value);
    await _settingsStorage.savePrefillExerciseName(value);
  }

  Future<void> _loadNotificationModeSetting() async {
    final value = await _settingsStorage.loadNotificationMode();
    if (!mounted) return;
    setState(() => _notificationMode = value);
  }

  // Fait défiler Son -> Vibration -> Rien -> Son, persiste immédiatement
  // le nouveau mode, puis joue son aperçu (sauf pour "Rien", qui n'en a
  // pas). Cet aperçu n'est joué que depuis cet écran, jamais depuis le
  // contrôle rapide de l'écran d'exécution d'une séance. Le service ne
  // connaissant plus la notion de "mode" (voir StepEndNotificationService),
  // c'est ici que ce mapping mode -> action se fait.
  Future<void> _cycleNotificationMode() async {
    final newMode = _notificationMode.next;
    setState(() => _notificationMode = newMode);
    await _settingsStorage.saveNotificationMode(newMode);

    switch (newMode) {
      case NotificationMode.sound:
        await _notificationService.playPreview(NotificationSound.classic);
        break;
      case NotificationMode.vibration:
        await _notificationService.vibrate();
        break;
      case NotificationMode.none:
        break;
    }
  }

  // Redéclenche explicitement les demandes de permissions liées à la
  // notification persistante de séance (voir SessionNotificationService.
  // requestPermissions) : utile si l'utilisateur les avait refusées par
  // erreur au premier lancement d'une séance, sans avoir à en relancer
  // une pour réessayer. Peut ouvrir un écran système (exemption de
  // batterie) : d'où la protection _requestingSessionNotificationPermissions
  // le temps de l'opération.
  Future<void> _requestSessionNotificationPermissions() async {
    setState(() => _requestingSessionNotificationPermissions = true);

    await _sessionNotificationService.requestPermissions();

    if (!mounted) return;
    setState(() => _requestingSessionNotificationPermissions = false);
    showSnack(
      context,
      "Vérifie les autorisations demandées, puis relance une séance.",
    );
  }

  // Logique de changement de thème réutilisée telle quelle depuis
  // l'écran d'accueil (même icône, même cycle Auto -> Clair -> Sombre).
  IconData get _themeIcon => switch (widget.themeMode) {
    ThemeMode.system => Icons.brightness_auto,
    ThemeMode.light => Icons.light_mode,
    ThemeMode.dark => Icons.dark_mode,
  };

  String get _themeLabel => switch (widget.themeMode) {
    ThemeMode.system => "Auto",
    ThemeMode.light => "Clair",
    ThemeMode.dark => "Sombre",
  };

  Future<void> _handleExport() async {
    setState(() => _busy = true);

    try {
      final filePath = await _exportService.exportToFile();

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: "Export des séances RepTimer",
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showSnack(context, "Erreur lors de l'export : $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    // Sélecteur annulé par l'utilisateur : rien à faire.
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
        "Import terminé : ${importResult.importedCount} séance(s) importée(s).",
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      showSnack(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, "Erreur lors de l'import : $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showAboutDialog() async {
    // PackageInfo lit le nom et la version réellement embarqués dans
    // l'app installée (voir la documentation associée à cette
    // fonctionnalité) : jamais de duplication figée en dur dans le code.
    final packageInfo = await PackageInfo.fromPlatform();

    if (!mounted) return;

    showAboutDialog(
      context: context,
      applicationName: packageInfo.appName,
      applicationVersion: "${packageInfo.version} (${packageInfo.buildNumber})",
      applicationIcon: SizedBox(
        width: 48,
        height: 48,
        child: Image.asset(_appIconAsset),
      ),
      applicationLegalese: _copyright,
      // Pas d'appel à showLicensePage : AboutDialog affiche déjà
      // nativement un bouton "Voir les licences" qui l'ouvre lui-même.
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paramètres")),
      body: ListView(
        children: [
          SettingsSection(
            title: "Affichage",
            children: [
              ListTile(
                title: Row(
                  children: [
                    const Text("Thème"),
                    const SizedBox(width: 8),
                    Text(
                      _themeLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(_themeIcon),
                  tooltip: "Thème : $_themeLabel (appuyer pour changer)",
                  onPressed: widget.onToggleTheme,
                ),
              ),
            ],
          ),

          // Ordre : Affichage, Édition, Notifications, Import / Export,
          // À propos (voir la section "Notifications" juste après pour
          // le réglage "Fin d'exercice").
          SettingsSection(
            title: "Édition",
            children: [
              ListTile(
                title: const Text("Préremplir le nom des nouveaux exercices"),
                trailing: Switch(
                  value: _prefillExerciseName,
                  onChanged: _togglePrefillExerciseName,
                ),
              ),
            ],
          ),

          SettingsSection(
            title: "Notifications",
            children: [
              ListTile(
                title: Row(
                  children: [
                    const Text("Fin d'exercice"),
                    const SizedBox(width: 8),
                    Text(
                      _notificationMode.label,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(iconForNotificationMode(_notificationMode)),
                  tooltip:
                      "Notifications : ${_notificationMode.label} (appuyer pour changer)",
                  onPressed: _cycleNotificationMode,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text("Activer les notifications de séance"),
                subtitle: const Text(
                  "Notification persistante affichant le chronomètre "
                  "pendant l'exécution d'une séance",
                ),
                enabled: !_requestingSessionNotificationPermissions,
                onTap: _requestSessionNotificationPermissions,
              ),
              if (_requestingSessionNotificationPermissions)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),

          SettingsSection(
            title: "Import / Export",
            children: [
              ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text("Importer"),
                subtitle: const Text("Ajouter des séances depuis un fichier"),
                enabled: !_busy,
                onTap: _handleImport,
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text("Exporter"),
                subtitle: const Text(
                  "Partager toutes vos séances dans un fichier",
                ),
                enabled: !_busy,
                onTap: _handleExport,
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),

          SettingsSection(
            title: "À propos",
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text("À propos"),
                onTap: _showAboutDialog,
              ),
            ],
          ),

          // Futures sections de paramètres : ajouter un autre
          // SettingsSection ici, sans modifier ce qui précède.
        ],
      ),
    );
  }
}
