#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./tool/flutter_with_build_metadata.sh run [options Flutter]
  ./tool/flutter_with_build_metadata.sh build <cible> [options Flutter]

Exemples:
  ./tool/flutter_with_build_metadata.sh run
  ./tool/flutter_with_build_metadata.sh run -d linux
  ./tool/flutter_with_build_metadata.sh build apk --debug
  ./tool/flutter_with_build_metadata.sh build apk --release
EOF
}

print_large_dart_files() {
  local section_title="$1"
  shift

  printf '%s\n' "$section_title"
  local report
  report="$(
    "$@" |
    while IFS= read -r -d '' dart_file; do
      if [[ ! -f "$dart_file" || "$dart_file" != *.dart ]]; then
        continue
      fi

      local line_count
      line_count="$(awk 'END { print NR }' "$dart_file")"
      if ((line_count >= 200)); then
        printf '%d %s\n' "$line_count" "$dart_file"
      fi
    done |
    LC_ALL=C sort -k1,1nr -k2
  )"

  if [[ -z "$report" ]]; then
    printf '%s\n' 'Aucun fichier.'
    return 0
  fi

  printf '%s\n' "$report"
  return 1
}

print_large_dart_file_reports() {
  local has_oversized_file=0

  print_large_dart_files \
    'Fichiers Dart suivis sous lib/ dépassant la limite de 199 lignes :' \
    git ls-files -z -- 'lib' || has_oversized_file=1
  print_large_dart_files \
    'Fichiers Dart ajoutés dans le dernier commit dépassant la limite :' \
    git diff --name-only --diff-filter=A -z HEAD^ HEAD -- 'lib' ||
    has_oversized_file=1

  if ((has_oversized_file)); then
    printf '%s\n' \
      'Erreur : tous les fichiers Dart suivis sous lib/ doivent avoir au plus 199 lignes.' \
      >&2
    return 1
  fi
}

prepare_flutter_command() {
  ./android/gradlew --stop
  print_large_dart_file_reports
}

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 64
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 0
fi

case "$1" in
  run)
    shift
    prepare_flutter_command
    build_timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    exec flutter run \
      --dart-define=REP_TIMER_DISTRIBUTION=dev \
      --dart-define=REP_TIMER_BUILD_TIMESTAMP="$build_timestamp" \
      "$@"
    ;;
  build)
    if [[ $# -lt 2 ]]; then
      usage >&2
      exit 64
    fi
    build_target="$2"
    shift 2
    prepare_flutter_command
    build_timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    exec flutter build "$build_target" \
      --dart-define=REP_TIMER_DISTRIBUTION=dev \
      --dart-define=REP_TIMER_BUILD_TIMESTAMP="$build_timestamp" \
      "$@"
    ;;
  *)
    echo "Sous-commande non prise en charge : $1" >&2
    usage >&2
    exit 64
    ;;
esac
