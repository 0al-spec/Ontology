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
node --input-type=module - "$output/first/ontology.normalized.json" "$output" <<'JS'
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

// Resolve navigation declared by the design against real emitted IR rather than
// checking only strings/booleans in the design against another local constant.
const eventRelation = fqid => {
  const value = events.relations.find(r => r.fqid === fqid);
  assert(value, 'Design references a missing event relation: ' + fqid);
  return value;
};
for (const [viewType, edge] of Object.entries(contract.actorRoleBinding.byViewType)) {
  assert(relation('hypothesisView').range.oneOf.includes(viewType));
  assert.equal(eventRelation(edge).domain, viewType);
  assert.equal(eventRelation(edge).range, relation('hypothesisActorRole').range);
}
assert.equal(eventRelation(contract.actorRoleBinding.entityRelation).domain, relation('hypothesisActorRole').range);
assert.equal(eventRelation(contract.actorRoleBinding.entityRelation).range, 'eventcore:Entity');
assert.equal(contract.actorRoleBinding.exclusiveOwnershipRequired, false);
const own = contract.consequence.ownChange;
assert.equal(actual.relations.find(r => r.fqid === own.viewRelation)?.id, 'hypothesisView');
const ownRecord = eventRelation(own.recordRelation);
assert(relation('hypothesisView').range.oneOf.includes(ownRecord.domain));
assert.equal(eventRelation(own.deltaRecordRelation).range, ownRecord.range);
const downstream = contract.consequence.hypothesizedDownstream;
assert(declared.has(downstream.causalType));
for (const id of [downstream.causeViewRelation, downstream.effectViewRelation]) {
  assert.equal(eventRelation(id).domain, downstream.causalType);
  assert.equal(eventRelation(id).range, ownRecord.domain);
}
assert.equal(eventRelation(downstream.effectRecordRelation).range, ownRecord.range);
assert.equal(eventRelation(downstream.deltaRecordRelation).range, ownRecord.range);
assert.equal(contract.consequence.emptyOwnDiffMeansNoDownstreamConsequences, false);
assert.equal(downstream.workflowStateProvesCausation, false);
assert.equal(downstream.automaticTransitivity, false);
assert.equal(downstream.mergeRecordDeltas, false);

// This exercises the existing event graph and a manual design example, not
// admission of motivation nodes, source truth, or verified causal attribution.
const example = read('SPECS/ontology/packages/motivation-core/design/omission-consequence-example.json');
const graph = read(example.eventGraph);
const node = id => {
  const value = graph.nodes.find(n => n.id === id);
  assert(value, 'Example references a missing graph node: ' + id);
  return value;
};
const ref = id => ({graphKey:graph.graphKey, revisionKey:graph.revisionKey, nodeId:id, type:node(id).type});
const sameRef = (a, b) => ['graphKey', 'revisionKey', 'nodeId', 'type'].every(k => a[k] === b[k]);
const targets = (from, edge) => graph.edges.filter(e => sameRef(e.from, ref(from)) && e.relation === edge).map(e => e.to.nodeId);
const single = values => { assert.equal(values.length, 1); return values[0]; };
const motive = example.motivation;
const expected = example.expected;
const selectedView = node(motive.hypothesisView);
const selectedRoleEdge = contract.actorRoleBinding.byViewType[selectedView.type];
assert(targets(selectedView.id, selectedRoleEdge).includes(motive.hypothesisActorRole));
assert.equal(node(motive.hypothesisActorRole).fields.roleName, contract.actorRoleBinding.roleName);
assert.equal(single(targets(motive.hypothesisActorRole, contract.actorRoleBinding.entityRelation)), expected.actorEntity);
const contributionRecord = single(targets(selectedView.id, own.recordRelation));
assert.equal(contributionRecord, expected.ownRecord);
const changes = record => {
  const before = single(targets(record, 'eventcore:recordBeforeSnapshot'));
  const after = single(targets(record, 'eventcore:recordAfterSnapshot'));
  const beforeFacts = targets(before, 'eventcore:snapshotContainsFact');
  const afterFacts = targets(after, 'eventcore:snapshotContainsFact');
  return {beforeSnapshot:before, afterSnapshot:after,
    addedFacts:afterFacts.filter(id => !beforeFacts.includes(id)).sort(),
    removedFacts:beforeFacts.filter(id => !afterFacts.includes(id)).sort()};
};
const localDeltas = graph.edges.filter(e => e.relation === own.deltaRecordRelation && sameRef(e.to, ref(contributionRecord)));
assert.equal(localDeltas.length, 0);
assert.deepEqual({...changes(contributionRecord), storedDelta:null}, expected.ownChange);
const causes = graph.edges.filter(e => e.relation === downstream.causeViewRelation && sameRef(e.to, ref(selectedView.id)));
const causal = node(single(causes.map(e => e.from.nodeId)));
assert.equal(causal.id, expected.causalHypothesis);
assert.equal(causal.type, downstream.causalType);
assert.equal(causal.state, expected.causalState);
const effectView = single(targets(causal.id, downstream.effectViewRelation));
assert.equal(effectView, expected.effectView);
const effectRecord = single(targets(effectView, downstream.effectRecordRelation));
assert.equal(effectRecord, expected.effectRecord);
assert.notEqual(contributionRecord, effectRecord);
assert(targets(expected.effectDelta, downstream.deltaRecordRelation).includes(effectRecord));
const effectChange = changes(effectRecord);
assert.deepEqual({addedFacts:effectChange.addedFacts, removedFacts:effectChange.removedFacts}, expected.effectChange);
assert.deepEqual(targets(expected.effectDelta, 'eventcore:deltaAddsFact').sort(), effectChange.addedFacts);
assert.deepEqual(targets(expected.effectDelta, 'eventcore:deltaRemovesFact').sort(), effectChange.removedFacts);
assert.equal(expected.consequenceAttribution, downstream.attribution);
assert.equal(expected.causationVerified, false);
assert.equal(expected.motivationTruthVerified, false);
assert.deepEqual(motive.positiveSupport, []);
assert.deepEqual(motive.negativeSupport, []);

const write = (name, value) => fs.writeFileSync(process.argv[3] + '/' + name + '.json', JSON.stringify(value));
const edge = (from, relation, to) => ({from, relation, to});
const withEmpty = structuredClone(graph);
const emptyRef = {graphKey:graph.graphKey, revisionKey:graph.revisionKey, nodeId:'omission-delta', type:'eventcore:Delta'};
withEmpty.nodes.push({id:emptyRef.nodeId, type:emptyRef.type, fields:{}});
withEmpty.edges.push(edge(emptyRef, own.deltaRecordRelation, ref(contributionRecord)));
write('empty-own-change', withEmpty);
const misplaced = structuredClone(graph);
misplaced.edges.find(e => e.from.nodeId === expected.effectDelta && e.relation === downstream.deltaRecordRelation).to = ref(contributionRecord);
write('misplaced-effect-delta', misplaced);
const shared = structuredClone(graph);
const candidate = {...structuredClone(node('letter-view')), id:'shared-owner-candidate', fields:{candidateKey:'shared-owner-candidate'}};
shared.nodes.push(candidate);
const candidateRef = {graphKey:graph.graphKey, revisionKey:graph.revisionKey, nodeId:candidate.id, type:candidate.type};
for (const original of graph.edges.filter(e => e.from.nodeId === 'letter-view')) {
  const copy = structuredClone(original);
  copy.from = candidateRef;
  if (copy.relation === contract.actorRoleBinding.byViewType[candidate.type]) copy.to = ref(motive.hypothesisActorRole);
  shared.edges.push(copy);
}
write('shared-actor-role', shared);
console.log('Motivation import/design navigation: PASS (' + refs.size + ' event classes; own/downstream changes kept separate).');
JS

# Frozen v1 controls deliberately use their original IR/profile. Do not admit
# motivcore nodes or reinterpret historical reports under the new design.
event_ir="SPECS/ontology/packages/events-core/generated/ontology.normalized.json"
"$compiler" validate-instances "$output/empty-own-change.json" --ontology-ir "$event_ir" --out "$output/empty-report.json"
"$compiler" validate-instances "$output/shared-actor-role.json" --ontology-ir "$event_ir" --out "$output/shared-role-report.json"
if "$compiler" validate-instances "$output/misplaced-effect-delta.json" --ontology-ir "$event_ir" --out "$output/misplaced-report.json"; then
    echo "error: movement Delta was accepted as the omission's own change" >&2
    exit 1
fi
node --input-type=module - "$output" <<'JS'
import fs from 'node:fs';
import assert from 'node:assert/strict';
const read = name => JSON.parse(fs.readFileSync(process.argv[2] + '/' + name + '.json', 'utf8'));
for (const name of ['empty-report', 'shared-role-report']) {
  const report = read(name);
  assert.equal(report.status, 'passed');
  assert.equal(report.authority.sourceTruthVerified, false);
  assert.equal(report.authority.causationVerified, false);
}
assert(read('misplaced-report').diagnostics.some(d => d.code === 'instanceGraph.delta.exact'));
console.log('Frozen event fixture controls: PASS (empty own Delta, shared role, misplaced effect rejected).');
JS
