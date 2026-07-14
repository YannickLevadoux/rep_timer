# RepTimer

Application mobile (Android) de suivi et d'exécution de séances d'entraînement, développée avec Flutter.

RepTimer permet de créer ses propres séances (échauffement, circuits, séries...), de les organiser en groupes d'exercices répétables, puis de les exécuter avec un système de minuteur, de progression et d'historique.

## Fonctionnalités

### Création et édition des séances
- Séances composées de **groupes d'exercices**, chaque groupe pouvant être répété un nombre de fois défini (rounds).
- Trois types d'exercices :
  - **Répétitions** — un nombre de répétitions à effectuer.
  - **Temps** — une durée définie (saisie via un sélecteur Minutes/Secondes).
  - **Durée libre** — aucun temps ni répétitions fixés à l'avance ; l'utilisateur décide lui-même de la fin de l'exercice, un chronomètre mesure le temps réellement passé.
- Pauses chronométrées entre les exercices.
- Réorganisation par glisser-déposer des groupes et des exercices.
- Icône personnalisable par exercice, parmi une liste prédéfinie.
- Commentaire libre et optionnel par exercice (poids, intensité...), modifiable aussi bien à l'édition que pendant l'exécution de la séance.
- Détection des modifications non enregistrées à la fermeture de l'écran d'édition (proposition d'enregistrer, d'abandonner ou d'annuler).

### Exécution d'une séance
- Écran de résumé avant le lancement (aperçu des groupes et exercices).
- Empêche la mise en veille de l'écran pendant toute la durée de la séance.
- Chronomètre global de la séance, indépendant du minuteur de chaque exercice.
- Navigation manuelle entre les exercices (précédent/suivant), en plus de la progression automatique.
- Mise en évidence visuelle (clignotement) de l'exercice en cours.
- Pause/reprise de la séance à tout moment.
- Écran de progression détaillée, avec possibilité de sauter directement à un exercice donné (avec confirmation).
- Fin de séance anticipée possible (statut "Incomplète") ou normale (statut "Terminée"), toutes deux enregistrées dans l'historique.
- Si une pause est définie la fin de la séance (dernière pause du dernier groupe), cette pause sera ignorée.

### Historique
- Historique local des séances effectuées : nom, date, durée totale, statut.
- Suppression d'une entrée d'historique avec confirmation.
- Détail d'une séance : temps passé sur chaque exercice

### Import / Export
- Export des séances enregistrées 
- Import des séances basé (json) sur un fichier précédement enregistré

### Interface
- Thème clair/sombre (suit le système, réglable manuellement).
- Interface entièrement en français.
- Interface uniquement en mode portrait pour conserver la lisibilité des écrans

## Stack technique

- **Flutter / Dart**
- Stockage local via `shared_preferences` (séances et historique, format JSON)
- `wakelock_plus` pour le maintien de l'écran actif pendant l'exécution
- `file_picker` pour l'import des séances
- `share_plus` pour l'export des séance via la fenetre stardard de partage d'éléments
- `flutter_launcher_icons` pour la gestion du logo

Aucun backend, aucun compte utilisateur : toutes les données restent sur l'appareil.

## Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal stable)
- Un appareil Android (ou un émulateur) avec le débogage USB activé, ou le support desktop Linux activé pour tester sur PC

## Installation

```bash
git clone https://github.com/YannickLevadoux/rep_timer.git
cd rep_timer
flutter pub get
```

## Lancer l'application

Sur un appareil Android connecté :
```bash
flutter run
```

Sur Linux desktop :
```bash
flutter run -d linux
```

## Build

APK release :
```bash
flutter build apk --release
```
L'APK généré se trouve dans `build/app/outputs/flutter-apk/app-release.apk`.

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

## Auteur

[Yannick Levadoux](https://github.com/YannickLevadoux)

Avec l'aimable contribution de [Claude](https://claude.ai/)