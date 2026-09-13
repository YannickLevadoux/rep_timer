# RepTimer 1.5.1

RepTimer 1.5.1 est une version corrective et de maintenance. Elle améliore la
lisibilité des groupes et de l'Historique, ouvre la Progression au bon endroit
et met à jour la chaîne de développement sans ajouter de fonctionnalité.

## Correctifs visibles

- Dans l'éditeur, le résumé d'un groupe à répétitions variables se limite au
  nombre de tours. Une fois le groupe déplié, chaque exercice affiche la suite
  réellement exécutée, par exemple `10 → 12 → 15`, ou `Suite à définir` si elle
  est vide. Les pauses et les autres types de groupes conservent leur affichage.
- Les navigations hebdomadaire et mensuelle de l'Historique tiennent désormais
  sur une ligne. L'action accessible **Revenir à aujourd'hui** reste visible,
  les semaines utilisent des mois français abrégés et les graphiques des
  périodes courantes et passées disposent de la même hauteur.
- L'écran **Progression** défile à chaque ouverture jusqu'à l'étape courante,
  même dans une longue séance. La cible est placée autant que possible dans le
  tiers supérieur, sans annuler ensuite le défilement manuel.
- Un séparateur discret précède le premier groupe et chacun des groupes
  suivants dans la Progression. Il reste lisible avec un nom long, une petite
  largeur, du texte agrandi et dans les thèmes clair et sombre.

## Maintenance technique

- Flutter passe à `3.47.4`. La sélection de fichiers est adaptée à la nouvelle
  API de `file_picker`, avec des tests couvrant la sélection et l'annulation.
- La chaîne Android finale utilise Kotlin `2.4.20`, Android Gradle Plugin
  `9.4.0`, Gradle Wrapper `9.7.1` et Java `17` Temurin.
- `actions/setup-java` passe à `6.0.1` et
  `softprops/action-gh-release` à `3.0.3`. Les autres GitHub Actions restent
  épinglées aux versions documentées dans `docs/ci-cd.md`.
- Renovate recherche les mises à jour chaque semaine en heure
  `Europe/Paris`. Il regroupe les workflows et leur version de Flutter sous
  **CI dependencies**, puis les packages et la chaîne Android sous
  **Application dependencies**. Les versions majeures restent séparées des
  mises à jour mineures et correctives.
- Le preset `:enableVulnerabilityAlerts` permet aux correctifs de sécurité de
  ne pas attendre la planification hebdomadaire. Lors de la préparation de
  cette version, l'API GitHub indique toutefois que les alertes de
  vulnérabilité du dépôt sont désactivées et ne permet pas de confirmer le
  graphe de dépendances. Il reste donc nécessaire d'activer ce graphe et les
  alertes Dependabot dans les réglages GitHub avant de considérer ce parcours
  comme opérationnel.
- La version du package passe à `1.5.1+9`. Le dialogue **À propos** continue de
  lire la version et le build depuis les métadonnées du package.

## Qualité

- Les 677 tests automatisés passent avec Flutter `3.47.4`.
- La couverture globale atteint **96,73 %** (`7 270 / 7 516` lignes), au-dessus
  du seuil bloquant de 91,78 %.
- La couverture différentielle n'est pas calculable hors contexte de Pull
  Request. Elle reste bloquante à 90 % lorsqu'elle est disponible.
- Aucun fichier Dart suivi sous `lib/` n'atteint 200 lignes. Les deux plus
  grands, `lib/screens/home_screen.dart` et
  `lib/screens/training_summary.dart`, comptent chacun 199 lignes ;
  `lib/services/session_notification_coordinator.dart` en compte 198.
- Les 335 fichiers contrôlés sont correctement formatés, l'analyse statique ne
  remonte aucun diagnostic et l'APK debug est construit avec succès.
- `renovate.json` est validé sans avertissement ni migration par le validateur
  officiel Renovate `44.79.6` en mode strict.

## Validations manuelles Android restantes

- [ ] déplier un groupe à répétitions variables avec une suite courte puis
  longue, un nom d'exercice long et une petite largeur ;
- [ ] ouvrir la Progression au milieu d'une longue séance, vérifier le
  positionnement de l'étape courante puis la conservation du défilement manuel ;
- [ ] vérifier les séparateurs de Progression avant le premier groupe et chaque
  groupe suivant, avec plusieurs tours, un nom de groupe long, une petite
  largeur, du texte agrandi et les thèmes clair et sombre ;
- [ ] parcourir l'Historique en semaine et en mois, pour **Nombre de séances**
  et **Temps passé**, sur la période courante puis une période passée ;
- [ ] vérifier l'Historique sur petit écran, avec texte agrandi et dans les
  thèmes clair et sombre ;
- [ ] sélectionner, exporter, importer, sauvegarder et restaurer des fichiers
  après l'adaptation de `file_picker` ;
- [ ] vérifier le dialogue **À propos** avec la version `1.5.1`, le build `9`
  et le badge DEV présent uniquement sur les builds locaux ;
- [ ] après publication, vérifier sur l'APK officiel l'absence du badge DEV,
  l'installation, le démarrage et la lecture des données locales existantes.

**Changelog complet** :
https://github.com/YannickLevadoux/rep_timer/compare/v1.5.0...v1.5.1
