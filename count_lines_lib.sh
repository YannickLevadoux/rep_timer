#!/usr/bin/env bash

# Liste le nombre de lignes de chaque fichier dans le dossier lib, récursivement.
# Usage: ./count_lines_lib.sh [chemin_vers_lib]
# Exemple: ./count_lines_lib.sh lib

set -euo pipefail

LIB_DIR=${1:-lib}

if [[ ! -d "$LIB_DIR" ]]; then
  echo "Erreur: le dossier '$LIB_DIR' n'existe pas." >&2
  exit 1
fi

find "$LIB_DIR" -type f -print0 | sort -z | xargs -0 wc -l | sed 's/^ *//' | sort -n
