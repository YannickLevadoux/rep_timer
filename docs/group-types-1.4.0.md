# Contrats des groupes RepTimer 1.4.0

Ce document fixe les contrats produit, métier et UX des groupes Tabata, AMRAP
et EMOM, ainsi que leur utilisation dans une Session rapide. Il constitue la
référence de conception des issues #158 à #164.

## Statut et périmètre

Les décisions décrites ici sont validées pour RepTimer 1.4.0 :

- Tabata, AMRAP et EMOM sont mono-exercice ;
- aucun sélecteur ni champ Mono/Multi n'est affiché ou persisté ;
- le Tabata multi-exercice est reporté après la 1.4.0 ;
- la Session rapide propose les cinq types de groupes ;
- une Session rapide n'est jamais ajoutée à **Mes entraînements**, mais son
  exécution est toujours conservée dans l'historique.

Elles reprennent les arbitrages du Product Owner et la revue UX du parcours
existant : sélecteur compact adapté aux petits écrans, libellés propres à
chaque type, formulaire partagé selon le contexte et transitions annoncées
sans surcharger les technologies d'assistance.

L'interface reste en français et en portrait. Les données restent locales.
Les services existants de session, progression, complétion, checkpoint,
historique et notification sont étendus, pas dupliqués dans les widgets.

## Vocabulaire

| Terme | Définition |
| --- | --- |
| Tour | Exécution complète de la liste d'un groupe Libre ou à répétitions variables. |
| Cycle Tabata | Un Effort suivi d'une Pause planifiée. |
| Tour AMRAP | Tour déclaré terminé par l'utilisateur avec le bouton dédié. |
| Tour partiel | Temps actif écoulé depuis le dernier tour AMRAP terminé. |
| Minute EMOM | Intervalle strict de 60 secondes consacré au même exercice. |
| Récupération après groupe | Pause optionnelle de transition, exécutée uniquement lorsqu'un autre groupe suit. |
| Temps actif | Temps d'exécution hors pause globale de la séance. |

## Règles communes

Les contrats de saisie actuels restent applicables :

- nom obligatoire, sur une ligne, limité à 50 caractères visibles ;
- commentaire facultatif, limité à 200 caractères visibles et trois lignes ;
- compteurs compris entre 1 et 999, sauf borne plus stricte d'un type ;
- exercice ou pause chronométré de 1 seconde à 2 h 00 min 59 s ;
- maximum de 10 000 `SessionStep` développés pour une séance entière ;
- validation identique en édition, avant lancement, en lecture locale et à
  l'import ;
- valeur invalide refusée sans correction, troncature ou mutation silencieuse.

Une récupération après groupe :

- est absente (`null`) par défaut ;
- est initialisée à la valeur propre au type lors de son ajout ;
- reste modifiable et supprimable, mais non réordonnable ;
- n'est développée que lorsqu'un autre groupe suit ;
- est masquée en Session rapide.

La pause globale suspend toutes les horloges, échéances et protections fondées
sur le temps actif. Le mode de notification existant reste la source unique de
vérité : son, vibration ou aucun signal. La notification persistante conserve
son comportement actuel.

## Tableau des cinq types

| Type | Structure enregistrée | Champ de répétition ou durée | Exécution |
| --- | --- | --- | --- |
| Libre | Liste ordonnée d'exercices et pauses | **Nombre de tours**, 1 à 999 | Liste répétée le nombre de tours choisi. |
| Répétitions variables | Liste ordonnée et suite de répétitions | **Répétitions par tour**, chaque valeur de 1 à 999 | La suite fournit les répétitions des exercices à chaque tour. |
| Tabata | Effort chronométré puis Pause chronométrée | **Nombre de cycles**, 1 à 999 | Alternance Effort/Pause ; dernière pause retirée si aucun groupe ne suit. |
| AMRAP | Un Effort chronométré | **Durée de l'AMRAP**, `01:00` à `60:00` | Chrono unique ; l'utilisateur enregistre les tours terminés. |
| EMOM | Un Effort fixe de 60 secondes | **Nombre de minutes**, 1 à 60 | Une occurrence automatique par minute. |

Le libellé générique **Répétitions** n'est plus utilisé pour le nombre de
tours d'un groupe Libre : **Nombre de tours** évite la confusion avec les
répétitions d'un exercice.

## Éditeur partagé

Un même contrôleur et les mêmes composants de formulaire servent les trois
contextes suivants :

| Contexte | Titre et action | Persistance |
| --- | --- | --- |
| Ajout | **Ajout de groupe** / **Ajouter à la séance** | Le groupe rejoint le brouillon de séance. |
| Modification | **Édition du groupe** / **Enregistrer** | Le groupe remplace l'original après validation. |
| Session rapide | **Session rapide** / **Commencer** | Une séance temporaire est construite uniquement au lancement. |

Le type est choisi dans le sélecteur compact existant. Une description courte
est affichée sous le champ. Le bouton d'aide partagé explique les acronymes
Tabata, AMRAP et EMOM sans occuper en permanence la hauteur de cinq cartes :

| Type | Description |
| --- | --- |
| Libre | Enchaîner la liste pendant un nombre de tours défini. |
| Répétitions variables | Définir les répétitions de chaque tour. |
| Tabata | Alterner effort et récupération sur des cycles courts. |
| AMRAP | Faire autant de tours que possible dans le temps imparti. |
| EMOM | Redémarrer l'exercice au début de chaque minute. |

Le passage d'un type à Tabata, AMRAP ou EMOM peut rendre les éléments courants
incompatibles. Avant leur remplacement visuel, un dialogue explique ce qui
sera initialisé. **Annuler** conserve le brouillon courant ; **Continuer**
affiche les valeurs par défaut du nouveau type.

Le contrôleur conserve un brouillon séparé pour chaque type visité pendant la
même édition. Un retour vers un type restaure son brouillon. Annuler l'éditeur
ne modifie jamais le groupe original et seul le type visible lors de
l'enregistrement est persisté.

## Tabata

### Modèle et valeurs

Un groupe Tabata contient exactement deux `TrainingItem`, dans cet ordre :

1. un exercice chronométré **Effort** ;
2. une pause chronométrée **Pause**.

| Champ | Défaut | Bornes et règles |
| --- | --- | --- |
| Nom du groupe | Tabata | Modifiable selon le contrat de nom. |
| Nombre de cycles (`rounds`) | 1 | 1 à 999. |
| Effort | 20 s | 1 s à 2 h 00 min 59 s. |
| Pause | 10 s | 1 s à 2 h 00 min 59 s. |
| Dernière pause personnalisée | `null` | 10 s à l'ajout, puis bornes usuelles. |

L'icône, le nom et le commentaire d'Effort sont modifiables avec le formulaire
d'exercice existant en mode contraint. Le choix Répétitions/Temps/Durée libre
et la durée du dialogue sont masqués. La durée reste modifiable dans la
section Effort. Le modèle impose toujours un exercice chronométré.

Effort et Pause ne sont ni supprimables ni réordonnables. Les actions
génériques **Exercice** et **Pause** sont masquées.

### Développement et durée

Pour trois cycles :

```text
Un groupe suit, sans personnalisation :
Effort → Pause → Effort → Pause → Effort → Pause → groupe suivant

Un groupe suit, avec personnalisation :
Effort → Pause → Effort → Pause → Effort → Pause finale → groupe suivant

Dernier groupe ou Session rapide :
Effort → Pause → Effort → Pause → Effort
```

La dernière pause personnalisée remplace la dernière occurrence de la pause
normale ; elle n'ajoute pas une occurrence. Si aucun groupe ne suit, la
dernière pause planifiée est retirée, personnalisée ou non.

```text
Sans groupe suivant :
cycles × effort + (cycles - 1) × pause

Avec groupe suivant :
cycles × effort + (cycles - 1) × pause
  + (dernière pause personnalisée ?? pause normale)
```

Le groupe développe `2 × cycles` étapes lorsqu'un groupe suit et
`2 × cycles - 1` lorsqu'il termine la séance. Toutes les pauses développées
comptent dans la limite de 10 000 étapes.

Exemples pour 8 cycles de 20 s / 10 s :

- dernier groupe ou Session rapide : `03:50` ;
- un groupe suit avec la pause normale : `04:00`.

### Édition et résumé

```text
Nom du groupe                         Tabata
Type du groupe                        Tabata
Nombre de cycles                  [−]  8  [+]

Effort                                  00:20
────────────────────────────────────────────
Pause                                   00:10
────────────────────────────────────────────
[ Personnaliser la dernière pause ]

Temps total estimé                     03:50
```

Le bouton de dernière pause est visible uniquement dans une séance
enregistrée. Après activation, la pause est modifiable et supprimable. Sa
suppression restaure `null` et donc la pause normale pour le dernier cycle.

Résumé sans le mot « Mono » :

```text
Tabata
Tabata · 8 cycles · 03:50
```

### Exécution, notification et historique

Chaque occurrence Effort ou Pause reste une étape chronométrée ordinaire :

- fin d'Effort : signal configuré puis Pause suivante ;
- fin d'une Pause intermédiaire : signal configuré puis Effort suivant ;
- fin de la dernière Pause lorsqu'un groupe suit : signal puis groupe suivant ;
- dernière pause retirée : fin de l'Effort puis fin de séance.

Le runner affiche la phase **Effort** ou **Pause**, puis **Cycle x/y**. Le
checkpoint existant restaure l'index d'étape, le cycle et le temps restant.
L'historique contient les occurrences Effort et Pause réellement exécutées,
avec leur durée et leur statut habituels.

```text
                        Tabata
                         00:20
                         Effort
                       Cycle 3/8
```

## AMRAP

### Modèle et valeurs

Un groupe AMRAP contient exactement un `TrainingItem` exercice chronométré.
Sa durée est le chrono global AMRAP.

| Champ | Défaut | Bornes et règles |
| --- | --- | --- |
| Nom du groupe | AMRAP | Modifiable selon le contrat de nom. |
| Exercice | Effort | Icône, nom et commentaire modifiables. |
| Durée globale | `02:00` | `01:00` à `60:00` inclus. |
| Récupération après groupe | `null` | 1 minute à l'ajout, puis bornes usuelles. |

La durée accepte les minutes et les secondes dans l'intervalle inclusif. Le
type de l'exercice est verrouillé et sa durée se modifie uniquement avec le
sélecteur principal **Durée de l'AMRAP**.

L'AMRAP produit une seule étape chronométrée. Les tours sont des événements
internes à cette étape ; ils ne créent pas de `SessionStep` supplémentaires et
ne sont pas soumis à la limite des 10 000 étapes.

### Édition et résumé

```text
Nom du groupe                         AMRAP
Type du groupe                        AMRAP
Durée de l'AMRAP                02 min 00 s
Enregistrez chaque tour terminé pendant le temps imparti.

Effort
────────────────────────────────────────────
[ Ajouter une récupération après l'AMRAP ]

Temps total estimé                     02:00
```

Le crayon d'Effort ouvre le formulaire contraint partagé : icône, nom et
commentaire visibles ; type et durée masqués. La récupération est visible
uniquement dans une séance enregistrée.

Résumé :

```text
AMRAP
AMRAP · Effort · 02:00
```

### État d'exécution

Le runner affiche en priorité :

- le temps AMRAP restant ;
- le nombre de tours terminés ;
- la durée du tour courant ;
- **+ Tour terminé**, au même emplacement et dans le même style que le bouton
  existant de répétition effectuée.

```text
                        AMRAP
                        01:19

Tours terminés             3
Tour courant            00:05

                 [ + Tour terminé ]
Tour 3 enregistré · 00:41        Annuler
```

Transitions principales :

```text
En cours
├─ tour valide → tour enregistré → délai actif de 2 s → En cours
├─ Annuler → dernier tour réintégré au tour courant → En cours
├─ pause globale → En pause → reprise exacte → En cours
├─ expiration → tour partiel éventuel → Terminé
└─ précédente/suivante → tentative conservée → Incomplet

Incomplet ou Terminé, puis retour
└─ confirmation
   ├─ Annuler → groupe actuellement affiché
   └─ Recommencer → tentative effacée → tour 1, durée initiale
```

Un appui valide :

1. refuse un tour courant de zéro seconde ;
2. enregistre sa durée entière à la seconde ;
3. démarre immédiatement le tour suivant ;
4. désactive le bouton pendant deux secondes de temps actif ;
5. ignore tout autre appui pendant la même seconde.

La pause globale désactive le bouton et suspend son délai de réactivation. Le
bouton revient après deux secondes effectivement actives, pas deux secondes de
temps mural.

### Annulation et limite

Le retour **Tour n enregistré · mm:ss — Annuler** reste disponible tant que
l'AMRAP est l'étape courante. **Annuler** retire uniquement le dernier tour
terminé et additionne sa durée au tour courant.

Exemple : un tour de 41 s est annulé après 5 s dans le suivant ; le tour
courant devient `00:46`. L'action disparaît en quittant le groupe ou à
l'expiration.

Le nombre de tours terminés est limité à 999. Après le 999e :

- le bouton reste désactivé jusqu'à la fin ;
- le message **Limite de 999 tours atteinte** est affiché ;
- le chrono continue normalement ;
- le temps restant devient le tour partiel final.

### Expiration et navigation

À l'expiration, le tour courant n'est pas compté comme terminé. S'il est
supérieur à zéro seconde, il est conservé comme **Tour partiel**. Si
l'utilisateur n'a jamais appuyé sur le bouton, l'historique contient zéro tour
terminé et un tour partiel égal à toute la durée active.

Les commandes précédente/suivante passent au groupe précédent/suivant. Un
départ anticipé conserve les tours terminés et le partiel, puis marque le
groupe incomplet.

Tout retour vers un AMRAP commencé ou terminé demande :

```text
Recommencer l'AMRAP ?
Les tours enregistrés pour cette tentative seront supprimés.

[ Annuler ]                         [ Recommencer ]
```

**Annuler** laisse affiché le groupe depuis lequel la navigation a été
demandée. **Recommencer** efface tours et partiel, remet le chrono à sa durée
initiale et démarre au tour 1. La confirmation s'applique aussi à un AMRAP
arrivé naturellement à expiration puis revisité avant la fin de la séance.

### Pause, checkpoint et historique

La pause globale suspend le chrono global, le tour courant et le délai du
bouton. Le temps en pause n'est inclus dans aucune durée AMRAP.

Le checkpoint conserve :

- la durée AMRAP configurée ;
- le temps actif global écoulé et restant ;
- les durées ordonnées des tours terminés ;
- la durée du tour courant ;
- le délai actif restant avant réactivation du bouton ;
- le statut commencé, terminé ou incomplet.

La reprise restaure exactement ces valeurs. Les durées sont enregistrées à la
seconde, comme les checkpoints actuels.

Le détail d'historique affiche le nombre de tours terminés, une ligne
`Tour n · mm:ss` par tour, puis `Tour partiel · mm:ss` seulement si sa durée
est positive. La somme des tours et du partiel est égale au temps actif
réellement passé dans l'AMRAP, hors pauses globales. La récupération apparaît
comme une pause classique uniquement si elle a été exécutée.

Un signal son ou vibration est émis uniquement à l'expiration et selon la
préférence existante. Aucun signal n'est émis si le mode est désactivé.

## EMOM

### Modèle et valeurs

Un groupe EMOM contient exactement un exercice chronométré d'une durée fixe de
60 secondes.

| Champ | Défaut | Bornes et règles |
| --- | --- | --- |
| Nom du groupe | EMOM | Modifiable selon le contrat de nom. |
| Exercice | Effort | Icône, nom et commentaire modifiables. |
| Nombre de minutes (`rounds`) | 10 | 1 à 60. |
| Intervalle | 60 s | Fixe et non éditable. |
| Récupération après groupe | `null` | 1 minute à l'ajout, puis bornes usuelles. |

Il n'existe ni validation anticipée ni pause interne. L'utilisateur effectue
l'exercice, puis utilise le temps restant de la minute comme récupération.

### Développement et navigation

```text
Minute 1 · Effort · 60 s
→ signal configuré
Minute 2 · Effort · 60 s
→ signal configuré
…
Minute x · Effort · 60 s
→ récupération éventuelle si un groupe suit
```

Le groupe développe une étape par minute, plus la récupération uniquement si
un groupe suit. Ces étapes comptent dans la limite de 10 000.

À zéro, la minute se termine naturellement et le moteur avance. Précédente ou
suivante démarre la minute de destination à 60 secondes. La minute quittée est
incomplète. Revenir sur une minute auparavant terminée la rend à nouveau
incomplète jusqu'à sa prochaine fin naturelle.

### Édition, runner et historique

```text
Nom du groupe                          EMOM
Type du groupe                         EMOM
Nombre de minutes                 [−]  10  [+]
L'exercice redémarre automatiquement au début de chaque minute.

Effort                      60 s, intervalle fixe
────────────────────────────────────────────
[ Ajouter une récupération après l'EMOM ]

Temps total estimé                     10:00
```

Le formulaire contraint d'Effort affiche icône, nom et commentaire, mais
masque type et durée. La récupération est visible uniquement dans une séance
enregistrée.

Le runner affiche **Minute x/y** et le temps restant dans la minute. Un signal
est émis à chaque fin de minute selon la préférence existante. La pause globale
et la notification persistante conservent leur comportement actuel.

```text
                         EMOM
                         00:37
                      Minute 4/10
                         Effort
```

Le détail d'historique contient une ligne par minute avec son index, sa durée
réelle et son statut terminé/incomplet. La récupération exécutée apparaît
comme une pause classique.

Résumé :

```text
EMOM
EMOM · Effort · 10:00
```

## Session rapide

La destination de navigation s'appelle **Rapide** et l'écran
**Session rapide**. Le type Tabata est sélectionné au premier affichage afin de
préserver l'usage de Quick Tabata.

| Type choisi | Valeurs initiales spécifiques |
| --- | --- |
| Libre | Valeurs par défaut de l'ajout d'un groupe Libre. |
| Répétitions variables | Valeurs par défaut de l'ajout d'un groupe variable. |
| Tabata | Tabata / Effort 20 s / Pause 10 s / 1 cycle. |
| AMRAP | AMRAP / Effort / `02:00`. |
| EMOM | EMOM / Effort / 10 minutes / intervalle fixe 60 s. |

Les récupérations après groupe ne sont jamais affichées. La dernière pause du
Tabata n'est pas exécutée, car aucun groupe ne suit.

Le lancement :

1. valide le même contrôleur que l'ajout de groupe ;
2. construit une `Training` temporaire uniquement en mémoire ;
3. passe par le gate de permissions existant ;
4. utilise `TrainingChangesPersistence.memoryOnly` ;
5. protège contre le double lancement avec **Préparation…** ;
6. n'écrit jamais dans **Mes entraînements** ;
7. écrit le résultat normal ou anticipé dans l'historique.

Une aide discrète indique : **Cette session ne sera pas enregistrée dans Mes
entraînements**. Quitter après une modification reprend la protection contre
les modifications non enregistrées, avec un texte adapté au contexte rapide.

## Notifications et annonces accessibles

| Événement | Signal son/vibration | Annonce d'interface |
| --- | --- | --- |
| Fin d'un Effort ou d'une Pause Tabata | Selon la préférence | Phase suivante et cycle. |
| Fin d'un AMRAP | Selon la préférence | Fin du temps imparti et total des tours. |
| Tour AMRAP enregistré | Aucun signal imposé | Retour accessible avec durée et Annuler. |
| Fin d'une minute EMOM | Selon la préférence | Minute suivante. |
| Fin d'une récupération de transition | Selon la préférence existante | Groupe suivant. |
| Mode désactivé | Aucun son ni vibration | L'état visuel reste disponible. |

Le chrono n'est jamais annoncé à chaque seconde par un lecteur d'écran. Les
annonces se limitent aux transitions et alertes utiles.

## Persistance et compatibilité

### Définition des entraînements

`GroupType` reçoit les valeurs stables `tabata`, `amrap` et `emom`. Aucun champ
de mode Mono/Multi n'est ajouté.

Le modèle de groupe transporte :

- Tabata : `rounds`, deux `items` et une durée optionnelle de dernière pause,
  par exemple `finalRestDuration` ;
- AMRAP : un item Effort dont la durée est le chrono global et une récupération
  optionnelle, par exemple `postGroupRestDuration` ;
- EMOM : `rounds`, un Effort fixe de 60 s et la même récupération optionnelle.

Les noms définitifs des champs Dart et JSON sont centralisés par #158, mais
leur sémantique ne doit pas changer. Les brouillons des types visités ne sont
jamais persistés.

### Format d'export

L'ajout de nouveaux types, champs de transition et données d'historique change
le schéma complet. RepTimer 1.4.0 écrit donc exclusivement des sauvegardes
**v3**.

- les anciens exports v1 restent importables par le chemin additif ;
- les sauvegardes v2 restent restaurables ;
- les données 1.3.2 sans nouveaux champs restent lisibles ;
- un format futur inconnu est refusé avant toute mutation ;
- une donnée Tabata, AMRAP ou EMOM incomplète ou incompatible est refusée ;
- validation et écriture restent transactionnelles et défensives.

La sauvegarde transporte les groupes éditables et l'historique, jamais les
étapes développées ni le checkpoint courant, conformément au contrat actuel.

### Historique et checkpoint

Les structures actuelles sont étendues de manière rétrocompatible : l'absence
des nouveaux champs dans une ancienne entrée conserve le comportement existant.

- Tabata utilise les snapshots ordinaires de ses étapes ;
- EMOM identifie chaque minute et son statut ;
- AMRAP transporte les tours ordonnés, le partiel optionnel et le temps actif ;
- le checkpoint AMRAP reste local et ajoute son état interne exact ;
- les listes et objets ajoutés sont copiés profondément.

## Validation par type

| Type | Structure invalide |
| --- | --- |
| Libre | Compteur ou item invalide selon les règles actuelles. |
| Répétitions variables | Suite vide, valeur hors bornes ou item incompatible selon les règles actuelles. |
| Tabata | Pas exactement Effort chronométré puis Pause, cycles hors bornes ou durée invalide. |
| AMRAP | Pas exactement un Effort chronométré, durée hors `01:00`–`60:00`, tour nul, plus de 999 tours ou somme incohérente. |
| EMOM | Pas exactement un Effort de 60 s ou nombre de minutes hors 1–60. |

Une récupération optionnelle n'est pas représentée par une durée de zéro :
elle est soit absente (`null`), soit valide selon les bornes de durée.

## Accessibilité et adaptation

- cible tactile minimale de 48 dp ;
- état jamais communiqué uniquement par la couleur ;
- erreurs inline annoncées en `liveRegion`, avec synthèse et focus sur la
  première erreur ;
- bouton final entièrement visible à 360 × 640 lorsque le contenu le permet ;
- défilement de secours pour clavier, petit écran ou texte agrandi ;
- `Wrap` ou disposition adaptative sans texte essentiel tronqué ;
- fonctionnement en thèmes clair et sombre ;
- orientation portrait ;
- bouton désactivé accompagné d'une raison compréhensible ;
- aucun double lancement ou double enregistrement de tour.

## Scénarios d'acceptation

### Éditeur et conversion

1. Ajouter chacun des cinq types puis l'enregistrer avec une configuration
   valide.
2. Changer d'un type existant vers Tabata, AMRAP ou EMOM, annuler la
   confirmation et vérifier l'absence de mutation.
3. Continuer, modifier le nouveau brouillon, revenir à l'ancien type et
   retrouver son brouillon exact.
4. Enregistrer et vérifier que seul le type sélectionné est persisté.
5. Vérifier la récupération avec un groupe suivant, puis son absence en fin de
   séance et en Session rapide.

### Tabata

1. Développer 1 puis plusieurs cycles avec et sans groupe suivant.
2. Remplacer la dernière Pause par la pause personnalisée sans créer d'étape.
3. Vérifier `03:50` pour 8 cycles de 20 s / 10 s en dernier groupe.
4. Suspendre et reprendre au milieu d'un Effort puis d'une Pause.
5. Restaurer le checkpoint sans décalage de phase ni de cycle.

### AMRAP

1. Valider `01:00`, `02:00`, une durée avec secondes et `60:00`, puis refuser
   les valeurs extérieures.
2. Enregistrer plusieurs tours, refuser un tour nul et un double appui.
3. Vérifier la réactivation après deux secondes actives, pause globale exclue.
4. Annuler un tour de 41 s après 5 s et obtenir un tour courant de 46 s.
5. Atteindre 999 tours, continuer le chrono et obtenir un partiel final.
6. Expirer sans appui et obtenir zéro tour terminé plus un partiel complet.
7. Quitter avant la fin, vérifier le statut incomplet, puis annuler ou confirmer
   le redémarrage au retour.
8. Restaurer un checkpoint pendant un tour et pendant le délai du bouton.
9. Vérifier que somme des tours et partiel égale le temps actif.

### EMOM

1. Exécuter 1, 10 et 60 minutes avec passage automatique à zéro.
2. Naviguer vers une autre minute et vérifier le redémarrage à 60 s et le
   statut incomplet de la minute quittée.
3. Suspendre puis restaurer au milieu d'une minute.
4. Vérifier une ligne d'historique par minute.

### Session rapide

1. Configurer et lancer chacun des cinq types avec l'éditeur partagé.
2. Vérifier les valeurs Tabata, AMRAP et EMOM par défaut.
3. Vérifier qu'aucune récupération après groupe n'est proposée.
4. Terminer ou interrompre la session et retrouver son historique.
5. Vérifier qu'aucun entraînement n'a été créé.
6. Vérifier le double appui, les erreurs, 360 × 640, le texte agrandi et les
   thèmes clair/sombre.

## Répartition des issues

| Issue | Responsabilité |
| --- | --- |
| #157 | Garde-fous bloquants de taille et couverture. |
| #158 | Modèle, JSON, export v3, import et compatibilité. |
| #159 | Développement des étapes, états temporisés et checkpoints. |
| #160 | Éditeur partagé, contextes, brouillons et validations UX. |
| #161 | Parcours complet Tabata. |
| #162 | Parcours complet AMRAP. |
| #163 | Parcours complet EMOM. |
| #164 | Remplacement de Quick Tabata par Session rapide. |

Chaque issue fonctionnelle livre ses tests unitaires et widget. Tous les
fichiers Dart suivis sous `lib/` restent sous 200 lignes, la couverture globale
reste au moins à 91,78 % et les lignes nouvelles ou modifiées atteignent au
moins 90 % lorsque ce calcul est disponible.
