import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/validation/business_validation.dart';

void main() {
  group('comptages', () {
    test('accepte 1 et 999, refuse 0 et 1000', () {
      for (final value in [1, 999]) {
        expect(
          BusinessValidation.validateCount(
            value,
            field: BusinessField.repetitions,
          ),
          isNull,
        );
      }
      expect(
        BusinessValidation.validateCount(
          0,
          field: BusinessField.repetitions,
        )?.code,
        BusinessValidationCode.belowMinimum,
      );
      expect(
        BusinessValidation.validateCount(
          1000,
          field: BusinessField.groupRounds,
        )?.code,
        BusinessValidationCode.aboveMaximum,
      );
    });

    test('distingue vide et non numérique', () {
      expect(
        BusinessValidation.validateCountText(
          '',
          field: BusinessField.repetitions,
        )?.code,
        BusinessValidationCode.required,
      );
      expect(
        BusinessValidation.validateCountText(
          'abc',
          field: BusinessField.repetitions,
        )?.code,
        BusinessValidationCode.notANumber,
      );
    });
  });

  test('valide exactement les bornes de durée', () {
    expect(
      BusinessValidation.validateDuration(Duration.zero)?.code,
      BusinessValidationCode.belowMinimum,
    );
    expect(
      BusinessValidation.validateDuration(const Duration(seconds: 1)),
      isNull,
    );
    expect(
      BusinessValidation.validateDuration(BusinessLimits.maximumDuration),
      isNull,
    );
    expect(
      BusinessValidation.validateDuration(
        BusinessLimits.maximumDuration + const Duration(seconds: 1),
      )?.code,
      BusinessValidationCode.aboveMaximum,
    );
  });

  group('noms', () {
    test('normalise, exige une valeur et une seule ligne', () {
      expect(BusinessValidation.normalizeName('  Nom  '), 'Nom');
      expect(
        BusinessValidation.validateName(
          '   ',
          field: BusinessField.trainingName,
        )?.code,
        BusinessValidationCode.required,
      );
      expect(
        BusinessValidation.validateName(
          'une\r\ndeux',
          field: BusinessField.trainingName,
        )?.code,
        BusinessValidationCode.multipleLines,
      );
    });

    test('compte les graphèmes Unicode comme Flutter', () {
      const emoji = '👨‍👩‍👧‍👦';
      expect(BusinessValidation.visibleLength(emoji), 1);
      expect(
        BusinessValidation.validateName(
          emoji * 50,
          field: BusinessField.exerciseName,
        ),
        isNull,
      );
      expect(
        BusinessValidation.validateName(
          emoji * 51,
          field: BusinessField.exerciseName,
        )?.code,
        BusinessValidationCode.tooLong,
      );
    });

    test(
      'le nom proposé pour une copie reste valide et conserve le suffixe',
      () {
        final proposal = BusinessValidation.copyNameProposal(
          '${'👨‍👩‍👧‍👦' * 60}\ndeuxième ligne',
        );
        expect(proposal, endsWith(' - Copie'));
        expect(BusinessValidation.visibleLength(proposal), 50);
        expect(
          BusinessValidation.validateName(
            proposal,
            field: BusinessField.copyName,
          ),
          isNull,
        );
      },
    );
  });

  group('commentaires', () {
    test('normalise les fins de ligne, trim et chaîne vide', () {
      expect(
        BusinessValidation.normalizeComment('  un\r\ndeux\r  '),
        'un\ndeux',
      );
      expect(BusinessValidation.normalizeComment(' \n '), isNull);
    });

    test('accepte 200 caractères et 3 lignes', () {
      expect(BusinessValidation.validateComment('a' * 200), isNull);
      expect(BusinessValidation.validateComment('a\nb\nc'), isNull);
    });

    test('refuse 201 caractères et 4 lignes', () {
      expect(
        BusinessValidation.validateComment('a' * 201)?.code,
        BusinessValidationCode.tooLong,
      );
      expect(
        BusinessValidation.validateComment('a\nb\nc\nd')?.code,
        BusinessValidationCode.tooManyLines,
      );
    });
  });

  test('contrôle 10 000/10 001 étapes sans construire la liste', () {
    final accepted = _training(items: 20, rounds: 500);
    final refused = _training(items: 11, rounds: 910);

    expect(BusinessValidation.sessionStepUpperBound(accepted), 10000);
    expect(BusinessValidation.validateSessionStepLimit(accepted), isNull);
    expect(
      BusinessValidation.sessionStepUpperBound(refused),
      BusinessLimits.maximumSessionSteps + 1,
    );
    expect(
      BusinessValidation.validateSessionStepLimit(refused)?.code,
      BusinessValidationCode.tooManySteps,
    );
    expect(
      () => buildSessionSteps(refused),
      throwsA(isA<BusinessValidationException>()),
    );
  });
}

Training _training({required int items, required int rounds}) => Training(
  id: 'training',
  name: 'Séance',
  createdAt: DateTime(2026),
  groups: [
    ExerciseGroup(
      id: 'group',
      name: 'Groupe',
      rounds: rounds,
      items: List.generate(
        items,
        (_) => TrainingItem(
          type: ItemType.exercise,
          name: 'Exercice',
          repetitions: 1,
        ),
      ),
    ),
  ],
);
