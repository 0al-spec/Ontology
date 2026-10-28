#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
compiler="${ONTOLOGYC_AGENCY_BINARY_PATH:-.build/ci-quality/debug/ontologyc}"
if [[ ! -x "$compiler" ]]; then
    echo "error: ontologyc unavailable; agency validation was not run" >&2
    exit 127
fi
output="$(mktemp -d "${TMPDIR:-/tmp}/ontology-agency.XXXXXX")"
trap 'rm -rf "$output"' EXIT
export LLVM_PROFILE_FILE="$output/agency-%p.profraw"
package="SPECS/ontology/packages/agency-core"
cmp "$package/authoring/domain-ontology-package-draft.yaml" "$package/domain-ontology-package.yaml"
"$compiler" validate-draft "$package/authoring" --out "$output/draft.yaml"
"$compiler" check "$package/domain-ontology-package.yaml"
"$compiler" compile "$package/domain-ontology-package.yaml" --target typescript --out "$output/first"
"$compiler" compile "$package/domain-ontology-package.yaml" --target typescript --out "$output/second"
diff -ru "$output/first" "$output/second"
diff -ru "$package/generated" "$output/first"
node --input-type=module - "$output/first/ontology.normalized.json" <<'JS'
import assert from 'node:assert/strict';
import fs from 'node:fs';
import crypto from 'node:crypto';
const read = path => JSON.parse(fs.readFileSync(path, 'utf8'));
const actual = read(process.argv[2]);
const pin = read('SPECS/ontology/packages/agency-core/profiles/agency-source-attribution-v1.json');
for (const key of ['id','namespace','version','sourceDigest']) assert.equal(actual[key], pin.packageVocabulary[key]);
assert.equal(crypto.createHash('sha256').update(fs.readFileSync(process.argv[2])).digest('hex'), pin.packageVocabulary.irSHA256);
const dependencies = pin.dependencies.map(dep => {
  const raw = fs.readFileSync(dep.path);
  assert.equal(crypto.createHash('sha256').update(raw).digest('hex'), dep.irSHA256);
  const ir = JSON.parse(raw);
  for (const key of ['id','namespace','version','sourceDigest']) assert.equal(ir[key], dep[key]);
  assert(actual.imports.some(i => ['id','namespace','version'].every(k => i[k] === ir[k])));
  return ir;
});
const declared = new Set([actual, ...dependencies].flatMap(ir => ir.classes.map(c => c.fqid)));
for (const r of actual.relations) {
  for (const ref of [r.domain, ...(typeof r.range === 'string' ? [r.range] : r.range.oneOf)])
    assert(declared.has(ref), 'Unresolved relation endpoint: ' + ref);
}
const relation = id => { const r = actual.relations.find(r => r.id === id); assert(r, id); return r; };
const events = dependencies.find(ir => ir.namespace === 'eventcore');
const motivation = dependencies.find(ir => ir.namespace === 'motivcore');
assert.equal(actual.id, 'org.0al.agency.core');
assert.equal(actual.classes.length, 10);
assert.equal(actual.relations.length, 24);
assert(actual.policies.every(p => p.enforceability === 'manual'));
assert(!actual.classes.some(c => /:(Motive|StateSnapshot|Fact|Delta)$/.test(c.fqid)));
assert.deepEqual(relation('contextView').range.oneOf, pin.contextViewAlternatives);
assert.deepEqual(relation('contextView').cardinality, {min:1,max:1});
assert.equal(relation('contextActorRole').range, 'eventcore:RoleBinding');
assert.deepEqual(relation('contextActorRole').cardinality, {min:0,max:1});
for (const [view, edge] of Object.entries(pin.actorRoleBinding.byViewType)) {
  const r = events.relations.find(r => r.fqid === edge);
  assert.equal(r?.domain, view);
  assert.equal(r?.range, relation('contextActorRole').range);
}
assert.equal(motivation.relations.find(r => r.id === 'hypothesisView')?.range.oneOf.includes('eventcore:InterpretationCandidate'), true);
assert.equal(relation('awarenessMotivation').range, 'motivcore:MotivationHypothesis');
for (const [kind, concept] of Object.entries(pin.claimConcepts)) {
  assert(declared.has(concept));
  assert.equal(relation(kind + 'Context').domain, concept);
  assert.equal(relation(kind + 'Context').range, 'agencycore:AgencyContext');
  for (const sign of ['Positive','Negative']) {
    const support = relation(kind + sign + 'Support');
    assert.equal(support.domain, concept);
    assert.deepEqual([...support.range.oneOf].sort(), ['agencycore:OperatorAgencySupport','eventcore:SourceAssertion']);
    assert.deepEqual(support.cardinality, {min:0,max:'*'});
  }
}
for (const name of ['goalContent','anticipationContent','attitudeContent','awarenessContent'])
  assert.equal(relation(name).range, 'agencycore:PropositionContent');
assert.equal(relation('intentionGoal').range, pin.claimConcepts.goal);
assert.equal(pin.executable, 'bounded-reference-envelope-only');
assert(Object.values(pin.authority).every(value => value === false));
assert(Object.values(pin.existingProfileAdmission).every(value => value === false));
console.log('Agency draft/dependency/IR navigation: PASS; reference-envelope execution is a separate TypeScript gate.');
JS
