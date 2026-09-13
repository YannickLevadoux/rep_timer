# Contrat de sauvegarde RepTimer v4

Tout nouvel export complet RepTimer utilise le format v4. L'enveloppe, les
préférences et l'historique conservent le contrat v3 ; la version évolue pour
porter la nouvelle représentation Tabata.

```json
{
  "app": "RepTimer",
  "exportFormatVersion": 4,
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

## Groupes Tabata

Un groupe Tabata v4 remplace les anciens champs `rounds`, `items` et
`finalRestDurationSeconds` par une configuration dédiée :

```json
{
  "id": "<identifiant>",
  "name": "Tabata",
  "type": "tabata",
  "repetitionSequence": [],
  "postGroupRestDurationSeconds": null,
  "tabata": {
    "rounds": 2,
    "exercises": [
      {
        "type": "exercise",
        "name": "Squat",
        "repetitions": null,
        "durationSeconds": 20,
        "isFreeDuration": false,
        "comment": null,
        "iconName": "fitness_center"
      }
    ],
    "restDurationSeconds": 10,
    "finalRestDurationSeconds": 30
  }
}
```

- `rounds` contient 1 à 99 tours ;
- `exercises` contient la liste ordonnée de 1 à 999 exercices chronométrés ;
- les exercices ont tous la même durée, comprise entre 1 seconde et
  2 h 00 min 59 s ;
- `restDurationSeconds` est la pause commune entre cycles, dans les mêmes
  bornes ;
- `finalRestDurationSeconds` est facultatif avec un tour et obligatoire à
  partir de deux tours ;
- `postGroupRestDurationSeconds` reste `null` pour un Tabata.

Les quatre autres types de groupe conservent exactement leur représentation
v3. La sauvegarde contient toujours les agrégats éditables et jamais les
`SessionStep` développées.

## Compatibilité et restauration

RepTimer restaure les sauvegardes v2, v3 et v4. Un Tabata v3 de `N` cycles est
lu comme un tour contenant `N` clones de l'ancien exercice. Son nom, son icône,
son commentaire, sa durée d'effort, sa pause normale et sa dernière pause
personnalisée sont conservés. Cette conversion en mémoire ne réécrit pas le
stockage source.

Chaque sauvegarde est validée intégralement selon le contrat de sa propre
version avant confirmation et avant toute mutation. Les versions futures et
les schémas v4 incomplets ou incohérents sont refusés. La restauration reste
transactionnelle, restaure les valeurs brutes précédentes en cas d'échec et
supprime le checkpoint uniquement après les écritures prévues.
