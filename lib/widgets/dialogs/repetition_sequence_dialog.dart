import 'package:flutter/material.dart';

import '../../utils/validation_messages.dart';
import '../../validation/business_validation.dart';

Future<List<int>?> showRepetitionSequenceDialog(
  BuildContext context, {
  required List<int> initialValues,
  required int fallbackValue,
}) => showDialog<List<int>>(
  context: context,
  builder: (context) => _RepetitionSequenceDialog(
    initialValues: initialValues,
    fallbackValue: fallbackValue,
  ),
);

class _SequenceEntry {
  _SequenceEntry(int value)
    : key = UniqueKey(),
      controller = TextEditingController(text: value.toString());

  final Key key;
  final TextEditingController controller;
  String? error;

  void dispose() => controller.dispose();
}

class _RepetitionSequenceDialog extends StatefulWidget {
  const _RepetitionSequenceDialog({
    required this.initialValues,
    required this.fallbackValue,
  });

  final List<int> initialValues;
  final int fallbackValue;

  @override
  State<_RepetitionSequenceDialog> createState() =>
      _RepetitionSequenceDialogState();
}

class _RepetitionSequenceDialogState extends State<_RepetitionSequenceDialog> {
  late final List<_SequenceEntry> _entries;
  String? _sequenceError;

  @override
  void initState() {
    super.initState();
    _entries = widget.initialValues.map(_SequenceEntry.new).toList();
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _add() {
    final value = _entries.isEmpty
        ? widget.fallbackValue
        : int.tryParse(_entries.last.controller.text.trim()) ??
              widget.fallbackValue;
    setState(() {
      _entries.add(_SequenceEntry(value));
      _sequenceError = null;
    });
  }

  void _remove(int index) {
    if (_entries.length <= 1) return;
    setState(() => _entries.removeAt(index).dispose());
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final entry = _entries.removeAt(oldIndex);
      _entries.insert(newIndex, entry);
    });
  }

  void _confirm() {
    if (_entries.isEmpty) {
      setState(() => _sequenceError = 'Ajoute au moins un tour.');
      return;
    }

    final values = <int>[];
    var valid = true;
    for (final entry in _entries) {
      final issue = BusinessValidation.validateCountText(
        entry.controller.text,
        field: BusinessField.groupRepetitionValue,
      );
      entry.error = issue == null ? null : validationMessage(issue);
      if (issue == null) {
        values.add(int.parse(entry.controller.text.trim()));
      } else {
        valid = false;
      }
    }
    setState(() => _sequenceError = null);
    if (valid) Navigator.pop(context, values);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      title: const Text('Suite de répétitions'),
      content: SizedBox(
        width: 420,
        height: (MediaQuery.sizeOf(context).height * 0.58)
            .clamp(240.0, 420.0)
            .toDouble(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _entries.isEmpty
                  ? const Center(child: Text('Aucun tour défini'))
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: _entries.length,
                      onReorderItem: _reorder,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return Padding(
                          key: entry.key,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 48,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Tour\n${index + 1}',
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextField(
                                  controller: entry.controller,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelText: 'Répétitions',
                                    errorText: entry.error,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Supprimer le tour',
                                constraints: const BoxConstraints.tightFor(
                                  width: 40,
                                  height: 48,
                                ),
                                onPressed: _entries.length > 1
                                    ? () => _remove(index)
                                    : null,
                                icon: const Icon(Icons.delete_outline),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Tooltip(
                                  message: 'Réordonner',
                                  child: SizedBox.square(
                                    dimension: 40,
                                    child: Icon(Icons.drag_handle),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (_sequenceError != null)
              Text(
                _sequenceError!,
                key: const Key('repetition-sequence-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('add-sequence-round'),
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un tour'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('Valider')),
      ],
    );
  }
}
