#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
compiler="${ONTOLOGYC_INSTANCE_BINARY_PATH:-.build/ci-quality/debug/ontologyc}"
output="$(mktemp -d "${TMPDIR:-/tmp}/ontology-instance-contract.XXXXXX")"
trap 'rm -rf "$output"' EXIT
export LLVM_PROFILE_FILE="$output/instance-%p.profraw"
ir="SPECS/ontology/packages/events-core/generated/ontology.normalized.json"
fixtures="SPECS/ontology/fixtures/instance-graphs"
"$compiler" export-instance-contract --ontology-ir "$ir" --out "$output/generated"
diff -ru SPECS/ontology/instance-graph/generated "$output/generated"
"$compiler" validate-instances "$fixtures/synthetic-car.json" --ontology-ir "$ir" --out "$output/car-report.json"
"$compiler" validate-instances "$fixtures/source-only.json" --ontology-ir "$ir" --out "$output/source-report.json"
if "$compiler" validate-instances "$fixtures/missing-interval.json" --ontology-ir "$ir" --out "$output/invalid-report.json"; then
    echo "error: invalid instance fixture was accepted" >&2
    exit 1
fi
