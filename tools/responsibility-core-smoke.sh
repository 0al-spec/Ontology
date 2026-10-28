#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
compiler="${ONTOLOGYC_RESPONSIBILITY_BINARY_PATH:-.build/ci-quality/debug/ontologyc}"
output="$(mktemp -d "${TMPDIR:-/tmp}/ontology-responsibility.XXXXXX")"
trap 'rm -rf "$output"' EXIT
export LLVM_PROFILE_FILE="$output/responsibility-%p.profraw"
package="SPECS/ontology/packages/responsibility-core"
cmp "$package/authoring/domain-ontology-package-draft.yaml" "$package/domain-ontology-package.yaml"
"$compiler" validate-draft "$package/authoring" --out "$output/draft-report.yaml"
"$compiler" check "$package/domain-ontology-package.yaml"
"$compiler" compile "$package/domain-ontology-package.yaml" --target typescript --out "$output/generated"
diff -ru "$package/generated" "$output/generated"
# Package imports resolve by namespace in the compiler. Verify this draft's
# imported class references against the actual pinned local event-core IR too.
node --input-type=module - "$output/generated/ontology.normalized.json" <<'JS'
import { readFileSync } from "node:fs";
const read = path => JSON.parse(readFileSync(path, "utf8"));
const actual = read(process.argv[2]);
const events = read("SPECS/ontology/packages/events-core/generated/ontology.normalized.json");
const mapping = read("SPECS/ontology/packages/responsibility-core/profiles/normlab-r3-v1.json");
const declared = new Set(events.classes.map(value => value.fqid));
const refs = new Set();
const visit = value => {
  if (typeof value === "string" && value.startsWith("eventcore:")) refs.add(value);
  else if (Array.isArray(value)) value.forEach(visit);
  else if (value && typeof value === "object") Object.values(value).forEach(visit);
};
actual.classes.forEach(visit);
actual.relations.forEach(visit);
for (const ref of refs) if (!declared.has(ref)) throw new Error(`Unknown imported event class: ${ref}`);
for (const key of ["id", "namespace", "version", "sourceDigest"]) {
  if (mapping.eventVocabulary[key] !== events[key]) throw new Error(`Event vocabulary pin mismatch: ${key}`);
}
if (mapping.executable !== false || mapping.authority.leanAdapterImplemented !== false) throw new Error("Draft mapping must not claim execution.");
console.log(`Responsibility import/pin check: PASS (${refs.size} event class references).`);
JS
