# Contrat de sauvegarde RepTimer v3

Tout nouvel export RepTimer utilise exclusivement le format v3 :

```json
{
  "app": "RepTimer",
  "exportFormatVersion": 3,
  "exportedAt": "<ISO8601>",
  "data": {
    "trainings": [],
    "history": [],
    "preferences": {
      "themeMode": "system|light|dark",
      "prefillExerciseName": true,
      "notificationMode": "sound|vibration|none",
      "preSessionCountdownSeconds": 0
    }
  }
}
```

`preSessionCountdownSeconds` est un entier obligatoire compris entre 0 et 15.
La valeur 0 désactive la préparation. Une valeur absente, d'un autre type ou
hors bornes invalide une sauvegarde v3 entière avant toute mutation.

## Groupes enregistrés

Les groupes conservent la représentation canonique de
`ExerciseGroup.toJson()` :

- `type` accepte `free`, `variableRepetitions`, `tabata`, `amrap` et `emom` ;
- `rounds`, `repetitionSequence` et `items` restent toujours présents ;
- `finalRestDurationSeconds` contient la dernière pause Tabata optionnelle ;
- `postGroupRestDurationSeconds` contient la récupération optionnelle AMRAP ou
  EMOM.

Une durée optionnelle est soit `null`, soit un nombre entier de secondes dans
les bornes usuelles. Les champs de transition non compatibles avec le type du
groupe sont refusés.

Les structures suivantes sont obligatoires :

| Type | Structure |
| --- | --- |
| Tabata | 1 à 999 cycles, puis exactement Effort chronométré et Pause chronométrée. |
| AMRAP | Un seul Effort chronométré de 60 à 3 600 secondes. |
| EMOM | 1 à 60 minutes et un seul Effort chronométré de 60 secondes. |

Les tours AMRAP sont des données d'exécution : ils ne figurent jamais dans la
définition d'un entraînement.

## Historique AMRAP et EMOM

Une étape d'historique reste lisible lorsque les nouveaux champs sont absents.
Lorsqu'ils sont présents :

- `emomMinuteIndex` est un index positif, basé sur 1 ;
- `amrap` contient `configuredDurationSeconds`, `activeDurationSeconds`,
  `completedLapDurationsSeconds`, `partialLapDurationSeconds` et `completed`.

Les tours terminés sont strictement positifs, ordonnés et limités à 999. Le
tour partiel est soit absent, soit strictement positif. La somme des tours et
du partiel doit être égale au temps actif, hors pauses globales, et le statut
AMRAP doit correspondre au statut de l'étape.

Le checkpoint courant reste exclu de la sauvegarde complète. Son stockage
local peut toutefois contenir `amrapState` afin de reprendre exactement la
durée configurée, le temps actif écoulé et restant, les tours terminés, le tour
courant, le délai actif du bouton et le statut.

## Compatibilité et restauration

- les exports v1 restent importés par le chemin additif historique ;
- les sauvegardes v2 restent restaurables et utilisent 0 seconde pour la
  préférence absente ;
- les données locales 1.3.2 restent décodées sans migration destructive ;
- toute version supérieure à 3 est refusée avant confirmation ;
- tout payload incomplet ou incohérent est refusé sans mutation.

La restauration v2 ou v3 remplace transactionnellement les séances,
l'historique et les préférences exportables, puis supprime le checkpoint. Les
valeurs brutes précédentes sont restaurées si une écriture échoue.
