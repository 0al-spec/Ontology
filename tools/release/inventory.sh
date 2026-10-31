#!/usr/bin/env bash
# Evaluate the selected source manifest with SwiftPM, never helper-checkout source.
set -euo pipefail
source_dir=$1
scratch=$2
helpers=$(cd "$(dirname "$0")" && pwd)
options=(--package-path "$source_dir" --scratch-path "$scratch")
if [[ -n ${SWIFT_PACKAGE_CACHE:-} ]]; then options+=(--cache-path "$SWIFT_PACKAGE_CACHE"); fi
swift package "${options[@]}" dump-package | python3 "$helpers/inventory.py"
