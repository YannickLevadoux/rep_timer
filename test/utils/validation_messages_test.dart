import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/utils/validation_messages.dart';
import 'package:rep_timer/validation/business_validation.dart';

void main() {
  test('traduit tous les codes de validation métier', () {
    for (final code in BusinessValidationCode.values) {
      final message = validationMessage(
        BusinessValidationIssue(
          field: BusinessField.exerciseName,
          code: code,
          minimum: 1,
          maximum: 10,
        ),
      );

      expect(message, isNotEmpty);
    }
  });

  test('personnalise la suite de répétitions obligatoire', () {
    expect(
      validationMessage(
        const BusinessValidationIssue(
          field: BusinessField.groupRepetitionSequence,
          code: BusinessValidationCode.required,
        ),
      ),
      'Ajoute au moins un tour à la suite de répétitions.',
    );
  });
}
