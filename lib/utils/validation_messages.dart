import '../validation/business_validation.dart';

String validationMessage(BusinessValidationIssue issue) {
  if (issue.field == BusinessField.groupRepetitionSequence &&
      issue.code == BusinessValidationCode.required) {
    return 'Ajoute au moins un tour à la suite de répétitions.';
  }
  return switch (issue.code) {
    BusinessValidationCode.required => 'Ce champ est obligatoire.',
    BusinessValidationCode.notANumber => 'Saisis un nombre entier.',
    BusinessValidationCode.belowMinimum =>
      'La valeur minimale est ${issue.minimum}.',
    BusinessValidationCode.aboveMaximum =>
      'La valeur maximale est ${issue.maximum}.',
    BusinessValidationCode.multipleLines =>
      'Le nom doit tenir sur une seule ligne.',
    BusinessValidationCode.tooLong => 'Maximum ${issue.maximum} caractères.',
    BusinessValidationCode.tooManyLines => 'Maximum ${issue.maximum} lignes.',
    BusinessValidationCode.tooManySteps =>
      'Cette séance dépasse ${issue.maximum} étapes.',
    BusinessValidationCode.invalidExerciseMode =>
      "Choisis un seul mode valide pour l'exercice.",
    BusinessValidationCode.invalidGroupStructure =>
      'La structure de ce groupe ne correspond pas à son type.',
  };
}
