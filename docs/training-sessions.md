# Créer et exécuter des séances

RepTimer organise une séance en groupes. Chaque groupe contient des exercices
et des pauses réordonnables, puis répète cette liste selon le type choisi.

## Contrats de saisie

Les mêmes règles sont appliquées lors de l'édition, de l'import et avant le
lancement d'une séance :

- les noms sont obligatoires, limités à 50 caractères visibles et à une ligne ;
- les commentaires sont facultatifs, limités à 200 caractères visibles et à
  trois lignes ;
- les nombres de tours et de répétitions sont compris entre 1 et 999 ;
- les exercices et pauses chronométrés durent de 1 seconde à 2 h 00 min 59 s ;
- une séance ne peut pas dépasser 10 000 étapes après développement des tours.

RepTimer affiche l'erreur près de la saisie concernée. Une valeur hors limite
n'est ni bornée, ni tronquée, ni enregistrée silencieusement.

## Créer ou modifier une séance

Depuis l'accueil, créer une séance ou ouvrir une séance existante pour la
modifier :

1. renseigner le nom de la séance ;
2. utiliser **Ajouter un groupe**, ou toucher le crayon d'un groupe existant ;
3. renseigner le nom et le type du groupe ;
4. ajouter des exercices ou des pauses, puis les réordonner avec leur poignée ;
5. enregistrer le groupe, puis la séance.

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

## Changer le type sans perdre la configuration

Le passage vers un groupe variable conserve en mémoire le nombre de tours et
les répétitions propres aux exercices. Le retour vers un groupe libre conserve
la suite variable. Un nouvel aller-retour retrouve donc les valeurs précédentes
au lieu de reconstruire ou d'écraser la configuration.

Lors du premier passage d'un ancien groupe libre vers le type variable,
RepTimer initialise la suite à partir du nombre de tours et d'une répétition
valide déjà présente dans le groupe. Cette proposition peut ensuite être
modifiée librement.

## Exécuter et reprendre une séance

L'écran de résumé présente le type de chaque groupe et, pour un groupe
variable, sa suite. Pendant la séance, RepTimer affiche le tour courant, le
nombre total de tours et la répétition résolue pour l'exercice en cours.

Les commentaires modifiés pendant l'exécution restent attachés à l'exercice
d'origine. En cas d'interruption, le checkpoint permet de reprendre au bon
groupe, au bon tour et avec la bonne répétition. À la fin, l'historique conserve
les répétitions réellement associées à chaque étape.
