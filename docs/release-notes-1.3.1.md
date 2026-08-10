# RepTimer 1.3.1

Cette version de maintenance met à jour l'outillage, clarifie les
responsabilités internes et renforce les tests. Elle n'apporte aucun changement
fonctionnel ou visuel.

## Outillage

- Flutter passe de `3.44.8` à `3.44.9` dans les workflows de validation, de
  build debug et de publication.
- Le wrapper Gradle passe de `9.6.1` à `9.7.0`.
- La configuration Renovate ignore désormais le plugin loader fourni par le SDK
  Flutter, ce qui supprime les avertissements non pertinents du Dependency
  Dashboard.

## Architecture interne

- Tous les fichiers Dart de production suivis sous `lib/` restent sous la
  limite de 200 lignes physiques.
- Le stockage JSON sépare les résultats de lecture, les listes et les objets,
  en conservant les formats et les protections contre la perte de données.
- La gestion des permissions sépare l'état et les actions de leur présentation.
- La reprise des checkpoints et l'affichage de la progression disposent de
  responsabilités dédiées et directement testables.
- Le compte à rebours, les données de notification et le pont avec la séance
  sont isolés du coordinateur de notifications.
- La composition du contrôleur de séance, les commentaires et la présentation
  de l'écran d'exécution sont séparés de l'orchestration Flutter.

## Tests

- La suite passe de 297 à 361 tests.
- La couverture de lignes mesurée par `flutter test --coverage` atteint
  **90,38 %** (`4 746 / 5 251`), contre 84,3 % pour la version 1.3.0.
- Les parcours de progression, d'exécution, de sortie et de reprise des
  checkpoints, ainsi que les composants extraits, disposent de tests dédiés.

**Changelog complet** :
https://github.com/YannickLevadoux/rep_timer/compare/v1.3.0...v1.3.1
