# RepTimer 1.3.0

Cette version renforce la création des séances, ajoute les groupes à
répétitions variables et transforme l'historique en tableau de bord. Elle
introduit également une sauvegarde complète et restaurable.

## Saisie plus sûre

- Contrats communs à l'interface, à l'import et au lancement des séances.
- Erreurs explicites pour les noms, commentaires, répétitions, tours et durées,
  sans correction ni troncature silencieuse.
- Protection contre les séances excessives avec une limite de 10 000 étapes
  vérifiée avant leur développement en mémoire.
- Affichages adaptés aux textes longs, aux petits écrans et au texte agrandi.

## Groupes à répétitions variables

- Création de suites libres telles que `10, 12, 15, 12, 10`, avec ajout,
  suppression et réordonnancement des tours.
- Application de la valeur du tour aux exercices en mode Répétitions, tout en
  permettant des groupes mixtes avec exercices chronométrés, durées libres et
  pauses.
- Changement non destructif entre groupe libre et groupe variable : tours,
  suite et répétitions individuelles restent disponibles.
- Résumé avant séance, exécution, reprise par checkpoint et historique adaptés
  à la répétition réellement résolue pour chaque tour.

## Historique hebdomadaire et mensuel

- Navigation par semaine ou par mois, sans permettre de période future.
- Bilan des séances terminées et incomplètes, avec liste filtrée sur la période
  affichée et mise à jour immédiate après suppression.
- Vue du temps global passé par jour sur une semaine et total hebdomadaire.
- Vue mensuelle agrégée par semaine pour le nombre de séances ou le temps passé,
  avec accès au détail d'une semaine.
- Prise en compte des séances normales, incomplètes et Quick Tabata.

## Préférences et sauvegardes

- Persistance du thème système, clair ou sombre après redémarrage.
- Nouvel export complet v2 contenant les séances, l'historique et les trois
  préférences exportables, y compris les groupes à répétitions variables et
  leurs valeurs dormantes.
- Compatibilité d'import des anciens fichiers v1 : leurs séances sont ajoutées
  sans modifier les données locales existantes, l'historique ou les
  préférences.
- Restauration v2 avec résumé et confirmation explicite avant remplacement des
  séances, de l'historique et des préférences.
- Validation complète avant mutation et rollback en cas d'échec, sans succès
  partiel annoncé.

## Fiabilisation

- Les snapshots d'historique conservent les répétitions résolues des groupes
  variables.
- La reprise d'une séance interrompue contrôle le checkpoint et restaure la
  progression cohérente avec le bon tour.
- Les données locales anciennes ou partiellement lisibles restent protégées
  contre les mutations susceptibles de les écraser.
- Le script de build local arrête les anciens daemons Gradle et signale les
  gros fichiers Dart avant un lancement ou un build.

**Changelog complet** :
https://github.com/YannickLevadoux/rep_timer/compare/v1.2.0...v1.3.0
