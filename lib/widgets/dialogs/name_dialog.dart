import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/validation_messages.dart';
import '../../validation/business_validation.dart';

/// Demande un nom sans modifier la valeur existante tant que l'utilisateur
/// n'a pas validé le dialogue.
Future<String?> showNameDialog(
  BuildContext context, {
  required String initialName,
  required BusinessField field,
  required String title,
  required String label,
  required String hintText,
  String? initialErrorText,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NameDialog(
      initialName: initialName,
      field: field,
      title: title,
      label: label,
      hintText: hintText,
      initialErrorText: initialErrorText,
    ),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.initialName,
    required this.field,
    required this.title,
    required this.label,
    required this.hintText,
    this.initialErrorText,
  });

  final String initialName;
  final BusinessField field;
  final String title;
  final String label;
  final String hintText;
  final String? initialErrorText;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
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
      field: widget.field,
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
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
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
          labelText: widget.label,
          hintText: widget.hintText,
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
