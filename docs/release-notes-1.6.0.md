# RepTimer 1.6.0

RepTimer 1.6.0 étend les groupes Tabata avec plusieurs tours et un exercice
propre à chaque cycle. La Session rapide repose sur le même modèle, le même
éditeur et le même moteur d'exécution. Cette version conserve les données
locales existantes et n'ajoute ni compte utilisateur ni service distant.

## Tabata à plusieurs tours

- Un groupe peut rejouer de 1 à 99 tours d'une liste ordonnée de 1 à 999
  cycles. Chaque cycle possède un exercice nommé avec sa propre icône et son
  commentaire facultatif.
- La durée des efforts reste commune à tous les exercices. L'éditeur présente
  désormais **Durée des efforts** et ouvre **Modifier les exercices** pour
  ajouter, supprimer ou réordonner les cycles dans un brouillon atomique.
- Les noms des nouveaux exercices suivent la préférence de préremplissage :
  `Effort n` lorsqu'elle est active, champ vide à compléter sinon.
- Les pauses utilisent une présentation compacte et le dialogue partagé
  **Modifier la pause**. La pause entre cycles reste obligatoire.
- La pause de fin de tour remplace la pause normale après le dernier cycle :
  elle ne crée jamais de double pause. Facultative avec un seul tour, elle
  devient obligatoire à partir de deux tours et conserve sa valeur lors d'un
  retour à un tour.
- Aucune pause n'est ajoutée après le dernier effort lorsque le Tabata termine
  la séance ou constitue une Session rapide. Lorsqu'un autre groupe suit, la
  pause de fin de tour résolue assure la transition.

## Exécution, progression et historique

- Le plan de séance rejoue les exercices dans leur ordre à chaque tour et
  conserve leur nom, leur icône et leur commentaire sans modifier la
  configuration source.
- Le runner et la liste **Progression** affichent le tour et le cycle, par
  exemple `Tour 1/2 · Cycle 3/4`. L'affichage reste concis avec un seul tour.
- Les actions précédente/suivante, le saut manuel, la pause globale, les
  notifications et la reprise de checkpoint continuent d'utiliser les
  services de séance existants.
- L'historique distingue chaque occurrence par tour et cycle et conserve
  l'exercice réellement exécuté, sa durée et son statut. Les anciens
  historiques dépourvus de ces métadonnées restent lisibles.
- Les résumés et estimations utilisent le plan réel, avec la pause de fin de
  tour uniquement lorsqu'elle est effectivement exécutée.

## Compatibilité, sauvegardes et données locales

- Un ancien Tabata de `N` cycles est lu comme un tour de `N` exercices clonés.
  Le nom, l'icône, le commentaire, les durées et la dernière pause historiques
  sont conservés sans réécriture destructive à la lecture.
- **Sauvegarder les données** crée désormais une sauvegarde complète v4,
  incluant sans perte la nouvelle configuration Tabata. **Restaurer les
  données** continue d'accepter les sauvegardes v2 et v3 en plus de la v4.
- L'import et l'export sélectifs v1 restent additifs et distincts de la
  restauration complète.
- Les schémas incomplets, invalides ou futurs sont refusés avant toute
  mutation. Les validations intégrales, écritures transactionnelles,
  rollbacks et protections contre l'écrasement de données illisibles sont
  conservés.
- La limite globale de 10 000 étapes développées est vérifiée avant allocation.
  Toutes les séances, préférences, sauvegardes et entrées d'historique restent
  exclusivement stockées sur l'appareil ou dans les fichiers choisis par
  l'utilisateur.

## Version et qualité mesurée

- La version du package est `1.6.0+10`. Le dialogue **À propos** lit toujours
  la version et le build depuis les métadonnées du package et affiche
  `1.6.0 (10)` ; l'APK debug produit les métadonnées Android `versionName`
  `1.6.0` et `versionCode` `10`.
- Les 730 tests automatisés passent avec une couverture globale de **96,75 %**
  (`7 901 / 8 166` lignes), au-dessus du seuil bloquant de 91,78 %. Aucun
  fichier mesuré n'est sous 80 %.
- La couverture différentielle n'est pas évaluée, car la branche de
  finalisation ne modifie aucune ligne Dart instrumentable sous `lib/`. Elle
  reste bloquante à 90 % lorsqu'elle est calculable dans la CI.
- Les 241 fichiers Dart suivis sous `lib/` respectent la limite de 199 lignes.
  Le maximum mesuré est de 199 lignes pour `lib/screens/home_screen.dart`.
- Les 353 fichiers contrôlés sont correctement formatés, l'analyse statique ne
  remonte aucun diagnostic et l'APK debug est construit avec succès.

## Validations manuelles Android restantes

- [ ] migrer une installation 1.5.1 contenant un Tabata existant de plusieurs
  cycles et vérifier la conservation de toutes ses données ;
- [ ] créer et modifier un Tabata à un tour, puis à plusieurs tours ;
- [ ] ajouter, renommer, illustrer, commenter, supprimer et réordonner les
  cycles ;
- [ ] vérifier le préremplissage actif puis désactivé ;
- [ ] modifier les pauses normale et de fin de tour, puis effectuer le passage
  1 → plusieurs → 1 tours sans perte de valeur ;
- [ ] vérifier l'absence de double pause et de pause finale inutile ;
- [ ] tester l'exécution, précédente/suivante, la pause globale,
  l'arrière-plan et la reprise depuis un checkpoint ;
- [ ] vérifier `Tour x/y · Cycle x/y` dans le runner et la Progression, ainsi
  que les notifications et l'historique ;
- [ ] exécuter un Tabata équivalent depuis la Session rapide ;
- [ ] exporter une sauvegarde v4, puis restaurer des sauvegardes v4, v3 et v2 ;
- [ ] vérifier l'import et l'export sélectifs v1 ;
- [ ] parcourir les éditeurs sur petit écran, avec texte agrandi, thèmes clair
  et sombre et orientation portrait ;
- [ ] vérifier le dialogue **À propos** en version `1.6.0`, build `10` ;
- [ ] installer et lancer l'APK officiel, vérifier la lecture des données
  existantes et l'absence du badge DEV.

**Changelog complet** :
https://github.com/YannickLevadoux/rep_timer/compare/v1.5.1...v1.6.0
