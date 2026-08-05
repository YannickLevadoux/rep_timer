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

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 64
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 0
fi

build_timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

case "$1" in
  run)
    shift
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
