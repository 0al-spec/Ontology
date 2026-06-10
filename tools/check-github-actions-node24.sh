#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflow_dir="$root/.github/workflows"

status=0

minimum_major_for_action() {
    case "$1" in
        actions/checkout) printf '6' ;;
        actions/cache) printf '5' ;;
        actions/setup-node) printf '6' ;;
        actions/upload-pages-artifact) printf '5' ;;
        actions/deploy-pages) printf '5' ;;
        *) return 1 ;;
    esac
}

while IFS= read -r -d '' file; do
    while IFS= read -r line; do
        if [[ "$line" =~ uses:[[:space:]]*[\"\']?(actions/[-_[:alnum:]]+)@v([0-9]+)(\.[0-9]+){0,2}[\"\']? ]]; then
            action="${BASH_REMATCH[1]}"
            major="${BASH_REMATCH[2]}"
            minimum="$(minimum_major_for_action "$action" || true)"
            if [[ -n "$minimum" ]] && (( major < minimum )); then
                echo "error: $file references $action@v$major; expected >= v$minimum" >&2
                status=1
            fi
        fi
    done < "$file"
done < <(find "$workflow_dir" -type f \( -name '*.yml' -o -name '*.yaml' \) -print0)

exit "$status"
