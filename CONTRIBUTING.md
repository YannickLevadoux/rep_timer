# Contribuer à RepTimer

Ce guide décrit l'organisation du développement et le cycle de vie des
contributions. Pour installer et lancer l'application, consulter le
[démarrage rapide](README.md#installation). Les commandes de validation
exécutées avant une Pull Request sont détaillées dans la
[documentation CI/CD](docs/ci-cd.md#validation-des-pull-requests).

## Environnement local

Le projet utilise Flutter et Dart. La version de Flutter attendue par les
workflows est épinglée afin de conserver des validations reproductibles. Les
versions de référence et les autres paramètres d'exécution sont documentés
dans la [documentation CI/CD](docs/ci-cd.md).

Pour lancer l'application, utiliser de préférence le script documenté dans le
[README](README.md#lancer-lapplication). Pour construire un APK local ou
comprendre les métadonnées DEV, consulter le guide des
[builds et releases](docs/release.md#builds-locaux).

## Structure du projet

```text
lib/
├── main.dart                  # Point d'entrée et composition de l'application
├── controllers/               # État et actions indépendants des widgets
├── models/                    # Modèles métier et historique
├── screens/                   # Édition, résumé, exécution et historique
├── services/                  # Stockage et orchestration métier
├── validation/                # Contrats et règles de validation
├── widgets/                   # Composants réutilisables
└── utils/                     # Formatage et registre d'icônes
```

Les workflows et leurs scripts sont regroupés sous `.github/`. Les outils
destinés au développement local sont regroupés sous `tool/`.

## Convention de nommage des branches

Chaque branche de développement doit être associée à une unique issue GitHub
et respecter le format suivant :

```text
<type>/<issue>-<description>
```

avec :

- `type` parmi `feature`, `bugfix`, `hotfix` ou `clean` ;
- `issue` correspondant au numéro de l'issue GitHub ;
- `description` sous la forme d'une description courte, généralement en
  *kebab-case*.

Exemples :

```text
feature/33-refacto-training-editor
bugfix/61-session-save
hotfix/85-crash-startup
clean/76-refacto-whatever
```

Le workflow de cycle de vie surveille uniquement les pushes sur ces quatre
familles de branches. Il vérifie leur nom avec l'expression
`<type>/<numéro>-<description>` et échoue si le nom complet n'est pas conforme.
Les autres branches ne bénéficient pas de cette automatisation et ne sont pas
considérées comme des erreurs. Les branches Renovate sont exclues de ce cycle.

## Cycle de vie d'une issue

Une issue prête à être développée doit d'abord porter le label `ready`.

Au premier push sur une branche conforme, le job `sync-issue-and-pr` :

- extrait le numéro de l'issue depuis le nom de la branche ;
- ajoute le label `in-progress` ;
- retire le label `ready` ;
- crée une Pull Request vers `main`, avec le titre
  `#<issue> - <titre de l'issue>`.

L'issue doit être ouverte et porter `ready` ou `in-progress`. Le workflow échoue
si ces préconditions ne sont pas respectées.

La description d'une Pull Request créée par le workflow contient :

```text
Closes #<issue>

> 🤖 Pull request créée automatiquement par GitHub Actions.
```

À chaque push suivant, le workflow vérifie de manière idempotente le label, la
Pull Request vers `main` et la directive `Closes #<issue>`. Si tous les éléments
sont présents, il ne les modifie pas.

Si une Pull Request vers `main` a été créée manuellement, le workflow conserve
sa description et ajoute uniquement `Closes #<issue>` si nécessaire. La mention
de création automatique n'est jamais ajoutée à une Pull Request existante.

Lors de la fusion de la Pull Request :

- le label `in-progress` est retiré ;
- l'issue est fermée si la description ou un commentaire de la Pull Request
  contient `Close #<issue>` ou `Closes #<issue>`, sans distinction de casse.

Lorsqu'une branche est supprimée, le label `in-progress` est retiré si l'issue
associée est encore ouverte. Les changements et traitements ignorés sont
publiés dans les logs et les résumés GitHub Actions. Les erreurs d'API ou
d'exécution font échouer le job.

## Mise à jour des dépendances

Renovate crée des Pull Requests portant le label `dependencies` pour :

- les dépendances Dart et Flutter, regroupées sous `Dart & Flutter packages` ;
- les GitHub Actions, regroupées sous `GitHub Actions` ;
- la version de Flutter déclarée dans les workflows, détectée par une règle
  dédiée.

Les Pull Requests Renovate ciblant `main` passent par les mêmes validations et
le même build APK debug que les autres Pull Requests. Elles restent exclues de
l'automatisation de cycle de vie liée aux noms de branches et aux issues.
