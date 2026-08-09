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
  "$@" |
    while IFS= read -r -d '' dart_file; do
      if [[ ! -f "$dart_file" ]]; then
        continue
      fi

      local line_count
      line_count="$(wc -l < "$dart_file")"
      if ((line_count >= 200)); then
        printf '%d %s\n' "$line_count" "$dart_file"
      fi
    done |
    LC_ALL=C sort -k1,1nr -k2
}

print_large_dart_file_reports() {
  print_large_dart_files \
    'Fichiers Dart suivis sous lib/ (au moins 200 lignes) :' \
    git ls-files -z -- 'lib/*.dart'
  print_large_dart_files \
    'Fichiers Dart ajoutés dans le dernier commit (au moins 200 lignes) :' \
    git diff --name-only --diff-filter=A -z HEAD^ HEAD -- 'lib/*.dart'
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
