import 'package:flutter/material.dart';

import '../controllers/pre_session_preparation_controller.dart';
import '../models/exercise_group.dart';
import '../models/group_editor_mode.dart';
import '../models/training.dart';
import '../services/app_settings_storage.dart';
import '../services/session_controller.dart';
import '../services/session_notification_permission_service.dart';
import '../services/session_start_permission_gate.dart';
import 'group_editor.dart';
import 'pre_session_preparation_flow.dart';
import 'training_session.dart';

class QuickSessionScreen extends StatefulWidget {
  const QuickSessionScreen({
    super.key,
    this.permissionService,
    this.settingsStorage,
    this.countdownStorage,
    this.controllerFactory,
  });

  final SessionNotificationPermissionService? permissionService;
  final SessionPermissionPromptStorage? settingsStorage;
  final AppSettingsStorage? countdownStorage;
  @visibleForTesting
  final SessionControllerFactory? controllerFactory;

  @override
  State<QuickSessionScreen> createState() => _QuickSessionScreenState();
}

class _QuickSessionScreenState extends State<QuickSessionScreen> {
  late final ExerciseGroup _initialGroup;
  late final PreSessionPreparationController _preparation;

  @override
  void initState() {
    super.initState();
    _initialGroup = ExerciseGroup(
      id: 'quick_group_${DateTime.now().microsecondsSinceEpoch}',
      name: '',
      items: [],
    );
    _preparation =
        PreSessionPreparationController(
            countdownStorage: widget.countdownStorage,
            permissionStorage: widget.settingsStorage,
          )
          ..addListener(_preparationChanged)
          ..load();
  }

  @override
  void dispose() {
    _preparation
      ..removeListener(_preparationChanged)
      ..dispose();
    super.dispose();
  }

  void _preparationChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _start(ExerciseGroup group) async {
    await _preparation.load();
    if (!mounted) return;
    final timestamp = DateTime.now();
    final training = Training(
      id: 'quick_${timestamp.microsecondsSinceEpoch}',
      name: group.name,
      groups: [group.copyWith()],
      createdAt: timestamp,
    );
    await SessionStartPermissionGate(
      permissionService: widget.permissionService,
      settingsStorage: widget.settingsStorage,
      countdownStorage: _preparation.settingsStorage,
    ).prepare(context, training);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingSessionScreen(
          training: training,
          trainingChangesPersistence: TrainingChangesPersistence.memoryOnly,
          controllerFactory: widget.controllerFactory,
          preSessionCountdownSeconds: _preparation.effectiveSeconds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GroupEditor(
    group: _initialGroup,
    mode: GroupEditorMode.quick,
    onSubmit: _start,
    preSessionPreparationSeconds: _preparation.seconds,
    preSessionPreparationEnabled: _preparation.enabled,
    onPreSessionPreparationChanged: _preparation.loaded
        ? preSessionPreparationHandler(context, _preparation)
        : null,
  );
}
