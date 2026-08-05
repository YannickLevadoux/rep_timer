# Contrat de sauvegarde RepTimer v2

Tout nouvel export utilise exclusivement l'enveloppe suivante :

```json
{
  "app": "RepTimer",
  "exportFormatVersion": 2,
  "exportedAt": "<ISO8601>",
  "data": {
    "trainings": [],
    "history": [],
    "preferences": {
      "themeMode": "system|light|dark",
      "prefillExerciseName": true,
      "notificationMode": "sound|vibration|none"
    }
  }
}
```

## Séances et groupes

Une séance utilise la représentation canonique de `Training.toJson()`. Les
groupes utilisent celle de `ExerciseGroup.toJson()` et conservent notamment :

- `type`, avec les valeurs stables `free` ou `variableRepetitions` ;
- `rounds`, y compris lorsqu'il s'agit de la valeur dormante d'un groupe à
  répétitions variables ;
- `repetitionSequence`, dans son ordre d'édition, y compris lorsqu'elle est
  dormante sur un groupe libre ;
- `items`, dont chaque champ `repetitions` individuel reste présent même si la
  suite du groupe fournit les répétitions exécutées tour par tour.

La sauvegarde contient les agrégats éditables, jamais une liste d'étapes
développées. Elle permet ainsi une restauration sans perte et un aller-retour
ultérieur entre les deux types de groupe.

## Exclusions

Le checkpoint d'une séance en cours, les permissions, l'exemption batterie et
les drapeaux internes d'interface ne font pas partie de `data`. Une lecture
partielle, illisible ou une séance invalide bloque la création du fichier.
