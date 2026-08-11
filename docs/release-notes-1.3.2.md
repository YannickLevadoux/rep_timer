# RepTimer 1.3.2

Cette version transforme la couverture des tests en garde-fou CI, renforce les
frontières Android et de sauvegarde, puis apporte trois ajustements ciblés à
l'Historique, au démarrage Android et à Quick Tabata.

## Couverture et intégration continue

- Le rapport LCOV est vérifié, résumé dans GitHub Actions et publié comme
  artefact pendant 14 jours.
- La CI échoue lorsque la couverture globale descend sous **90,00 %** ou que le
  rapport LCOV est absent, vide ou invalide.
- La couverture des lignes Dart ajoutées ou modifiées est affichée à titre
  informatif dans les Pull Requests.
- La suite atteint **422 tests** et **91,78 %** de couverture de lignes
  (`5 079 / 5 534`), contre 361 tests et 90,38 % pour la version 1.3.1.

## Notifications Android et sauvegardes

- Les frontières de notification, son et vibration sont simulables et testées
  sans modifier la politique best-effort ni la prévention des doublons.
- Le gestionnaire de tâche Android atteint 93,10 % de couverture ; le service
  de notification et le service de fin d'étape atteignent 100 %.
- La sélection, la lecture, l'écriture et le partage des sauvegardes sont
  isolés derrière des contrats testables.
- L'orchestration du transfert atteint 100 % de couverture tout en conservant
  les formats v1/v2 et les protections de restauration existants.

## Historique

- En vue hebdomadaire, le nombre de séances utilise désormais un histogramme
  de sept barres, du lundi au dimanche.
- Chaque barre empile les séances terminées et incomplètes avec leurs couleurs
  existantes ; un appui affiche le détail du jour sans filtrer la liste.
- Le bilan hebdomadaire, la navigation, la vue mensuelle et les protections de
  stockage restent inchangés.

## Démarrage Android

- Un splash natif violet avec l'icône RepTimer est affiché avant la première
  frame Flutter.
- Android avant et après la version 12 ainsi que les modes clair et sombre
  disposent de ressources dédiées, sans délai artificiel.

## Quick Tabata

- Les libellés Work et Pause sont alignés avec leurs sélecteurs pour compacter
  l'écran sans réduire les contrôles partagés.
- Les espacements et la carte d'estimation sont réduits afin que le bouton
  **Commencer** soit visible sans défilement initial sur `360 × 640` à l'échelle
  de texte `1.0`.
- Le défilement reste disponible sur les écrans plus contraints et avec un
  texte agrandi.

## Validations manuelles restantes

- [ ] splash à froid sur Android 11 ou inférieur et Android 12+, en clair et sombre ;
- [ ] aucun flash noir, délai artificiel ou rognage de l'icône ;
- [ ] graphique hebdomadaire : sept jours, couleurs, empilement, détail et navigation ;
- [ ] Quick Tabata : bouton visible sans défilement sur `360 × 640` à
  l'échelle `1.0` et repli accessible ;
- [ ] notification en arrière-plan, pause/reprise, son et vibration sans doublon ;
- [ ] export v2, import v1 et restauration v2 sans perte inattendue ;
- [ ] résumé de couverture lisible, artefact LCOV disponible et seuil actif ;
- [ ] dialogue « À propos » affichant `1.3.2` et le build `6`.

**Changelog complet** :
https://github.com/YannickLevadoux/rep_timer/compare/v1.3.1...v1.3.2
