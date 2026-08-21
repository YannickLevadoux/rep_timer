import 'package:flutter/foundation.dart';

import '../models/training.dart';

/// Conserve la sélection d'export dans l'ordre affiché, hors persistance.
class TrainingExportSelectionController extends ChangeNotifier {
  TrainingExportSelectionController(List<Training> trainings)
    : trainings = List.unmodifiable(trainings),
      _selected = List.filled(trainings.length, true);

  final List<Training> trainings;
  final List<bool> _selected;

  bool isSelected(int index) => _selected[index];
  bool get hasSelection => _selected.any((selected) => selected);
  bool get allSelected =>
      _selected.isNotEmpty && _selected.every((value) => value);
  List<Training> get selectedTrainings => [
    for (var index = 0; index < trainings.length; index++)
      if (_selected[index]) trainings[index],
  ];

  void setSelected(int index, bool selected) {
    if (_selected[index] == selected) return;
    _selected[index] = selected;
    notifyListeners();
  }

  void selectAll() => _setAll(true);
  void clearAll() => _setAll(false);

  void _setAll(bool selected) {
    if (_selected.every((value) => value == selected)) return;
    _selected.fillRange(0, _selected.length, selected);
    notifyListeners();
  }
}
