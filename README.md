# RepTimer

[![CI](https://github.com/YannickLevadoux/rep_timer/actions/workflows/ci.yml/badge.svg)](https://github.com/YannickLevadoux/rep_timer/actions/workflows/ci.yml)
[![Release](https://github.com/YannickLevadoux/rep_timer/actions/workflows/release.yml/badge.svg)](https://github.com/YannickLevadoux/rep_timer/actions/workflows/release.yml)

Application mobile (Android) de suivi et d'exécution de séances d'entraînement, développée avec Flutter.

Pas de version iOS prévue.

RepTimer permet de créer ses propres séances (échauffement, circuits, séries...), de les organiser en groupes d'exercices répétables, puis de les exécuter avec un système de minuteur, de progression et d'historique.

## Fonctionnalités

### Création et édition des séances
- Séances composées de **groupes d'exercices**, chaque groupe pouvant être répété un nombre de fois défini (rounds).
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

### Quick Tabata
- Lancement rapide d'une séance travail/pause répétée, sans avoir à créer de séance au préalable (accessible depuis la barre de navigation de l'accueil).
- Nom, durée de travail, durée de pause et nombre de répétitions personnalisables ; les répétitions utilisent le même sélecteur `−` / `+` que les groupes de séances.
- Temps total estimé recalculé en direct, sans compter la dernière pause puisqu'elle n'est pas exécutée ; une aide contextuelle précise les éléments inclus dans ce calcul.
- La séance est générée entièrement en mémoire et exécutée avec le même moteur qu'une séance classique (mêmes statistiques, même historique) — elle n'est jamais ajoutée à la liste des séances enregistrées.

### Historique
- Historique local des séances effectuées : nom, date, durée totale, statut.
- Suppression d'une entrée d'historique avec confirmation.
- Détail d'une séance avec sa date et son heure, ses statistiques de réalisation, ses durées de travail et de pause, puis le temps passé sur chaque exercice ou pause, regroupé dans des groupes initialement repliés.

### Import / Export
- Export des séances enregistrées via la fenêtre standard de partage.
- Import des séances au format JSON depuis un fichier précédemment exporté.
- Lecture défensive du stockage local : les données récupérables restent consultables, les erreurs sont signalées sans exposer leur contenu et les mutations susceptibles d'écraser des données illisibles sont bloquées.

### Interface
- Thème clair/sombre (suit le système, réglable manuellement).
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

Les builds locaux doivent de préférence passer par le script
`tool/flutter_with_build_metadata.sh`. Le premier argument est directement la
sous-commande Flutter (`run` ou `build`) : il ne faut pas ajouter le mot
`flutter` après le nom du script.

Commandes disponibles :

```bash
# Afficher l'aide du script
./tool/flutter_with_build_metadata.sh --help

# Lancer l'application sur un appareil Android connecté
./tool/flutter_with_build_metadata.sh run

# Lancer l'application sur Linux desktop
./tool/flutter_with_build_metadata.sh run -d linux
```

Ce script transmet le canal `dev` et la date de compilation UTC avec les
`--dart-define` centralisés dans `BuildMetadata`. Les options placées après
`run` sont transmises à cette commande Flutter. Un lancement direct avec
`flutter run` reste possible : il est considéré comme DEV, mais le dialogue
« À propos » indique alors que la date de build est indisponible.

## Build

Le script accepte les options Flutter après la cible `apk` :

```bash
# APK debug local
./tool/flutter_with_build_metadata.sh build apk --debug

# APK release local, toujours identifié comme DEV
./tool/flutter_with_build_metadata.sh build apk --release
```

Les APK générés se trouvent dans `build/app/outputs/flutter-apk/`.

Le mode Flutter (`--debug` ou `--release`) ne détermine pas le canal de
distribution : même un APK release construit avec ce script porte le badge
DEV. Seule la CI de publication transmet explicitement
`REP_TIMER_DISTRIBUTION=release`. Elle n'injecte pas de date et ne modifie ni la
version ni le numéro de build définis dans `pubspec.yaml`.

## Structure du projet

```
lib/
├── main.dart                  # Écran d'accueil, liste des séances
├── models/                    # Training, ExerciseGroup, TrainingItem, historique...
├── screens/                   # Édition, résumé, exécution, progression, historique
├── services/                  # Stockage local (séances, historique)
├── widgets/                   # Composants réutilisables (cartes, pickers, sélecteurs)
└── utils/                     # Formatage, registre d'icônes...
```


## Développement GitHub & CI/CD

### Vue d'ensemble

```mermaid
flowchart LR
    A[Issue avec label ready]
    B[Push sur une branche conforme]
    C[Issue avec label in-progress]
    D[Pull Request créée ou vérifiée vers main]
    E[Validation et APK debug]
    F[Merge]
    G[Issue fermée]

    A --> B
    B --> C
    B --> D --> E --> F
    F -->|Close ou Closes présent| G
```

Les automatisations sont réparties entre quatre workflows :

- `issue-lifecycle.yml` gère la convention des branches, les labels, la création des Pull Requests et leur liaison avec les issues ;
- `flutter-validate.yml` centralise les contrôles Flutter réutilisés par la CI et les releases ;
- `ci.yml` valide les Pull Requests vers `main` et construit un APK debug ;
- `release.yml` construit et publie un APK signé lors de l'envoi d'un tag `v*`.

### Convention de nommage des branches

Chaque branche de développement doit être associée à une unique issue GitHub et respecter le format suivant :

```text
<type>/<issue>-<description>
```

avec :

- `type` parmi `feature`, `bugfix`, `hotfix` ou `clean` ;
- `issue` correspondant au numéro de l'issue GitHub ;
- `description` sous la forme d'une description courte, généralement en *kebab-case*.

Exemples :

```text
feature/33-refacto-training-editor
bugfix/61-session-save
hotfix/85-crash-startup
clean/76-refacto-whatever
```

Le workflow de cycle de vie surveille uniquement les pushes sur ces quatre familles de branches. Il vérifie leur nom avec l'expression `<type>/<numéro>-<description>` et échoue si le nom complet n'est pas conforme. Les autres branches ne bénéficient pas de cette automatisation et ne sont pas considérées comme des erreurs.

Lors de la fusion d'une Pull Request ou de la suppression d'une branche, le traitement est exécuté uniquement si une issue peut être extraite d'un nom conforme. Dans le cas contraire, le workflow publie une information puis termine sans erreur. Les branches Renovate sont exclues du cycle de vie.

### Cycle de vie d'une issue

Une issue prête à être développée doit d'abord porter le label `ready`.

Au premier push sur une branche conforme, le job `sync-issue-and-pr` :

- le numéro de l'issue est extrait du nom de la branche ;
- le label `in-progress` est ajouté ;
- le label `ready` est supprimé ;
- une Pull Request est créée vers `main`, avec le titre `#<issue> - <titre de l'issue>`.

L'issue doit être ouverte et porter `ready` ou `in-progress`. Le workflow échoue si ces préconditions ne sont pas respectées.

La description d'une Pull Request créée par le workflow contient :

```text
Closes #<issue>

> 🤖 Pull request créée automatiquement par GitHub Actions.
```

À chaque push suivant, le workflow vérifie de manière idempotente le label, la Pull Request vers `main` et la directive `Closes #<issue>`. Si tous les éléments sont déjà présents, il ne les modifie pas et publie simplement leur état dans GitHub Actions.

Si une Pull Request vers `main` a été créée manuellement, le workflow conserve sa description et ajoute uniquement `Closes #<issue>` si nécessaire. La mention de création automatique n'est jamais ajoutée à une Pull Request existante et ne peut donc pas être dupliquée lors des pushes suivants.

Lors de la fusion de la Pull Request :

- le label `in-progress` est retiré ;
- l'issue est fermée si la description ou un commentaire de la Pull Request contient `Close #<issue>` ou `Closes #<issue>`, sans distinction de casse.

Lorsqu'une branche est supprimée, le label `in-progress` est retiré si l'issue associée est encore ouverte. Tous les changements, éléments déjà présents et traitements ignorés sont publiés dans les logs et dans des tableaux récapitulatifs GitHub Actions. Les véritables erreurs d'API ou d'exécution font échouer le job.

### Authentification de la création des Pull Requests

Le step `Sync issue and pull request` utilise un PAT fine-grained stocké dans le secret GitHub Actions `PR_AUTOMATION_TOKEN`. L'utilisation de ce PAT, plutôt que de `GITHUB_TOKEN`, permet aux validations de la Pull Request créée automatiquement de démarrer sans approbation manuelle du workflow.

Le PAT doit être limité à ce dépôt et disposer uniquement des permissions suivantes :

- `Issues` : `Read and write` ;
- `Pull requests` : `Read and write`.

Les jobs de fusion et de suppression continuent d'utiliser `GITHUB_TOKEN`. Le PAT ne doit jamais être ajouté directement au dépôt ; lors de son renouvellement, seule la valeur du secret `PR_AUTOMATION_TOKEN` doit être mise à jour dans `Settings` → `Secrets and variables` → `Actions`.

### Validation des Pull Requests

Le workflow `ci.yml` s'exécute uniquement pour les Pull Requests ciblant `main`. Il appelle d'abord le workflow réutilisable `flutter-validate.yml`.

Après le checkout, un rapport non bloquant recense les fichiers Dart suivis par Git sous `lib/`. Il affiche directement dans le résumé de l'Action trois tableaux triés par nombre de lignes :

- plus de 300 lignes ;
- entre 250 et 300 lignes ;
- entre 200 et 249 lignes.

Le comptage comprend les commentaires et les lignes vides. Les fichiers de tests et les fichiers générés ne sont pas inclus. Une erreur lors de la génération de ce rapport ne fait pas échouer la validation.

Le workflow poursuit ensuite les contrôles Flutter :

1. la récupération des dépendances avec `flutter pub get` ;
2. la vérification du formatage avec `dart format --output=none --set-exit-if-changed .` ;
3. l'analyse statique avec `flutter analyze --no-fatal-infos` ;
4. les tests automatisés avec `flutter test --coverage`.

Les informations remontées par l'analyseur ne sont donc pas bloquantes actuellement, contrairement aux avertissements et aux erreurs.

Une fois la validation réussie, un second job configure Java et Flutter, récupère les dépendances puis construit un APK Android debug avec :

```bash
flutter build apk --debug
```

Le build debug ne démarre pas si le job de validation échoue.

### Reproductibilité

Les jobs Flutter utilisent les mêmes versions et paramètres :

- Flutter `3.44.8`, explicitement épinglé avec le cache activé ;
- Java `17`, distribution Temurin ;
- versions épinglées des GitHub Actions utilisées par les workflows ;
- fichier `pubspec.lock` suivi dans le dépôt.

Les workflows CI et Release utilisent aussi des groupes de concurrence distincts. Lorsqu'une nouvelle exécution démarre pour une même référence Git, l'exécution précédente encore en cours est annulée.

### Création d'une release

Le workflow `release.yml` se déclenche lors de l'envoi de tout tag correspondant à `v*`. Il réutilise les mêmes validations que la CI avant d'autoriser le job de publication.

Après validation, le workflow :

1. configure Java 17 et Flutter 3.44.8 ;
2. récupère les dépendances ;
3. décode le keystore Android depuis le secret `KEYSTORE_BASE64` ;
4. génère `android/key.properties` à partir des secrets `KEYSTORE_PASSWORD`, `KEY_PASSWORD` et de la variable `KEY_ALIAS` ;
5. construit l'APK release signé avec `flutter build apk --release --dart-define=REP_TIMER_DISTRIBUTION=release` ;
6. renomme l'artefact en `RepTimer-<tag>.apk` ;
7. crée une GitHub Release avec des notes générées automatiquement et y joint l'APK.

La publication nécessite donc que les validations réussissent et que les secrets et variables de signature Android soient configurés dans le dépôt GitHub.

### Mise à jour des dépendances

Renovate crée des Pull Requests portant le label `dependencies` pour :

- les dépendances Dart et Flutter, regroupées sous `Dart & Flutter packages` ;
- les GitHub Actions, regroupées sous `GitHub Actions` ;
- la version de Flutter déclarée dans les workflows, détectée par une règle dédiée.

Les Pull Requests Renovate ciblant `main` passent par les mêmes validations et le même build APK debug que les autres Pull Requests.


## About

Declarer l'image en tant que assets dans pubspec.yaml

```yaml
flutter:
  assets:
    - assets/icon/app_icon.png
```

Documentation — où modifier chaque information

| Information | Où c'est défini | Comment ça arrive dans le dialogue |
| ----------- | --------------- | ---------------------------------- |
| Nom de l'app | `android/app/src/main/AndroidManifest.xml`, attribut `android:label` | Lu au runtime par PackageInfo.fromPlatform().appName | 
| Icône | `assets/icon/app_icon.png` (le fichier source utilisé par flutter_launcher_icons pour générer les icônes natives) | Chargée via Image.asset(), une fois déclarée dans pubspec.yaml | 
| Version | `pubspec.yaml`, champ `version`: X.Y.Z+B | Lue via PackageInfo.fromPlatform().version/.buildNumber — c'est ce même champ que Flutter utilise pour générer versionName/versionCode Android à la compilation| 
| Copyright | Constante `_copyright` dans `lib/widgets/settings/app_about_dialog.dart` | Aucun autre endroit du projet ne porte cette info : c'est le seul point à éditer |

Les métadonnées de distribution sont centralisées dans
`lib/models/build_metadata.dart` :

| Variable de compilation | Valeur | Effet |
| ----------------------- | ------ | ----- |
| `REP_TIMER_DISTRIBUTION` | `dev` par défaut, `release` pour une publication officielle | Affiche ou masque le badge DEV et les informations de build local |
| `REP_TIMER_BUILD_TIMESTAMP` | Date ISO 8601 en UTC, optionnelle | Est convertie dans le fuseau local de l'appareil avant affichage |

`kReleaseMode` ne permet pas cette distinction : un développeur peut produire
localement un APK optimisé avec `flutter build apk --release`. Le workflow de
release garantit l'absence du badge DEV en transmettant explicitement le canal
`release` au build signé.

## Auteur

[Yannick Levadoux](https://github.com/YannickLevadoux)

Avec l'aimable contribution de [Claude](https://claude.ai/)
