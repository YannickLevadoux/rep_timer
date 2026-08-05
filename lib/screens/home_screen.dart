import 'package:flutter/material.dart';

import '../controllers/home_controller.dart';
import '../models/training.dart';
import '../services/app_settings_storage.dart';
import '../services/pending_session_recovery_service.dart';
import '../utils/snack.dart';
import '../utils/validation_messages.dart';
import '../widgets/dialogs/duplicate_training_dialog.dart';
import '../widgets/home_screen_view.dart';
import 'quick_tabata_screen.dart';
import 'settings_screen.dart';
import 'training_editor.dart';
import 'training_history.dart';
import 'training_session.dart';
import 'training_summary.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    this.onThemeRestored,
    this.settingsStorage,
  });

  final ThemeMode themeMode;
  final Future<ThemeMode> Function() onToggleTheme;
  final ValueChanged<ThemeMode>? onThemeRestored;
  final AppSettingsStorage? settingsStorage;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;
  late final PendingSessionRecoveryService _recoveryService;

  @override
  void initState() {
    super.initState();
    _controller = HomeController()..loadTrainings();
    _recoveryService = PendingSessionRecoveryService();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _resumePendingSessionIfAny(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resumePendingSessionIfAny() async {
    final recovery = await _recoveryService.resolve();
    if (!mounted) return;

    if (recovery.storageWarning) _controller.reportStorageWarning();
    if (recovery.checkpointWarning) _controller.reportCheckpointWarning();
    if (recovery.validationIssue case final issue?) {
      showSnack(context, 'Reprise impossible : ${validationMessage(issue)}');
      return;
    }
    if (recovery.training == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingSessionScreen(
          training: recovery.training!,
          initialCheckpoint: recovery.checkpoint!,
        ),
      ),
    );
    if (mounted) _controller.loadTrainings();
  }

  Future<void> _openEditor({Training? training}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingEditor(training: training),
      ),
    );
    if (saved == true) _controller.loadTrainings();
  }

  void _startTraining(Training training) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingSummaryScreen(training: training),
      ),
    );
  }

  Future<void> _duplicateTraining(Training training) async {
    final name = await showDuplicateTrainingDialog(
      context,
      originalName: training.name,
    );
    if (name == null || !mounted) return;

    final errorMessage = await _controller.duplicateTraining(training, name);
    if (mounted && errorMessage != null) showSnack(context, errorMessage);
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          themeMode: widget.themeMode,
          onToggleTheme: widget.onToggleTheme,
          onThemeRestored: widget.onThemeRestored,
          settingsStorage: widget.settingsStorage,
        ),
      ),
    );
    if (mounted) _controller.loadTrainings();
  }

  void _openDestination(int index) {
    final Widget? destination = switch (index) {
      1 => const QuickTabataScreen(),
      2 => const TrainingHistoryScreen(),
      _ => null,
    };
    if (destination != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => HomeScreenView(
        trainings: _controller.trainings,
        expandedTrainingId: _controller.expandedTrainingId,
        loading: _controller.loading,
        storageWarning: _controller.storageWarning,
        storageFailure: _controller.storageFailure,
        checkpointWarning: _controller.checkpointWarning,
        onOpenSettings: _openSettings,
        onRetry: _controller.loadTrainings,
        onToggleExpanded: _controller.toggleExpanded,
        onDuplicate: _duplicateTraining,
        onEdit: (training) => _openEditor(training: training),
        onStart: _startTraining,
        onDestinationSelected: _openDestination,
        onCreate: _openEditor,
      ),
    );
  }
}
