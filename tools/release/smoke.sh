#!/usr/bin/env bash
# Absolute arguments allow execution outside both checkout and extracted archive.
set -euo pipefail
bin_dir=$1
source_dir=$2
work=$3
executables=$4
mkdir -p "$work"
cd "$work"
fixture="$source_dir/SPECS/ontology/packages/examcalc/domain-ontology-package.yaml"
"$bin_dir/ontologyc" check "$fixture"
"$bin_dir/ontologyc" compile "$fixture" --target typescript --out "$work/generated"
cmp "$work/generated/ontology.normalized.json" "$source_dir/SPECS/ontology/packages/examcalc/generated/ontology.normalized.json"
# Exercise the foundation identity carried by the selected release, including
# re-dispatches for historical releases built from their original checkouts.
catalog="$source_dir/SPECS/ontology/foundation/0.1.0/exports.json"
if [[ -f "$source_dir/SPECS/ontology/foundation/0.2.0/exports.json" ]]; then
  catalog="$source_dir/SPECS/ontology/foundation/0.2.0/exports.json"
fi
if [[ -f "$catalog" ]]; then
  "$bin_dir/ontologyc" export-foundation > "$work/foundation.json"
  cmp "$catalog" "$work/foundation.json"
fi
if [[ -f "$source_dir/SPECS/ontology/examples/theatre.yaml" ]]; then
  "$bin_dir/ontologyc" check "$source_dir/SPECS/ontology/examples/theatre.yaml"
fi
case "$executables" in
  ontologyc) echo 'Selected source predates ontologyviz; compiler-only smoke passed'; exit 0 ;;
  ontologyc,ontologyviz) ;;
  *) echo 'Unexpected executable inventory' >&2; exit 2 ;;
esac
profile="$source_dir/Examples/package-visualization/motivation-relations.profile.json"
if [[ -f "$profile" ]]; then
  "$bin_dir/ontologyviz" --profile "$profile" --out "$work/diagram"
  cmp "$work/diagram/ontology.dot" "$source_dir/Examples/package-visualization/motivation-relations.dot"
  for text in 'eventcore:RecordedEvent' 'motivcore:Motive' 'eventcore:hypothesisCauseView'; do
    grep -Fq "$text" "$work/diagram/ontology.dot"
    grep -Fq "$text" "$work/diagram/ontology.svg"
  done
else
  # Earlier visualization tags support rendering but do not yet have profiles.
  echo 'Selected source has no saved motivation profile; testing basic rendering'
  "$bin_dir/ontologyviz" "$fixture" --out "$work/diagram"
fi
grep -q '^digraph ontology {' "$work/diagram/ontology.dot"
grep -q '<svg' "$work/diagram/ontology.svg"
grep -q '</svg>' "$work/diagram/ontology.svg"
test "$(od -An -tx1 -N8 "$work/diagram/ontology.png" | tr -d ' \n')" = 89504e470d0a1a0a
test "$(wc -c < "$work/diagram/ontology.png")" -gt 24
test "$(tail -c 12 "$work/diagram/ontology.png" | od -An -tx1 | tr -d ' \n')" = 0000000049454e44ae426082
