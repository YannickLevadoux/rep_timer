# RepTimer

[![CI](https://github.com/YannickLevadoux/rep_timer/actions/workflows/ci.yml/badge.svg)](https://github.com/YannickLevadoux/rep_timer/actions/workflows/ci.yml)
[![Release](https://github.com/YannickLevadoux/rep_timer/actions/workflows/release.yml/badge.svg)](https://github.com/YannickLevadoux/rep_timer/actions/workflows/release.yml)

Application mobile (Android) de suivi et d'exécution de séances d'entraînement, développée avec Flutter.

Pas de version iOS prévue.

RepTimer permet de créer ses propres séances (échauffement, circuits, séries...), de les organiser en groupes d'exercices répétables, puis de les exécuter avec un système de minuteur, de progression et d'historique.

## Fonctionnalités

### Création et édition des séances
- Séances composées de **groupes d'exercices** libres ou à répétitions variables :
  - un groupe libre répète tous ses éléments pendant un nombre de tours défini ;
  - un groupe à répétitions variables applique une suite ordonnée (par exemple `10, 12, 15, 12, 10`) aux exercices en mode Répétitions, sans modifier les exercices chronométrés, les durées libres ni les pauses ;
  - le passage d'un type de groupe à l'autre conserve les tours, la suite et les répétitions individuelles afin d'éviter toute perte de configuration.
- Trois types d'exercices :
  - **Répétitions** — un nombre de répétitions à effectuer.
  - **Temps** — une durée définie (saisie via un sélecteur Minutes/Secondes).
  - **Durée libre** — aucun temps ni répétitions fixés à l'avance ; l'utilisateur décide lui-même de la fin de l'exercice, un chronomètre mesure le temps réellement passé.
- Pauses chronométrées entre les exercices.
- Réorganisation des groupes et des exercices par glisser-déposer depuis une poignée dédiée.
- Groupes initialement repliés dans l'éditeur de séance, avec aperçu dépliable de leur contenu et écran dédié à l'édition de leurs paramètres, exercices et pauses.
- Option permettant de désactiver le préremplissage du nom des nouveaux exercices avec le nom du groupe.
- Duplication d'une séance depuis l'écran d'accueil, avec choix du nom de la copie ; la nouvelle séance reste indépendante de l'originale.
- Icône personnalisable par exercice, parmi une liste prédéfinie.
- Commentaire libre et optionnel par exercice (poids, intensité...), modifiable aussi bien à l'édition que pendant l'exécution de la séance.
- Détection des modifications non enregistrées à la fermeture de l'écran d'édition (proposition d'enregistrer, d'abandonner ou d'annuler).
- Validation explicite des saisies : noms et commentaires limités, tours et répétitions compris entre `1` et `999`, durées programmées comprises entre `1 s` et `2 h 00 min 59 s`, et séances limitées à `10 000` étapes développées. Une valeur invalide n'est jamais corrigée ou tronquée silencieusement.

### Exécution d'une séance
- Écran de résumé avant le lancement : nom de la séance, compteurs de groupes, d'exercices et de pauses, puis aperçu des groupes, de leurs répétitions et de leurs exercices.
- Empêche la mise en veille de l'écran pendant toute la durée de la séance.
- Chronomètre global de la séance, indépendant du minuteur de chaque exercice.
- Écran organisé autour des commandes de séance, de la progression, du prochain élément et de l'exercice ou de la pause en cours.
- Navigation manuelle entre les exercices (précédent/suivant), en plus de la progression automatique.
- Mise en évidence visuelle (clignotement) de l'exercice en cours.
- Pause/reprise de la séance à tout moment.
- Écran de progression détaillée, avec possibilité de sauter directement à un exercice donné (avec confirmation).
- Fin de séance anticipée ou normale, toutes deux enregistrées dans l'historique : le statut (`Terminée` / `Incomplète`) est toujours déterminé à partir de la progression réelle (mêmes coches que l'écran de progression détaillée), quel que soit le mode de fin de séance.
- Si l'ordre d'exécution est modifié manuellement (exercices/pauses sautés, groupes réalisés dans un autre ordre) et que le dernier exercice du dernier groupe est terminé alors que des éléments restent non réalisés, la séance ne se termine pas automatiquement : elle se met en pause et propose de **reprendre à un exercice de son choix** (via l'écran de progression) ou de **terminer la séance** (enregistrée avec le statut `Incomplète`).
- Si une pause est définie à la fin de la séance (dernière pause du dernier groupe), cette pause sera ignorée.
- Alerte de fin des exercices et pauses chronométrés, configurable sur **Son**, **Vibration** ou **Rien** depuis les paramètres et ajustable pendant la séance.
- Notification Android persistante pendant qu'un chronomètre est actif (pause, exercice Temps ou Durée libre — jamais pour un exercice Répétitions) : icône Play/Pause dans la barre d'état, nom de l'exercice/de la pause et temps restant (ou écoulé en Durée libre), prochain élément de la séance et bouton **Pause** / **Reprendre**. Un appui sur la notification rouvre la séance. Repose sur un vrai Foreground Service Android (et non une simple notification), afin que la mise à jour du chronomètre ainsi que le son/la vibration de fin d'exercice restent fiables même lorsque l'application est en arrière-plan. Disparaît automatiquement à la fin, à l'abandon, ou à l'arrêt de la séance.
- Exécution tour par tour des groupes à répétitions variables, avec la valeur résolue affichée et conservée dans l'historique. La reprise d'une séance interrompue restaure le bon tour et la bonne répétition.

### Quick Tabata
- Lancement rapide d'une séance travail/pause répétée, sans avoir à créer de séance au préalable (accessible depuis la barre de navigation de l'accueil).
- Nom, durée de travail, durée de pause et nombre de répétitions personnalisables ; les répétitions utilisent le même sélecteur `−` / `+` que les groupes de séances.
- Temps total estimé recalculé en direct, sans compter la dernière pause puisqu'elle n'est pas exécutée ; une aide contextuelle précise les éléments inclus dans ce calcul.
- La séance est générée entièrement en mémoire et exécutée avec le même moteur qu'une séance classique (mêmes statistiques, même historique) — elle n'est jamais ajoutée à la liste des séances enregistrées.

### Historique
- Historique local des séances effectuées : nom, date, durée totale, statut.
- Tableau de bord par semaine ou par mois, avec navigation entre les périodes et liste filtrée sur la période affichée.
- Bilan des séances terminées et incomplètes, ainsi que du temps global passé : détail quotidien en vue hebdomadaire et agrégation par semaine en vue mensuelle.
- Suppression d'une entrée d'historique avec confirmation.
- Détail d'une séance avec sa date et son heure, ses statistiques de réalisation, ses durées de travail et de pause, puis le temps passé sur chaque exercice ou pause, regroupé dans des groupes initialement repliés.

### Import / Export
- Export d'une sauvegarde complète v2 via la fenêtre standard de partage : séances, historique, thème, préremplissage des noms et mode de notification.
- Compatibilité avec les anciens exports v1, importés de façon additive sans modifier l'historique ni les préférences.
- Restauration v2 complète après présentation d'un résumé et confirmation explicite : elle remplace les séances, l'historique et les trois préférences exportables.
- Lecture défensive du stockage local : les données récupérables restent consultables, les erreurs sont signalées sans exposer leur contenu et les mutations susceptibles d'écraser des données illisibles sont bloquées.

### Interface
- Thème système, clair ou sombre, réglable manuellement et conservé après redémarrage.
- Interface entièrement en français.
- Interface uniquement en mode portrait pour conserver la lisibilité des écrans.

## Stack technique

- **Flutter / Dart**
- Stockage local via `shared_preferences` (séances et historique, format JSON)
- `wakelock_plus` pour le maintien de l'écran actif pendant l'exécution
- `file_picker` pour l'import des séances
- `share_plus` pour l'export des séances via la fenêtre standard de partage d'éléments
- `flutter_launcher_icons` pour la gestion du logo
- `package_info_plus` pour l'affichage des informations du package dans la boîte « À propos »
- `flutter_foreground_task` pour le Foreground Service Android de la notification persistante pendant l'exécution d'une séance

Aucun backend, aucun compte utilisateur : toutes les données restent sur l'appareil.

## Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal stable)
- Un appareil Android (ou un émulateur) avec le débogage USB activé, ou le support desktop Linux activé (instable) pour tester sur PC

## Installation

```bash
git clone https://github.com/YannickLevadoux/rep_timer.git
cd rep_timer
flutter pub get
```

## Lancer l'application

Les lancements locaux doivent de préférence passer par le script
`tool/flutter_with_build_metadata.sh`. Le premier argument est directement la
sous-commande Flutter : il ne faut pas ajouter le mot `flutter` après le nom du
script.

Commandes disponibles :

```bash
# Afficher l'aide du script
./tool/flutter_with_build_metadata.sh --help

# Lancer l'application sur un appareil Android connecté
./tool/flutter_with_build_metadata.sh run

# Lancer l'application sur Linux desktop
./tool/flutter_with_build_metadata.sh run -d linux
```

Les options placées après `run` sont transmises à Flutter. Les métadonnées de
ces lancements locaux sont décrites dans le [guide des builds et des
releases](docs/release.md).

## Documentation

- [Créer et exécuter des séances](docs/training-sessions.md) : groupes libres,
  groupes à répétitions variables, édition et exécution.
- [Importer, exporter et restaurer](docs/import-export.md) : sauvegarde v2,
  compatibilité v1 et précautions avant une restauration.
- [Contribuer au projet](CONTRIBUTING.md) : environnement de développement,
  structure du projet, branches, issues et mises à jour Renovate.
- [Intégration continue et déploiement](docs/ci-cd.md) : workflows,
  authentification, validations et reproductibilité.
- [Builds et releases](docs/release.md) : distributions DEV et officielles,
  métadonnées, signature, dialogue « À propos » et publication.
- [Notes de version 1.3.0](docs/release-notes-1.3.0.md) : nouveautés,
  compatibilité et corrections importantes de cette version.

## Auteur

[Yannick Levadoux](https://github.com/YannickLevadoux)

Avec l'aimable contribution de [Claude](https://claude.ai/) et de [ChatGPT](https://chatgpt.com/)
