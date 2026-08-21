import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/validation_messages.dart';
import '../../validation/business_validation.dart';
import 'app_form_dialog.dart';

/// Dialogue de duplication d'une séance : demande le nom de la copie,
/// /// prérempli avec `<nom d'origine> - Copie`.
/// L'utilisateur peut le modifier librement.
///
/// Retourne le nom saisi (trim), ou `null` si annulé (bouton ou fermeture
/// du dialogue) : dans ce cas, aucune duplication ne doit être effectuée.
/// Un nom vide bloque simplement la validation (même comportement que
/// showRestDialog pour un champ invalide), sans message d'erreur
/// supplémentaire.
Future<String?> showDuplicateTrainingDialog(
  BuildContext context, {
  required String originalName,
}) async {
  final controller = TextEditingController(
    text: BusinessValidation.copyNameProposal(originalName),
  );
  String? errorText;
  late StateSetter updateDialog;

  final result = await showAppFormDialog<String>(
    context,
    title: "Dupliquer la séance",
    contentBuilder: (context, setDialogState) {
      updateDialog = setDialogState;
      return TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        maxLength: BusinessLimits.maximumNameCharacters,
        maxLengthEnforcement: MaxLengthEnforcement.none,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: "Nom de la nouvelle séance",
          errorText: errorText,
        ),
      );
    },
    confirmLabel: "Copier",
    onConfirm: () {
      final issue = BusinessValidation.validateName(
        controller.text,
        field: BusinessField.copyName,
      );
      if (issue != null) {
        updateDialog(() => errorText = validationMessage(issue));
        return null;
      }
      return BusinessValidation.normalizeName(controller.text);
    },
  );
  return result;
}
