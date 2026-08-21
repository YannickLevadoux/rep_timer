# RepTimer 1.5.0

RepTimer 1.5.0 simplifie la préparation et l'édition des séances, réorganise
les actions de l'accueil et sépare clairement le partage de séances de la
sauvegarde complète des données.

## Préparation au lancement

- Le résumé d'une séance enregistrée et l'éditeur d'une Session rapide
  permettent d'activer ou de désactiver la préparation pour le lancement en
  cours.
- Le contrôle part du réglage global, mais son état reste temporaire et n'est
  jamais enregistré dans les Paramètres.
- Lorsque le compte à rebours global est désactivé, une durée de 1 à 15
  secondes peut être choisie uniquement pour la séance à venir.
- Désactiver puis réactiver la préparation pendant le même lancement restaure
  la dernière durée connue. Un nouveau lancement repart toujours du réglage
  global.
- Une durée effective de 0 démarre directement au premier exercice. Une
  reprise de checkpoint ne rejoue jamais la préparation.

## Édition des séances et des groupes

- Le nom d'une séance se modifie désormais depuis son titre ou l'icône crayon,
  dans un dialogue placé en haut de l'écran pour rester visible avec le clavier.
- Une séance sans nom affiche le placeholder *Nouvelle séance*, qui n'est
  jamais enregistré comme nom réel.
- Le nom d'un groupe se modifie de la même façon depuis sa barre de titre.
- Les nouveaux groupes Libre et Variables reçoivent respectivement les noms
  initiaux `Libre` et `Variables`, entièrement modifiables et conservés dans
  leurs brouillons.
- Les erreurs de nom obligatoire disparaissent dès que la saisie redevient
  valide.
- Le clavier Android propose une majuscule au début des noms et des textes
  libres. RepTimer conserve toujours exactement la casse saisie.

## Actions de l'accueil

- Les actions d'une séance sélectionnée sont réparties sur deux lignes :
  **Dupliquer**, **Supprimer** et **Éditer**, puis **Commencer** sur toute la
  largeur.
- La suppression est maintenant accessible directement depuis l'accueil et
  réutilise la confirmation ainsi que les protections de mutation existantes.
- Après une suppression confirmée, la séance disparaît et la sélection est
  nettoyée.

## Sons et audio externe

- Les sons de séance, les signaux de préparation et les aperçus des Paramètres
  utilisent le ducking temporaire : le volume de la musique externe diminue
  brièvement, puis revient à son niveau normal sans interrompre la lecture.
- Les modes **Vibration** et **Rien** conservent leur comportement.

## Partage de séances

- **Exporter des séances** permet de sélectionner les séances à partager. Elles
  sont toutes cochées par défaut et les actions **Tout cocher** et **Tout
  décocher** facilitent la sélection.
- Le fichier créé utilise le format v1 et contient uniquement les séances
  sélectionnées, dans leur ordre d'affichage, avec les cinq types de groupes.
  Il ne contient ni historique, ni préférences, ni checkpoint.
- **Importer des séances** accepte uniquement ce format v1 et ajoute toutes les
  séances avec de nouveaux identifiants. Les séances locales, l'historique, les
  préférences et le checkpoint ne sont jamais remplacés.

## Sauvegarde et restauration complètes

- **Sauvegarder les données** crée toujours une sauvegarde complète v3 avec les
  séances, l'historique et les préférences exportables.
- **Restaurer les données** accepte les sauvegardes v2 historiques et les
  sauvegardes v3. Après validation et confirmation, ce parcours remplace les
  données locales couvertes par le fichier.
- La séparation est stricte : un v1 choisi pour une restauration, ou un v2/v3
  choisi pour un import additif, est refusé sans mutation et avec une indication
  du bon parcours.
- Une sauvegarde valide sans séance ou sans historique reste restaurable. Le
  dialogue avertit explicitement de la suppression des données locales
  correspondantes avant d'appliquer les préférences du fichier.
- Fermer un sélecteur ou la feuille de partage est traité comme une annulation,
  sans faux succès ni modification des données.

## Mise à jour technique

- Le projet utilise Flutter 3.47.1 et conserve ses garde-fous de formatage,
  d'analyse, de taille des fichiers Dart et de couverture.
- La version du package passe à `1.5.0+8`. Le dialogue **À propos** continue de
  lire la version et le numéro de build depuis les métadonnées du package.

## Qualité

- Les 627 tests automatisés passent.
- La couverture globale atteint **93,77 %** (`6 942 / 7 403` lignes), au-dessus
  du seuil bloquant de 91,78 %.
- La couverture différentielle n'est pas calculable pour cette finalisation,
  qui ne modifie aucune ligne Dart. Elle reste bloquante à 90 % dès que des
  lignes Dart sont ajoutées ou modifiées dans une Pull Request.
- Aucun fichier Dart suivi sous `lib/` n'atteint 200 lignes ; les plus grands
  fichiers comptent 199 lignes.
- Le formatage bloquant et l'analyse statique passent sans modification ni
  diagnostic.

## Validations manuelles Android restantes

- [ ] vérifier le contrôle de préparation sur une séance enregistrée et une
  Session rapide, avec un réglage global à 0 puis supérieur à 0, y compris
  sélection, annulation, désactivation, réactivation et nouveau lancement ;
- [ ] confirmer qu'une reprise de checkpoint ne rejoue pas la préparation et
  qu'une durée effective de 0 démarre directement ;
- [ ] éditer des noms de séance et de groupe avec le clavier ouvert, un nom
  long, du texte agrandi et les thèmes clair et sombre ;
- [ ] vérifier sur le clavier Android la majuscule proposée pour les noms,
  exercices et commentaires, ainsi que l'absence de changement des champs
  numériques ou de la casse existante ;
- [ ] vérifier sur l'accueil la disposition des quatre actions, puis annuler et
  confirmer une suppression ;
- [ ] lancer de la musique dans une autre application, déclencher plusieurs
  sons de séance, signaux de préparation et aperçus, puis vérifier le ducking
  temporaire sans pause de la lecture externe ;
- [ ] exporter une sélection contenant les cinq types de groupes, annuler une
  feuille de partage puis partager et réimporter le v1 sans perte locale ;
- [ ] refuser un v1 depuis **Restaurer les données** et un v3 depuis **Importer
  des séances**, puis annuler chaque sélecteur sans mutation ;
- [ ] créer une sauvegarde v3, restaurer une v2 puis une v3, annuler une
  restauration et vérifier le rollback en cas d'échec ;
- [ ] restaurer une sauvegarde valide sans séance ni historique et vérifier
  l'avertissement, la suppression des données locales et l'application des
  préférences du fichier ;
- [ ] vérifier les nouveaux écrans sur une petite surface portrait, avec texte
  agrandi et dans les thèmes clair et sombre ;
- [ ] vérifier le dialogue **À propos** : version `1.5.0`, build `8` et absence
  de badge DEV sur l'APK de release.

**Changelog complet** :
https://github.com/YannickLevadoux/rep_timer/compare/v1.4.0...v1.5.0
