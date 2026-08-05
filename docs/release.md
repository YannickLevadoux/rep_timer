# Builds et releases

Ce guide décrit les builds locaux, les métadonnées affichées par l'application
et la publication d'une release officielle. Les validations exécutées par les
workflows sont détaillées dans la [documentation CI/CD](ci-cd.md).

## Builds locaux

Les builds locaux doivent de préférence passer par le script
`tool/flutter_with_build_metadata.sh`. Le premier argument est directement la
sous-commande Flutter (`run` ou `build`) : il ne faut pas ajouter le mot
`flutter` après le nom du script.

Le script accepte les options Flutter après la cible `apk` :

```bash
# APK debug local
./tool/flutter_with_build_metadata.sh build apk --debug

# APK release local, toujours identifié comme DEV
./tool/flutter_with_build_metadata.sh build apk --release
```

Les APK générés se trouvent dans `build/app/outputs/flutter-apk/`.

Le script transmet le canal `dev` et la date de compilation UTC avec les
`--dart-define` centralisés dans `BuildMetadata`. Un lancement direct avec
`flutter run` reste possible : il est considéré comme DEV, mais le dialogue
« À propos » indique alors que la date de build est indisponible.

Le mode Flutter (`--debug` ou `--release`) ne détermine pas le canal de
distribution. Même un APK release construit avec ce script porte le badge DEV.
Seule la CI de publication transmet explicitement
`REP_TIMER_DISTRIBUTION=release`. Elle n'injecte pas de date et ne modifie ni la
version ni le numéro de build définis dans `pubspec.yaml`.

## Métadonnées de distribution

Les métadonnées sont centralisées dans `lib/models/build_metadata.dart` :

| Variable de compilation | Valeur | Effet |
| --- | --- | --- |
| `REP_TIMER_DISTRIBUTION` | `dev` par défaut, `release` pour une publication officielle | Affiche ou masque le badge DEV et les informations de build local |
| `REP_TIMER_BUILD_TIMESTAMP` | Date ISO 8601 en UTC, optionnelle | Est convertie dans le fuseau local de l'appareil avant affichage |

`kReleaseMode` ne permet pas cette distinction : un développeur peut produire
localement un APK optimisé avec `flutter build apk --release`. Le workflow de
release garantit l'absence du badge DEV en transmettant explicitement le canal
`release` au build signé.

## Dialogue « À propos »

L'icône doit être déclarée comme asset dans `pubspec.yaml` :

```yaml
flutter:
  assets:
    - assets/icon/app_icon.png
```

| Information | Où elle est définie | Comment elle arrive dans le dialogue |
| --- | --- | --- |
| Nom de l'application | Attribut `android:label` dans `android/app/src/main/AndroidManifest.xml` | Lu au runtime par `PackageInfo.fromPlatform().appName` |
| Icône | Fichier source `assets/icon/app_icon.png` utilisé par `flutter_launcher_icons` | Chargée avec `Image.asset()` après sa déclaration dans `pubspec.yaml` |
| Version | Champ `version: X.Y.Z+B` dans `pubspec.yaml` | Lue avec `PackageInfo.fromPlatform().version` et `.buildNumber`, également utilisés par Flutter pour `versionName` et `versionCode` Android |
| Copyright | Constante `_copyright` dans `lib/widgets/settings/app_about_dialog.dart` | Lu directement depuis cet unique emplacement |

## Signature Android

Le workflow de release attend les secrets GitHub Actions suivants :

- `KEYSTORE_BASE64` pour le contenu encodé du keystore ;
- `KEYSTORE_PASSWORD` pour le mot de passe du keystore ;
- `KEY_PASSWORD` pour le mot de passe de la clé.

La variable GitHub Actions `KEY_ALIAS` contient l'alias de la clé. Le workflow
décode le keystore puis génère temporairement `android/key.properties`. Ces
deux fichiers sont exclus du suivi Git et ne doivent jamais être ajoutés au
dépôt.

## Publication d'une release

Le workflow `release.yml` se déclenche lors de l'envoi d'un tag correspondant à
`v*`. Il réutilise les validations de la CI avant d'autoriser le job de
publication.

Après validation, le workflow :

1. configure Java et Flutter aux versions épinglées dans les workflows ;
2. récupère les dépendances ;
3. décode le keystore Android depuis `KEYSTORE_BASE64` ;
4. génère `android/key.properties` à partir des secrets de signature et de
   `KEY_ALIAS` ;
5. construit l'APK release signé avec
   `flutter build apk --release --dart-define=REP_TIMER_DISTRIBUTION=release` ;
6. renomme l'artefact en `RepTimer-<tag>.apk` ;
7. crée une GitHub Release avec des notes générées automatiquement et y joint
   l'APK.

La publication nécessite que les validations réussissent et que les secrets et
variables de signature Android soient configurés dans le dépôt GitHub.

Le tag ne doit être créé qu'après la fusion de la Pull Request de finalisation
sur `main`. Pour publier la version `X.Y.Z` :

```bash
git switch main
git pull --ff-only origin main
git tag -a vX.Y.Z -m "RepTimer vX.Y.Z"
git push origin vX.Y.Z
```

Après le push, surveiller le workflow Release, vérifier la création de la
GitHub Release et la présence de l'APK `RepTimer-vX.Y.Z.apk`, puis fermer le
milestone concerné.
