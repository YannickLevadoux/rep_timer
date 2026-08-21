import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/validation_messages.dart';
import '../../validation/business_validation.dart';

/// Demande un nouveau nom de séance sans modifier la valeur existante tant
/// que l'utilisateur n'a pas validé le dialogue.
Future<String?> showTrainingNameDialog(
  BuildContext context, {
  required String initialName,
  String? initialErrorText,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TrainingNameDialog(
      initialName: initialName,
      initialErrorText: initialErrorText,
    ),
  );
}

class _TrainingNameDialog extends StatefulWidget {
  const _TrainingNameDialog({required this.initialName, this.initialErrorText});

  final String initialName;
  final String? initialErrorText;

  @override
  State<_TrainingNameDialog> createState() => _TrainingNameDialogState();
}

class _TrainingNameDialogState extends State<_TrainingNameDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _errorText = widget.initialErrorText;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final issue = BusinessValidation.validateName(
      _controller.text,
      field: BusinessField.trainingName,
    );
    if (issue != null) {
      setState(() => _errorText = validationMessage(issue));
      return;
    }
    Navigator.pop(context, BusinessValidation.normalizeName(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text("Nom de la séance"),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: BusinessLimits.maximumNameCharacters,
        maxLengthEnforcement: MaxLengthEnforcement.none,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _confirm(),
        onChanged: (_) {
          if (_errorText != null) {
            setState(() => _errorText = null);
          }
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: "Nom de la séance",
          hintText: "Ex : Full Body",
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        FilledButton(onPressed: _confirm, child: const Text("Valider")),
      ],
    );
  }
}
