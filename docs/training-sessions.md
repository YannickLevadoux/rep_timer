# Créer et exécuter des séances

RepTimer organise une séance en groupes. Les groupes Libre et Répétitions
variables contiennent des exercices et des pauses réordonnables. Les groupes
Tabata, AMRAP et EMOM proposent une structure chronométrée dédiée.

## Contrats de saisie

Les mêmes règles sont appliquées lors de l'édition, de l'import et avant le
lancement d'une séance :

- les noms sont obligatoires, limités à 50 caractères visibles et à une ligne ;
- les commentaires sont facultatifs, limités à 200 caractères visibles et à
  trois lignes ;
- les nombres de tours et de répétitions sont compris entre 1 et 999 ; un
  Tabata accepte de 1 à 99 tours et de 1 à 999 cycles par tour ;
- les exercices et pauses chronométrés durent de 1 seconde à 2 h 00 min 59 s ;
- une séance ne peut pas dépasser 10 000 étapes après développement des tours.

RepTimer affiche l'erreur près de la saisie concernée. Une valeur hors limite
n'est ni bornée, ni tronquée, ni enregistrée silencieusement.

## Créer ou modifier une séance

Depuis l'accueil, créer une séance ou ouvrir une séance existante pour la
modifier :

1. renseigner le nom de la séance ;
2. utiliser **Ajouter un groupe**, puis choisir l'un des cinq types proposés,
   ou toucher le crayon d'un groupe existant pour le modifier ;
3. renseigner le nom et les paramètres propres au groupe ;
4. pour un groupe Libre ou Répétitions variables, ajouter des exercices ou des
   pauses puis les réordonner avec leur poignée ; pour un Tabata, configurer
   les tours et ouvrir **Modifier les exercices** pour éditer ses cycles ;
5. enregistrer le groupe, puis la séance.

Avant le choix du type, aucun formulaire ni bouton d'ajout n'est affiché. Le
bouton d'aide placé près du sélecteur présente les cinq types. Quitter à ce
stade ne demande aucune confirmation.

Un exercice peut être défini en **Répétitions**, **Temps** ou **Durée libre**.
Quitter un éditeur contenant des modifications ouvre un choix permettant de
les enregistrer, de les abandonner ou de rester dans l'éditeur.

## Groupe libre

Le type **Groupe libre** exécute la même liste d'éléments pendant le nombre de
tours choisi. Chaque exercice en mode Répétitions conserve son propre nombre
de répétitions.

## Groupe à répétitions variables

Le type **Groupe à répétitions variables** remplace le nombre de tours par une
suite ordonnée. Sa longueur détermine le nombre de tours et chaque valeur
détermine les répétitions des exercices en mode Répétitions pour ce tour.

Pour créer ou modifier cette suite :

1. sélectionner **Groupe à répétitions variables** dans **Type du groupe** ;
2. toucher le bouton qui résume la suite ;
3. utiliser **Ajouter un tour**, saisir une valeur de 1 à 999, puis réordonner
   les lignes avec leur poignée si nécessaire ;
4. supprimer les lignes inutiles, tout en conservant au moins un tour ;
5. choisir **Valider**, puis enregistrer le groupe.

Par exemple, la suite `10, 12, 15, 12, 10` crée cinq tours. À chacun de ces
tours, tous les exercices en mode Répétitions reçoivent la valeur
correspondante. Les exercices **Temps**, les exercices **Durée libre** et les
pauses gardent leur comportement habituel : un groupe peut donc être mixte.

**Annuler** ferme l'éditeur de suite sans appliquer sa modification. De même,
les changements du groupe restent transactionnels tant que celui-ci n'a pas
été enregistré.

## Groupe Tabata

Un Tabata rejoue pendant 1 à 99 tours la même liste ordonnée de 1 à 999 cycles.
Chaque cycle correspond à un exercice chronométré possédant son propre nom,
son icône et son commentaire facultatif. La durée des efforts est commune à
tous les exercices : elle vaut 20 secondes par défaut. La liste reste l'unique
source du nombre et de l'ordre des cycles.

**Modifier les exercices** ouvre un brouillon permettant d'ajouter, supprimer
et réordonner les cycles sans modifier le groupe avant **Valider**. Les
nouveaux noms suivent la préférence de préremplissage. Les lignes compactes de
pause ouvrent le même dialogue **Modifier la pause** : la pause entre cycles
vaut 10 secondes par défaut et ne peut pas être supprimée.

La pause de fin de tour remplace toujours la pause normale après le dernier
cycle ; elle ne s'y ajoute jamais. Elle est facultative et supprimable avec un
seul tour. À partir de deux tours, elle devient obligatoire et, si nécessaire,
est initialisée avec la pause entre cycles. Sa valeur est conservée lors d'un
retour à un tour.

Après le dernier exercice du dernier tour, aucune pause n'est exécutée si le
Tabata termine la séance ou constitue une Session rapide. Si un autre groupe
suit, la pause de fin de tour résolue assure la transition. Par exemple, un
tour de huit cycles avec 20 secondes d'effort et 10 secondes de pause dure
`03:50` lorsqu'il termine la séance.

## Groupe AMRAP

Un AMRAP contient un seul effort chronométré de `01:00` à `60:00`, avec
`02:00` par défaut. Pendant l'exécution :

1. toucher **+ Tour terminé** à la fin de chaque tour ;
2. utiliser **Annuler** pour réintégrer le dernier tour au tour en cours ;
3. laisser le chrono arriver à zéro pour conserver la durée du tour courant
   comme **Tour partiel**.

Le bouton refuse les tours de zéro seconde et reste indisponible pendant deux
secondes actives après un ajout. Un maximum de 999 tours terminés est conservé.
La pause globale suspend le chrono du groupe, celui du tour courant et ce délai.

Quitter l'AMRAP avant son expiration conserve la tentative comme incomplète.
Revenir vers un AMRAP déjà commencé ou terminé demande confirmation avant de
supprimer ses tours et de le recommencer.

## Groupe EMOM

Un EMOM relance automatiquement le même effort au début de chaque minute. Le
nombre de minutes est compris entre 1 et 60, avec 10 par défaut, et chaque
intervalle dure exactement 60 secondes. RepTimer n'insère aucune pause dans la
minute : le temps restant sert librement de récupération.

La progression affiche **Minute x/y**. Une notification peut signaler chaque
nouvelle minute selon le mode Son, Vibration ou Rien. Une minute quittée
manuellement est marquée incomplète ; y revenir redémarre son chrono à 60
secondes.

## Récupération après un groupe

Une récupération facultative peut être ajoutée après un AMRAP ou un EMOM. Le
Tabata utilise sa pause de fin de tour, personnalisée ou repliée sur la pause
entre cycles avec un seul tour. Ces transitions sont exécutées uniquement si
un autre groupe suit et ne sont pas proposées en Session rapide.

## Changer le type sans perdre la configuration

Le passage vers un groupe variable conserve en mémoire le nombre de tours et
les répétitions propres aux exercices. Le retour vers un groupe libre conserve
la suite variable. Un nouvel aller-retour retrouve donc les valeurs précédentes
au lieu de reconstruire ou d'écraser la configuration.

Lors du premier passage d'un ancien groupe libre vers le type variable,
RepTimer initialise la suite à partir du nombre de tours et d'une répétition
valide déjà présente dans le groupe. Cette proposition peut ensuite être
modifiée librement.

Le passage vers ou depuis Tabata, AMRAP ou EMOM peut remplacer une structure
incompatible. RepTimer demande alors confirmation. Pendant la même édition,
chaque type visité conserve son propre brouillon ; annuler ne modifie jamais le
groupe enregistré.

## Lancer une Session rapide

La destination **Rapide** permet d'exécuter un seul groupe sans créer
d'entraînement dans **Mes entraînements** :

1. choisir Libre, Répétitions variables, Tabata, AMRAP ou EMOM ;
2. configurer le groupe avec le même éditeur que dans une séance enregistrée ;
3. toucher **Commencer**.

La session est construite uniquement en mémoire. Le Tabata rapide utilise le
même modèle, les mêmes tours, la même liste d'exercices et le même moteur que
le Tabata enregistré. Aucune récupération finale n'est proposée puisqu'aucun
groupe ne suit, mais une fin normale ou anticipée est toujours conservée dans
l'historique.

## Préparer le départ

Dans **Paramètres**, section **Séance**, le **Compte à rebours** peut être réglé
de 0 à 15 secondes. La valeur 0 le désactive. Pour une nouvelle séance
enregistrée ou rapide, l'écran affiche **Prêt ?** avant le premier exercice.

Le décompte peut être mis en pause, repris ou passé avec **Suivant**. Un passage
en arrière-plan le met en pause jusqu'à une reprise explicite. Selon le mode de
notification, un signal est émis à 3, 2 et 1 seconde puis au démarrage.

Cette préparation ne compte dans aucun chrono, historique, checkpoint,
statistique ou estimation. Elle n'est jamais rejouée lors de la reprise d'une
séance interrompue.

## Exécuter et reprendre une séance

L'écran de résumé présente le type et la durée estimée de chaque groupe. Pendant
un Tabata à plusieurs tours, le runner et la Progression affichent par exemple
**Tour 1/2 · Cycle 3/4** ; avec un seul tour, **Cycle 3/4** suffit. Les autres
types conservent leur tour ou leur minute selon leur contrat.

Les commentaires modifiés pendant l'exécution restent attachés à l'exercice
d'origine. En cas d'interruption, le checkpoint permet de reprendre au bon
groupe et à la bonne occurrence, notamment au bon tour, au bon cycle et dans la
bonne phase d'un Tabata. Pour un AMRAP, il restaure aussi les tours, le tour
courant, le temps restant et le délai du bouton. À la fin, l'historique
conserve les métadonnées de tour et de cycle Tabata ainsi que les répétitions,
tours et minutes réellement exécutés.
