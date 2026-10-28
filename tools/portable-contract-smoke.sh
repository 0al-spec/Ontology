#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
compiler="${ONTOLOGYC_PORTABLE_BINARY_PATH:-.build/ci-quality/debug/ontologyc}"
if [[ ! -x "$compiler" ]]; then
    echo "error: ontologyc is unavailable or not executable: $compiler; validation was not run" >&2
    exit 127
fi
output="$(mktemp -d "${TMPDIR:-/tmp}/ontology-portable.XXXXXX")"
trap 'rm -rf "$output"' EXIT
export LLVM_PROFILE_FILE="$output/portable-%p.profraw"

# Compare complete compiler output with tracked baselines on each platform.
# These are package/structural checks, not proof of source truth or causation.
for name in examcalc specgraph-core events-core events-core/versions/0.2.0 responsibility-core motivation-core; do
    package="SPECS/ontology/packages/$name"
    "$compiler" check "$package/domain-ontology-package.yaml"
    "$compiler" compile "$package/domain-ontology-package.yaml" --target typescript --out "$output/$name"
    diff -ru "$package/generated" "$output/$name"
done

event_package="SPECS/ontology/packages/events-core"
cmp "$event_package/authoring/domain-ontology-package-draft.yaml" "$event_package/domain-ontology-package.yaml"
"$compiler" validate-draft "$event_package/authoring" --out "$output/events-draft-report.yaml"
ONTOLOGYC_INSTANCE_BINARY_PATH="$compiler" bash tools/instance-graph-smoke.sh
ONTOLOGYC_RESPONSIBILITY_BINARY_PATH="$compiler" bash tools/responsibility-core-smoke.sh
ONTOLOGYC_PROVENANCE_BINARY_PATH="$compiler" bash tools/snapshot-provenance-smoke.sh
ONTOLOGYC_MOTIVATION_BINARY_PATH="$compiler" bash tools/motivation-core-smoke.sh
echo "Portable package generation and structural contracts: PASS"
