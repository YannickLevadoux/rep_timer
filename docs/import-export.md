# Importer, exporter et restaurer

Les entrées **Importer** et **Exporter** de **Paramètres > Import / Export**
ouvrent deux écrans distincts. Les quatre parcours ne sont pas
interchangeables : un fichier choisi dans le mauvais parcours est refusé avant
toute modification.

| Parcours | Format | Effet |
| --- | --- | --- |
| Exporter des séances | Crée un export v1 | Partage uniquement les séances sélectionnées |
| Importer des séances | Accepte un export v1 | Ajoute les séances sans remplacer les données locales |
| Sauvegarder les données | Crée une sauvegarde v3 | Partage toutes les données couvertes par la sauvegarde complète |
| Restaurer les données | Accepte une sauvegarde v2 ou v3 | Remplace les données locales après confirmation |

## Partager des séances

Dans **Exporter > Exporter des séances**, toutes les séances sont cochées par
défaut. Elles peuvent être sélectionnées individuellement, avec **Tout cocher**
ou **Tout décocher**. L'export est désactivé lorsque la sélection est vide.

Le fichier v1 conserve l'ordre affiché et les définitions complètes des
séances choisies, dont les groupes libres, à répétitions variables, Tabata,
AMRAP et EMOM. Il ne contient ni historique, ni préférences, ni checkpoint.
RepTimer valide toute la sélection avant d'écrire et de partager le fichier.

Dans **Importer > Importer des séances**, ce fichier est validé intégralement,
puis toutes ses séances sont ajoutées à la liste locale avec de nouveaux
identifiants de séances et de groupes. Les séances déjà présentes, les noms en
double, l'historique, les préférences et le checkpoint restent inchangés. Un
export v1 vide est refusé.

## Sauvegarder et restaurer toutes les données

**Exporter > Sauvegarder les données** crée exclusivement une sauvegarde v3
contenant toutes les séances, tout l'historique, les préférences exportables et
les métadonnées du format. Le checkpoint d'une séance en cours, les permissions
Android et les réglages techniques internes restent exclus.

**Importer > Restaurer les données** accepte les sauvegardes v3 ainsi que les
anciennes sauvegardes v2, conservées uniquement pour la compatibilité en
lecture. RepTimer ne crée plus de sauvegarde v2. Après validation complète, un
dialogue résume la date, les séances, l'historique et les préférences avant de
proposer la restauration destructive.

La confirmation remplace transactionnellement les séances, l'historique et les
préférences, applique immédiatement le thème restauré et supprime le checkpoint
local. Une sauvegarde valide sans séance ou sans historique reste restaurable :
le dialogue prévient alors explicitement que les données locales correspondantes
seront toutes supprimées. Si les deux ensembles sont vides, toutes les séances
et tout l'historique locaux sont supprimés, puis les préférences du fichier sont
appliquées. Ce n'est pas une remise aux paramètres d'usine.

En cas d'échec d'écriture, RepTimer restaure les anciennes données et n'annonce
jamais de succès partiel. Annuler le dialogue ne modifie rien.

## Annulations et erreurs

Fermer un sélecteur sans choisir de fichier affiche une annulation et conserve
l'écran **Importer**. Fermer explicitement la feuille de partage affiche une
annulation et conserve l'écran **Exporter**. Quand la plateforme accepte le
partage ou ne peut pas en déterminer le résultat, RepTimer considère que le
fichier lui a été confié, affiche le succès puis revient aux Paramètres.

Une lecture partielle ou illisible, un JSON invalide, un fichier d'une autre
application, une version inconnue ou un format utilisé dans le mauvais parcours
est refusé sans mutation ni partage. Après une erreur, l'écran courant reste
ouvert afin de permettre une nouvelle tentative.

Le schéma complet v3 est décrit dans le [contrat de sauvegarde v3](backup-v3.md).
