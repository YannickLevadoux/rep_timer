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

/// Point d'entrée historique conservé pour la Session rapide généralisée.
class QuickTabataScreen extends StatefulWidget {
  const QuickTabataScreen({
    super.key,
    this.permissionService,
    this.settingsStorage,
  });

  final SessionNotificationPermissionService? permissionService;
  final SessionPermissionPromptStorage? settingsStorage;

  @override
  State<QuickTabataScreen> createState() => _QuickTabataScreenState();
}

class _QuickTabataScreenState extends State<QuickTabataScreen> {
  late final ExerciseGroup _initialGroup;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _initialGroup = ExerciseGroup(
      id: 'quick_${DateTime.now().microsecondsSinceEpoch}',
      name: '',
      items: [],
    );
  }

  Future<void> _start(ExerciseGroup group) async {
    if (_starting) return;
    _starting = true;
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
    _starting = false;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingSessionScreen(
          training: training,
          trainingChangesPersistence: TrainingChangesPersistence.memoryOnly,
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
