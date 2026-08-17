# RepTimer 1.4.0

RepTimer 1.4.0 ajoute trois groupes temporisés, remplace Quick Tabata par une
Session rapide couvrant les cinq types de groupes et propose une préparation
facultative avant chaque nouvelle séance.

## Cinq types de groupes

- **Libre** conserve ses exercices, pauses et tours configurables.
- **Répétitions variables** applique une suite ordonnée aux exercices en mode
  Répétitions.
- **Tabata** alterne un Effort et une Pause pendant 1 à 999 cycles. Une dernière
  pause personnalisée peut remplacer la pause normale lorsqu'un groupe suit.
- **AMRAP** enregistre jusqu'à 999 tours terminés pendant 1 à 60 minutes. Le
  dernier tour peut être annulé et le tour courant devient un tour partiel à
  l'expiration.
- **EMOM** redémarre automatiquement le même Effort de 60 secondes pendant 1 à
  60 minutes.

L'ajout d'un groupe demande d'abord son type. Le formulaire apparaît ensuite
avec les valeurs adaptées. Les changements incompatibles sont confirmés et les
brouillons des types visités restent disponibles pendant l'édition.

## Session rapide

- La destination **Rapide** permet de choisir et lancer l'un des cinq types.
- Aucun type n'est présélectionné ; Tabata conserve ensuite ses valeurs
  historiques de 20 secondes d'effort, 10 secondes de pause et un cycle.
- Le même éditeur, les mêmes validations et le même moteur sont utilisés que
  pour une séance enregistrée.
- La configuration reste uniquement en mémoire et n'apparaît jamais dans
  **Mes entraînements**.
- Une fin normale ou anticipée est toujours ajoutée à l'historique.

## Préparation avant séance

- Le nouveau réglage **Compte à rebours** accepte 0 à 15 secondes ; 0 conserve
  le démarrage immédiat.
- Le décompte **Prêt ?** est partagé par les séances enregistrées et rapides.
- Il peut être mis en pause, repris ou passé, et se met automatiquement en
  pause lorsque l'application passe en arrière-plan.
- Les signaux à 3, 2 et 1 seconde puis au démarrage respectent le mode Son,
  Vibration ou Rien.
- La préparation n'est incluse dans aucun chrono, checkpoint, historique,
  statistique ou estimation, et n'est pas rejouée lors d'une reprise.

## Historique, reprise et notifications

- Le détail d'un AMRAP conserve ses tours terminés, son tour partiel et son
  statut. Son checkpoint restaure précisément le temps, les tours et le délai
  actif du bouton.
- Le détail d'un EMOM distingue chaque minute terminée ou incomplète.
- Les étapes Tabata et EMOM réutilisent les notifications, la pause globale, la
  progression, les checkpoints et la complétion existants.
- Les récupérations après Tabata, AMRAP ou EMOM ne sont exécutées que lorsqu'un
  autre groupe suit.

## Données et sauvegardes

- Les données locales 1.3.2 restent lisibles sans migration destructive.
- Les nouveaux exports utilisent le format v3 et transportent les groupes
  temporisés ainsi que la préférence de compte à rebours.
- Les exports v1 restent importables de façon additive et les sauvegardes v2
  restent restaurables avec un compte à rebours ramené à 0.
- Les imports, restaurations et lectures locales conservent les validations
  défensives et les protections contre les mutations partielles.

## Qualité

- La couverture finale atteint **92,77 %** (`6 430 / 6 931` lignes), au-dessus
  du seuil bloquant de 91,78 %.
- La couverture des lignes ajoutées ou modifiées atteint **94,05 %**
  (`458 / 487`), au-dessus du seuil de 90 %.
- La CI refuse toujours tout fichier Dart suivi sous `lib/` atteignant 200
  lignes physiques.

## Validations manuelles Android restantes

- [ ] ajouter, modifier et exécuter chacun des cinq types dans une séance
  enregistrée, en clair et sombre ;
- [ ] vérifier l'état sans type, l'aide locale et les valeurs par défaut dans
  l'ajout d'un groupe et la Session rapide ;
- [ ] vérifier Tabata avec plusieurs cycles, une dernière pause personnalisée,
  un groupe suivant et une fin de séance ;
- [ ] vérifier AMRAP avec tours, délai anti-double appui, annulation, tour
  partiel, navigation, redémarrage confirmé, reprise et détail d'historique ;
- [ ] vérifier EMOM avec changement automatique de minute, navigation,
  récupération conditionnelle, reprise et détail d'historique ;
- [ ] confirmer qu'une Session rapide n'apparaît jamais dans **Mes
  entraînements**, mais apparaît dans l'historique après une fin normale ou
  anticipée ;
- [ ] tester le compte à rebours à 0, 1 et 15 secondes, sa pause, **Suivant**,
  l'arrière-plan, le dialogue Retour et l'absence de préparation à la reprise ;
- [ ] vérifier les signaux Son, Vibration et Rien, ainsi que la notification
  persistante en arrière-plan et sur écran verrouillé, sans doublon ;
- [ ] exporter une sauvegarde v3 puis la restaurer, importer un export v1 et
  restaurer une sauvegarde v2 sans perte inattendue ;
- [ ] vérifier les parcours principaux sur `360 × 640`, avec texte agrandi et
  réduction des animations ;
- [ ] vérifier le dialogue **À propos** : version `1.4.0`, build `7` et absence
  de badge DEV sur l'APK de release.

**Changelog complet** :
https://github.com/YannickLevadoux/rep_timer/compare/v1.3.2...v1.4.0
