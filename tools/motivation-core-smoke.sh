#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
compiler="${ONTOLOGYC_MOTIVATION_BINARY_PATH:-.build/ci-quality/debug/ontologyc}"
output="$(mktemp -d "${TMPDIR:-/tmp}/ontology-motivation.XXXXXX")"
trap 'rm -rf "$output"' EXIT
export LLVM_PROFILE_FILE="$output/motivation-%p.profraw"
package="SPECS/ontology/packages/motivation-core"
cmp "$package/authoring/domain-ontology-package-draft.yaml" "$package/domain-ontology-package.yaml"
"$compiler" validate-draft "$package/authoring" --out "$output/draft-report.yaml"
"$compiler" check "$package/domain-ontology-package.yaml"
"$compiler" compile "$package/domain-ontology-package.yaml" --target typescript --out "$output/first"
"$compiler" compile "$package/domain-ontology-package.yaml" --target typescript --out "$output/second"
diff -ru "$output/first" "$output/second"
diff -ru "$package/generated" "$output/first"
node --input-type=module - "$output/first/ontology.normalized.json" <<'JS'
import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
const read = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const actual = read(process.argv[2]);
const eventPath = 'SPECS/ontology/packages/events-core/versions/0.2.0/generated/ontology.normalized.json';
const events = read(eventPath);
const contract = read('SPECS/ontology/packages/motivation-core/design/motivation-binding-v1.json');
const declared = new Set(events.classes.map(c => c.fqid));
const refs = new Set();
const visit = value => {
  if (typeof value === 'string' && value.startsWith('eventcore:')) refs.add(value);
  else if (Array.isArray(value)) value.forEach(visit);
  else if (value && typeof value === 'object') Object.values(value).forEach(visit);
};
actual.classes.forEach(visit); actual.relations.forEach(visit);
for (const ref of refs) assert(declared.has(ref), 'Unknown imported event class: ' + ref);
assert.deepEqual([...refs].sort(), ['eventcore:Entity', 'eventcore:Fact', 'eventcore:Interpretation', 'eventcore:InterpretationCandidate', 'eventcore:RoleBinding', 'eventcore:SourceAssertion']);
const relation = id => {
  const value = actual.relations.find(r => r.id === id);
  assert(value, 'Missing declared relation: ' + id);
  return value;
};
assert.equal(relation('hypothesisActorRole').range, 'eventcore:RoleBinding');
assert.deepEqual(relation('hypothesisActorRole').cardinality, {min:0,max:1});
assert.deepEqual(relation('hypothesisView').range, {oneOf:['eventcore:Interpretation','eventcore:InterpretationCandidate']});
assert.deepEqual(relation('hypothesisView').cardinality, {min:1,max:1});
assert.equal(relation('hypothesisMotive').range, 'motivcore:Motive');
assert.deepEqual(relation('hypothesisMotive').cardinality, {min:1,max:1});
for (const id of ['hypothesisPositiveSupport', 'hypothesisNegativeSupport']) {
  assert.deepEqual(relation(id).range, {oneOf:['eventcore:SourceAssertion','motivcore:OperatorMotivationSupport']});
  assert.deepEqual(relation(id).cardinality, {min:0,max:'*'});
}
assert.equal(relation('operatorSupportAuthor').range, 'eventcore:Entity');
assert.deepEqual(relation('operatorSupportAuthor').cardinality, {min:1,max:1});
for (const key of ['id', 'namespace', 'version', 'sourceDigest']) assert.equal(contract.eventVocabulary[key], events[key], 'Event pin: ' + key);
assert.equal(contract.eventVocabulary.irSHA256, crypto.createHash('sha256').update(fs.readFileSync(eventPath)).digest('hex'));
assert(actual.imports.some(i => i.id === events.id && i.namespace === events.namespace && i.version === events.version));
// Approval metadata remains in the source package, not the normalized IR.
assert(fs.readFileSync('SPECS/ontology/packages/motivation-core/domain-ontology-package.yaml', 'utf8').includes('\n  approvalStatus: draft\n'));
assert(actual.policies.every(p => p.enforceability === 'manual'));
assert.equal(contract.kind, 'MotivationBindingDesign');
assert.equal(contract.executable, false);
assert.equal(contract.consciousIntentionRequired, false);
assert(Object.values(contract.authority).every(value => value === false));
assert(Object.values(contract.existingProfileAdmission).every(value => value === false));
assert.equal(contract.consequence.sourceOnlyAvailable, true);
assert.equal(contract.consequence.unknownChangesAreEmptyDiff, false);
assert.equal(contract.consequence.desiredOutcomeIsActualConsequence, false);
assert.deepEqual(contract.contributionKinds, ['action', 'omission']);
assert.deepEqual(contract.scopeViewAlternatives, ['eventcore:Interpretation', 'eventcore:InterpretationCandidate']);
assert.deepEqual(contract.supportPresence, {neither:'unknown',positiveOnly:'supported',negativeOnly:'opposed',both:'contested'});
console.log('Motivation import/design boundary: PASS (' + refs.size + ' event classes).');
JS
