import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/group_editor_mode.dart';
import '../models/training.dart';
import '../services/app_settings_storage.dart';
import '../services/session_controller.dart';
import '../services/session_notification_permission_service.dart';
import '../services/session_start_permission_gate.dart';
import 'group_editor.dart';
import 'training_session.dart';

class QuickSessionScreen extends StatefulWidget {
  const QuickSessionScreen({
    super.key,
    this.permissionService,
    this.settingsStorage,
    this.controllerFactory,
  });

  final SessionNotificationPermissionService? permissionService;
  final SessionPermissionPromptStorage? settingsStorage;
  @visibleForTesting
  final SessionControllerFactory? controllerFactory;

  @override
  State<QuickSessionScreen> createState() => _QuickSessionScreenState();
}

class _QuickSessionScreenState extends State<QuickSessionScreen> {
  late final ExerciseGroup _initialGroup;

  @override
  void initState() {
    super.initState();
    _initialGroup = ExerciseGroup.tabata(
      id: 'quick_group_${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  Future<void> _start(ExerciseGroup group) async {
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
    ).prepare(context, training);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingSessionScreen(
          training: training,
          trainingChangesPersistence: TrainingChangesPersistence.memoryOnly,
          controllerFactory: widget.controllerFactory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GroupEditor(
    group: _initialGroup,
    mode: GroupEditorMode.quick,
    onSubmit: _start,
  );
}
