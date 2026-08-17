# Importer, exporter et restaurer

Les actions se trouvent dans **Paramètres**, section **Import / Export**.
RepTimer reconnaît trois formats dont les effets sont volontairement différents.

| Fichier sélectionné | Action | Séances locales | Historique et préférences |
| --- | --- | --- | --- |
| Export v1 historique | Import additif | Conservées, les séances importées sont ajoutées avec de nouveaux identifiants | Inchangés |
| Sauvegarde v2 | Restauration complète rétrocompatible | Remplacées par celles de la sauvegarde | Historique et préférences remplacés ; compte à rebours remis à 0 |
| Sauvegarde v3 | Restauration complète après confirmation | Remplacées par celles de la sauvegarde | Historique et quatre préférences exportables remplacés |

## Exporter une sauvegarde v3

Choisir **Exporter** construit puis partage un fichier JSON v3 contenant :

- toutes les séances, y compris les groupes à répétitions variables et leurs
  valeurs dormantes ;
- tout l'historique ;
- le thème, le préremplissage du nom des exercices, le mode de notification et
  le compte à rebours de préparation de 0 à 15 secondes ;
- l'identifiant RepTimer, la version du format et la date d'export.

Le checkpoint d'une séance en cours, les permissions Android, l'exemption
batterie et les réglages techniques internes sont exclus. RepTimer valide
toutes les données avant de créer le fichier et refuse de présenter comme
complète une sauvegarde dont une partie n'a pas pu être lue.

Le schéma détaillé est décrit dans le [contrat de sauvegarde v3](backup-v3.md).
Depuis RepTimer 1.3.0, l'application ne crée plus d'export v1.

## Importer un ancien fichier v1

Choisir **Importer**, puis sélectionner un export v1 ajoute uniquement ses
séances à la liste existante. RepTimer attribue de nouveaux identifiants aux
séances et groupes importés afin d'éviter les collisions.

Ce chemin ne modifie ni l'historique ni les préférences. Les anciens groupes,
qui ne possèdent ni type ni suite de répétitions, restent des groupes libres.
Tout le fichier est validé avant écriture : une séance invalide annule
l'import entier sans mutation partielle.

## Restaurer une sauvegarde v2 ou v3

Après la sélection d'un fichier v2 ou v3 valide, RepTimer affiche un résumé avec sa
date, le nombre de séances, le nombre d'entrées d'historique et les préférences
à restaurer.

L'action **Restaurer** est destructive : après confirmation, elle remplace
intégralement les séances et l'historique, puis remplace le thème, le
préremplissage du nom, le mode de notification et le compte à rebours. Une
sauvegarde v2 utilise la valeur 0 pour ce dernier. Le thème est appliqué
immédiatement et le checkpoint local est supprimé. Les permissions Android et
les autres drapeaux internes restent inchangés.

**Annuler** ne modifie aucune donnée. En cas d'échec pendant l'écriture,
RepTimer tente de restaurer exactement les valeurs précédentes et n'annonce
jamais un succès partiel.

## Précautions

- conserver le fichier source jusqu'à la fin de la vérification ;
- vérifier le résumé avant de confirmer une restauration v2 ou v3 ;
- réaliser les essais destructifs sur des données de test ou après avoir créé
  une sauvegarde récente ;
- ne jamais utiliser l'unique copie de données personnelles de production pour
  tester une restauration.

Un JSON invalide, un fichier destiné à une autre application ou une version de
format inconnue est refusé avant toute écriture.
