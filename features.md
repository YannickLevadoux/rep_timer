# RepTimer

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# ================================     T E C H   D E B T     ================================



# ================================     S T E P S     ================================

## ================================     T O   D O     ================================












## ================================     G R O O M I N G     ================================

### Session adhoc

** PAS PRET **
on génére un entrainement a la volée


### Quick Tabata


Ajout d'une fonctionnalité Quick Tabata
Depuis l'acceuil on ajoute une icone, entre "Acceuil" et "Historique".
Ce bouton envoi vers un nouvel un écran de préparation. Celui ci se compose de haut en bas :
- un nom, par defaut quick Tabata, modifiable  
- work : temps a saisir par l'utilisateur (réutiliser la fonctionnalité qui permet de mettre minute/secondes, defaut 20 sec)
- pause : temps a saisir par l'utilisateur (réutiliser la fonctionnalité qui permet de mettre minute/secondes, defaut 10 sec)
- repetition : nombre a remplir par l'utilisateur defaut 1
- Affichage du calcul a la volée le temps total : (work + pause) * repetition 
- un bouton Commencer 
quand on a cliqué sur Commencer , on génére une séance a la volée  
- un groupe nommé avec le nom précédement saisie, "quick Tabata" s'il na pas été modifié; 
- un exercice nommé "work" de type "Temps" avec la durée saisie dans le champs work;
- une pause avec la durée saisie dans le champs pause;
- un nombre de répétition correspondant au nombre saisie précédement
on garde le mode d'execution actuel;
a la fin on sauvegarde le tout dans l'historique, mais on ne sauvegarde pas la séance dans la liste des séance disponibles







## ================================     D O N E     ================================

### navigation pendant l'exécution d'une séance

Ajouter une fonctionnalité de navigation pendant l'exécution d'une séance ainsi que des améliorations sur l'écran de progression.

Écran d'exécution de la séance
Navigation entre les exercices

Ajouter deux boutons de navigation permettant de changer manuellement d'exercice :

un bouton Précédent à gauche du chronomètre ;
un bouton Suivant à droite du chronomètre.

Le comportement attendu est le suivant :

Précédent revient à l'exercice précédent de la séance ;
Suivant passe immédiatement à l'exercice suivant ;
la navigation doit respecter l'ordre réel de la séance, y compris les groupes et les pauses ;
le chronomètre et l'état de l'exercice doivent être mis à jour correctement après chaque navigation.
Affichage des répétitions

Pour les exercices basés sur un nombre de répétitions :

remplacer l'affichage "n répétitions" par le format "× n".
Écran de progression
Positionnement automatique

À l'ouverture de l'écran de progression :

positionner automatiquement la liste sur l'exercice actuellement en cours afin qu'il soit immédiatement visible.
Lancer un exercice spécifique

Permettre à l'utilisateur de démarrer directement n'importe quel exercice de la liste :

ajouter une action sur chaque exercice permettant de le lancer ;
avant de changer d'exercice, afficher une boîte de dialogue de confirmation indiquant que la progression actuelle sera modifiée ;
ne lancer le nouvel exercice qu'après confirmation de l'utilisateur.
Exercice en cours

Modifier l'affichage de l'exercice actuellement en cours :

supprimer l'icône Play ;
faire clignoter la ligne de l'exercice en cours en utilisant le même système d'animation que sur l'écran d'exécution ;
arrêter le clignotement lorsque la séance est en pause et le reprendre lorsque la séance reprend.
Contraintes
Conserver le fonctionnement actuel de la séance en dehors des modifications demandées.
Maintenir une navigation cohérente et synchronisée entre l'écran d'exécution et l'écran de progression.
Réutiliser autant que possible les composants et animations existants.
Produire un code propre, modulaire et maintenable.
Questions

Si un point n'est pas suffisamment défini, poser les questions avant d'implémenter plutôt que de faire des hypothèses.


### Arret de session / enregistrement historique

Modifier le comportement du menu de retour pendant l'exécution d'une séance afin de mieux gérer la fin anticipée d'un entraînement.

Menu de retour pendant une séance

Lorsque l'utilisateur appuie sur le bouton Retour pendant l'exécution d'une séance, afficher un menu proposant les trois actions suivantes :

Continuer la séance ;
Terminer la session ;
Abandonner.
Continuer la séance

Si l'utilisateur choisit Continuer la séance :

fermer le menu ;
reprendre la séance exactement là où elle était.
Terminer la session

Si l'utilisateur choisit Terminer la session :

arrêter immédiatement la séance ;
enregistrer la session dans l'historique ;
enregistrer les informations suivantes :
nom de la séance ;
date de réalisation ;
temps total écoulé depuis le début de la séance ;
statut Incomplète ;
quitter ensuite l'écran d'exécution ;
Afficher l'écran de fin seance (sans changement sur cet écran)

Abandonner

Si l'utilisateur choisit Abandonner :

quitter immédiatement la séance ;
ne créer aucun enregistrement dans l'historique ;
ne conserver aucune trace de cette session.
Fin normale de la séance

Lorsque la séance se termine normalement :

enregistrer automatiquement la session dans l'historique ;
enregistrer les informations suivantes :
nom de la séance ;
date de réalisation ;
temps total de la séance ;
statut Terminée.
Afficher l'écran de fin seance (sans changement sur cet écran)

Contraintes
Conserver le fonctionnement actuel du bouton Retour, en ajoutant uniquement la nouvelle option.
Utiliser le même mécanisme de sauvegarde de l'historique que celui déjà présent dans l'application.
Garantir qu'une séance n'est enregistrée qu'une seule fois dans l'historique.
Produire un code propre, modulaire et maintenable.
Questions

Si un point n'est pas suffisamment défini, poser les questions avant d'implémenter plutôt que de faire des hypothèses.


### Commentaires poids 

Ajouter une fonctionnalité de commentaires personnalisés sur les exercices.

Écran d'ajout / modification d'un exercice
Champ commentaire

Ajouter un champ texte optionnel permettant d'associer une note à un exercice.

Caractéristiques :

champ texte multiligne ;
optionnel ;
placeholder : "Poids, intensité...".
Sauvegarde

Lors de l'enregistrement de l'exercice :

sauvegarder le commentaire avec les autres données de l'exercice ;
utiliser le même mécanisme de stockage local que le reste de l'application.
Écran d'exécution de la séance
Affichage du commentaire

Si un commentaire est renseigné pour l'exercice en cours :

l'afficher sous le nom de l'exercice ;
utiliser une taille de texte plus petite que le titre de l'exercice ;
intégrer ce texte à l'animation existante : il doit clignoter en même temps que le nom et l'icône de l'exercice.

Si aucun commentaire n'est renseigné :

ne rien afficher.
Modification pendant la séance

Permettre de modifier le commentaire directement pendant l'exécution de la séance.

Comportement attendu :

afficher une icône crayon à côté du commentaire ;
un clic sur cette icône passe le commentaire en mode édition ;
afficher les boutons Valider et Annuler.
Valider
enregistrer immédiatement la modification ;
utiliser le même mécanisme de sauvegarde locale que le reste des données de l'application ;
mettre à jour l'affichage sans quitter la séance.
Annuler
abandonner les modifications ;
restaurer le commentaire précédent.
Contraintes
Le commentaire est propre à chaque exercice.
La modification effectuée pendant une séance doit être persistée localement et réutilisée lors des prochaines séances.
Réutiliser les composants existants lorsque cela est pertinent.
Produire un code propre, modulaire et maintenable.
Questions

Si un point n'est pas suffisamment défini, poser les questions avant d'implémenter plutôt que de faire des hypothèses.





### Ecran historique

Créer un écran Historique permettant de consulter les séances d'entraînement réalisées.

Écran Historique

Créer un écran respectant le thème graphique actuel de l'application.
Cet écran sera a brancher sur le bouton historique de main

Affichage initial

Au chargement de l'écran :

afficher uniquement les 5 séances les plus récentes ;
trier les éléments du plus récent au plus ancien.
Informations affichées

Pour chaque élément de l'historique, afficher :

le nom de la séance ;
la date de réalisation ;
le temps total passé sur la séance ;
le statut de la séance :
Terminée : afficher une coche verte ;
Incomplète : afficher une icône représentant une séance partielle.
Suppression d'un élément

Permettre de supprimer un élément de l'historique.

Comportement attendu :

afficher une icône corbeille alignée à droite de chaque élément ;
au clic, afficher une boîte de dialogue de confirmation ;
ne supprimer l'élément qu'après confirmation de l'utilisateur ;
mettre la liste à jour immédiatement après la suppression.
Chargement de l'historique complet

En bas de l'écran, ajouter un bouton "Tout Visualiser".

Au clic :

charger l'ensemble des éléments de l'historique ;
conserver le tri du plus récent au plus ancien ;
remplacer la liste initiale limitée à 5 éléments par la liste complète.
Contraintes
Respecter le thème graphique existant.
Réutiliser le mécanisme de stockage local déjà utilisé pour l'historique.
Mettre à jour automatiquement l'affichage après toute suppression.
Produire un code propre, modulaire et maintenable.
Questions

Si un point n'est pas suffisamment défini, poser les questions avant d'implémenter plutôt que de faire des hypothèses.




### Ecran Main

Modifier l'interaction avec la liste des séances sur l'écran d'accueil afin de simplifier l'interface.

Écran d'accueil
Suppression des actions actuelles

Pour chaque séance de la liste :

supprimer les boutons d'action actuellement affichés (Play, Édition) ;
supprimer le comportement qui ouvre directement l'édition lorsqu'un utilisateur clique sur une séance.
Nouvelle interaction

Lorsqu'un utilisateur clique sur une séance :

développer uniquement cette séance ;
afficher deux boutons directement sous le nom de la séance.

Les boutons sont :

Commencer
Éditer
Bouton "Commencer"

Au clic :

lancer immédiatement la séance en mode exécution ;
utiliser exactement le même comportement que l'ancien bouton Play.
Bouton "Éditer"

Au clic :

ouvrir l'écran d'édition de la séance ;
utiliser exactement le même comportement que l'ancien bouton Crayon.
Comportement de la liste
Une seule séance peut être développée à la fois.
Si l'utilisateur sélectionne une autre séance, refermer la précédente et développer la nouvelle.
Un second clic sur la séance déjà développée referme les boutons d'action.
Contraintes
Conserver le fonctionnement actuel des actions Commencer et Éditer.
Modifier uniquement leur mode d'accès.
Respecter le thème graphique existant.
Produire un code propre, modulaire et maintenable.
Questions

Si un point n'est pas suffisamment défini, poser les questions avant d'implémenter plutôt que de faire des hypothèses.



### Sauvegarde séance

Modifier le fonctionnement de l'écran d'édition d'une séance afin de gérer correctement les modifications non enregistrées.

Écran d'édition d'une séance
Gestion des modifications

Les modifications effectuées pendant l'édition ne doivent pas être enregistrées automatiquement.

Le comportement attendu est le suivant :

toutes les modifications restent uniquement en mémoire tant que l'utilisateur est sur l'écran d'édition ;
aucune modification ne doit être persistée localement avant une action explicite de l'utilisateur.
Enregistrement

Les modifications doivent être sauvegardées localement uniquement lorsque l'utilisateur clique sur le bouton Enregistrer.

À ce moment :

enregistrer l'ensemble des modifications ;
utiliser le mécanisme de stockage local déjà présent dans l'application.
Gestion du bouton Retour

Lorsque l'utilisateur appuie sur le bouton Retour, deux cas sont possibles.

Aucun changement

Si aucune modification n'a été effectuée depuis l'ouverture de l'écran :

revenir directement à l'écran d'accueil ;
ne rien enregistrer.
Modifications en attente

Si une ou plusieurs modifications ont été effectuées sans avoir été enregistrées :

afficher une boîte de dialogue de confirmation ;
proposer les actions suivantes :
Enregistrer ;
Abandonner les modifications ;
Annuler.
Enregistrer
sauvegarder les modifications ;
revenir à l'écran d'accueil.
Abandonner les modifications
ignorer toutes les modifications effectuées depuis l'ouverture de l'écran ;
restaurer les données initiales ;
revenir à l'écran d'accueil.
Annuler
fermer la boîte de dialogue ;
rester sur l'écran d'édition sans perdre les modifications en cours.
Contraintes
Détecter correctement toute modification (ajout, suppression, renommage, réorganisation, changement de paramètres, etc.).
Ne jamais enregistrer automatiquement une modification avant un clic sur Enregistrer.
Réutiliser le mécanisme de stockage local existant.
Produire un code propre, modulaire et maintenable.
Questions

Si un point n'est pas suffisamment défini, poser les questions avant d'implémenter plutôt que de faire des hypothèses.



### Fonctionnalité de choix des icones

Ajouter la possibilité de personnaliser l'icône de chaque exercice.

Écran d'édition d'une séance
Sélection d'une icône

Pour chaque exercice, permettre à l'utilisateur de choisir une icône personnalisée parmi une liste prédéfinie de la classe Icons.

Affichage

En haut de l'écran d'édition de l'exercice :

afficher l'icône actuellement sélectionnée ;
par défaut, afficher fitness_center.
Changement d'icône

Lorsque l'utilisateur clique sur l'icône :

ouvrir une galerie d'icônes ;
afficher uniquement les icônes de la liste prédéfinie ci-dessous ;
permettre la sélection d'une seule icône ;
permettre un bouton annuler pour fermer la galerie sans changement ;
fermer la galerie après la sélection ;
mettre immédiatement à jour l'aperçu de l'icône.
Sauvegarde

L'icône sélectionnée doit être enregistrée avec les autres données de l'exercice en utilisant le mécanisme de stockage local existant.

Réutilisation de l'icône

L'icône personnalisée doit être utilisée partout où l'exercice est affiché, notamment :

sur l'écran de prévisualisation de la séance ;
sur l'écran d'exécution de la séance ;
sur l'écran de progression ;
et sur tout autre écran affichant un exercice.

Si aucune icône n'a été choisie, utiliser fitness_center comme valeur par défaut.

Liste des icônes disponibles

Utiliser exclusivement les icônes suivantes de la classe Icons :

fitness_center
rowing
directions_run
directions_bike
directions_walk
monitor_heart
sports
sports_gymnastics
sports_martial_arts
sports_score
accessibility_new
self_improvement
local_fire_department
leaderboard
emoji_events
star
bolt
flag
monitor_weight
Contraintes
L'icône est propre à chaque exercice.
Conserver fitness_center comme valeur par défaut pour les exercices existants et les nouveaux exercices.
Réutiliser la même icône sur tous les écrans afin de garantir une représentation cohérente de l'exercice.
Produire un code propre, modulaire et maintenable.
Questions

Si un point n'est pas suffisamment défini, poser les questions avant d'implémenter plutôt que de faire des hypothèses.


### Saisie du temps 

Améliorer l'ergonomie de la saisie des durées lors de la création et de la modification des exercices et des pauses.

Écran d'édition d'une séance
Nouvelle saisie des durées

Remplacer le champ actuel de saisie en secondes par deux champs distincts :

Minutes
Secondes

Conserver leur emplacement actuel dans l'interface, en affichant simplement les deux champs sur la même ligne.

Valeur par défaut

Pour tout nouvel exercice ou toute nouvelle pause :

initialiser la durée à 1 minute 30 secondes.
Interaction utilisateur

Chaque champ (Minutes et Secondes) doit proposer deux modes de saisie.

Défilement (Picker)
permettre de faire défiler les valeurs verticalement ;
les valeurs doivent défiler de manière fluide.

Plages de valeurs :

Minutes : de 0 à 120 ;
Secondes : de 0 à 59.
Saisie directe

Lorsque l'utilisateur clique sur un champ :

afficher le clavier numérique Android ;
permettre la saisie directe de la valeur ;
mettre à jour immédiatement le sélecteur après validation.
Stockage
Continuer à stocker les durées dans le format actuellement utilisé par l'application (par exemple en secondes), afin de ne pas impacter le reste du code.
La conversion entre minutes/secondes et le format interne doit être entièrement transparente.
Contraintes
Appliquer cette nouvelle interface aussi bien aux exercices basés sur une durée qu'aux pauses.
Conserver le comportement actuel de l'application en dehors de cette modification.
Garantir la cohérence entre le picker et la saisie clavier.
Produire un code propre, modulaire et maintenable.
Questions

Si un point n'est pas suffisamment défini, poser les questions avant d'implémenter plutôt que de faire des hypothèses.

Q: Pour le mode "défilement", quel type de picker utiliser ?
A: ListWheelScrollView personnalisé (même effet, sans dépendance Cupertino)

Q: Comment basculer entre le mode défilement et la saisie clavier ?
A: Le picker (roue) est toujours visible ; taper directement sur le nombre affiché fait apparaître un champ clavier par-dessus



### Nouveau type d'exercice

Ajouter un nouveau type d'exercice nommé Durée libre.

Nouveau type d'exercice

Créer un troisième type d'exercice :

Répétitions
Temps
Durée libre

Le principe de Durée libre est le suivant :

aucun temps n'est défini à l'avance ;
aucun nombre de répétitions n'est demandé ;
un chronomètre démarre au lancement de l'exercice afin de mesurer le temps réellement passé ;
l'utilisateur décide lui-même de la fin de l'exercice.
Écran de création / modification d'un exercice
Choix du type

Ajouter Durée libre à la liste des types d'exercice disponibles.

Les choix deviennent :

Répétitions
Temps
Durée libre
Paramètres

Lorsque Durée libre est sélectionné :

Demander le commentaires (toujours optionnel) ;
ne demander ni durée, ni nombre de répétitions.

Écran d'exécution de la séance
Affichage

Lorsqu'un exercice de type Durée libre est en cours :

afficher un chronomètre mesurant uniquement le temps écoulé sur cet exercice ;
démarrer automatiquement ce chronomètre au début de l'exercice ;
conserver la même présentation que les autres types d'exercices afin de préserver la cohérence de l'interface.
Fin de l'exercice

Ajouter un bouton Exercice effectué.

Au clic :

arrêter le chronomètre de l'exercice ;
passer immédiatement à l'exercice suivant de la séance.

Contraintes
Le chronomètre de l'exercice est indépendant du chronomètre global de la séance.
Conserver le fonctionnement actuel des exercices de type Temps et Répétitions.
Intégrer ce nouveau type partout où les types d'exercices sont gérés dans l'application.
Produire un code propre, modulaire et maintenable.
Questions

Si un point n'est pas suffisamment défini, poser les questions avant d'implémenter plutôt que de faire des hypothèses.


### nommage auto des exercices

Améliorer la création d'un nouvel exercice en préremplissant automatiquement son nom.

Écran d'édition d'une séance
Création d'un nouvel exercice

Lorsqu'un utilisateur ajoute un nouvel exercice dans un groupe :

préremplir automatiquement le champ Nom de l'exercice avec le nom du groupe auquel il appartient.

Exemple :

Groupe : Échauffement → Nom de l'exercice prérempli : Échauffement
Groupe : Pompes → Nom de l'exercice prérempli : Pompes
Modification du nom

Le nom proposé est uniquement une valeur par défaut.

L'utilisateur doit pouvoir :

modifier librement ce nom ;
le remplacer complètement ;
conserver le nom proposé s'il le souhaite.
Contraintes
Appliquer ce comportement uniquement lors de la création d'un nouvel exercice.
Ne pas modifier le nom des exercices existants.
Conserver le fonctionnement actuel de l'écran d'édition en dehors de cette amélioration.
Produire un code propre, modulaire et maintenable.
Questions

Si un point n'est pas suffisamment défini, poser les questions avant d'implémenter plutôt que de faire des hypothèses.



### Suppression par glissement

NB :Suppression par glissement a été supprimée poru éviter un écart entre android et linux

Prompt:

Ajouter une confirmation avant la suppression d'une séance depuis l'écran d'accueil.

Écran d'accueil
Suppression par glissement

Actuellement, lorsqu'une séance est supprimée par un geste de glissement (swipe), la suppression est effectuée immédiatement.

Modifier ce comportement afin d'ajouter une confirmation avant toute suppression.

Confirmation

Lorsqu'un utilisateur tente de supprimer une séance par glissement :

afficher une boîte de dialogue de confirmation ;
proposer les actions suivantes :
Supprimer ;
Annuler.
Supprimer
supprimer définitivement la séance ;
mettre à jour immédiatement la liste des séances.
Annuler
fermer la boîte de dialogue ;
annuler la suppression ;
conserver la séance dans la liste.
Cohérence
Utiliser la même boîte de dialogue, le même style et le même comportement que la confirmation déjà utilisée sur l'écran d'édition d'une séance.
Garantir une expérience utilisateur cohérente dans toute l'application.
Contraintes
Ne modifier que le comportement de la suppression par glissement.
Conserver le reste du fonctionnement de l'écran d'accueil.
Produire un code propre, modulaire et maintenable.
Questions

Si un point n'est pas suffisamment défini, poser les questions avant d'implémenter plutôt que de faire des hypothèses.


### Dropdown a remplacer 

Le menu déroulant (DropdownButton) fonctionne, mais pour seulement deux choix (Temps / Répétitions), Flutter propose un composant plus moderne et plus agréable : SegmentedButton (Material 3). Il est plus compact, plus intuitif sur mobile et s'intègre très bien au style de l'application. Je te conseille de l'adopter dès maintenant.

Réponse : 

Bonne réflexion, et je suis assez d'accord avec toi dans ce cas précis.
Pour SegmentedButton :

Avec seulement 3 options fixes (Répétitions / Temps / Durée libre), c'est exactement le cas d'usage que Material 3 recommande pour ce composant plutôt qu'un dropdown — toutes les options sont visibles d'un coup, pas besoin d'un tap supplémentaire pour ouvrir le menu et voir ce qui est disponible.
L'état sélectionné est visuellement plus clair (fond rempli) qu'un texte dans un dropdown fermé.
Ça change moins souvent qu'un champ de saisie libre, donc pas de perte à tout afficher d'un coup.

Le point de vigilance : ton dialogue (AlertDialog) a une largeur limitée, et tes libellés ("Répétitions", "Durée libre") sont plutôt longs. Sur un petit écran, 3 segments avec ces textes risquent soit de se tasser, soit de forcer un retour à la ligne dans chaque segment. Deux options pour éviter ça si tu passes au SegmentedButton :

Raccourcir les libellés ("Reps" / "Temps" / "Libre"), quitte à garder le nom complet ailleurs (tooltip, ou texte d'aide sous le sélecteur comme tu l'as déjà pour "Durée libre").
Ou n'afficher que des icônes dans les segments (icon: sans label:), avec un Tooltip par segment — très compact, mais un peu moins explicite au premier coup d'œil qu'un texte.

Globalement : oui, je pense que c'est une bonne amélioration ergonomique ici, à condition de traiter le rétrécissement des libellés pour que ça reste lisible sur mobile étroit. Dis-moi si tu veux que je l'implémente.

Choix : on laisse DropdownButton