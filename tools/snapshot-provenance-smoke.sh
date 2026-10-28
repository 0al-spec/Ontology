#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
compiler="${ONTOLOGYC_PROVENANCE_BINARY_PATH:-.build/ci-quality/debug/ontologyc}"
output="$(mktemp -d "${TMPDIR:-/tmp}/ontology-provenance.XXXXXX")"
trap 'rm -rf "$output"' EXIT
export LLVM_PROFILE_FILE="$output/provenance-%p.profraw"
package="SPECS/ontology/packages/events-core/versions/0.2.0"
ir="$package/generated/ontology.normalized.json"
cmp "$package/authoring/domain-ontology-package-draft.yaml" "$package/domain-ontology-package.yaml"
"$compiler" validate-draft "$package/authoring" --out "$output/draft-report.yaml"
"$compiler" check "$package/domain-ontology-package.yaml"
"$compiler" compile "$package/domain-ontology-package.yaml" --target typescript --out "$output/package"
diff -ru "$package/generated" "$output/package"
"$compiler" export-instance-contract --ontology-ir "$ir" --profile eventcore-provenance-v1 --out "$output/contract"
diff -ru SPECS/ontology/instance-graph/provenance/generated "$output/contract"
node --input-type=module - "$compiler" "$output" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';
const [compiler, output] = process.argv.slice(2);
const root = 'SPECS/ontology/fixtures/instance-graphs/provenance';
const ir = 'SPECS/ontology/packages/events-core/versions/0.2.0/generated/ontology.normalized.json';
const read = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const hash = p => crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const descriptor = 'SPECS/ontology/instance-graph/profiles/eventcore-provenance-v1.json';
assert.equal(read(descriptor).irSHA256, hash(ir));
const cases = read(path.join(root, 'cases.json'));
for (const item of cases) {
  const graph = path.join(root, item.graph);
  const report = path.join(output, item.name + '-report.json');
  const result = spawnSync(compiler, ['validate-instances', graph, '--ontology-ir', ir,
    '--profile', 'eventcore-provenance-v1', '--provenance-authority', path.join(root, item.authority), '--out', report], {encoding:'utf8'});
  assert.equal(result.status, item.status === 'passed' ? 0 : 1, item.name + ': ' + result.stderr);
  const value = read(report);
  assert.equal(value.status, item.status);
  assert.equal(value.graphSHA256, hash(graph));
  assert.equal(value.profilePin.definitionSHA256, hash(descriptor));
  assert.equal(value.authority.sourceTruthVerified, false);
  assert.equal(value.provenance.authorityAuthenticationVerified, false);
  assert.equal(value.provenance.confirmationStatus, item.status === 'passed' ? (value.provenance.snapshotCount === 0 ? 'no-snapshots' : 'confirmed-under-supplied-authority') : 'not-confirmed');
  if (item.code) assert(value.diagnostics.some(d => d.code === 'instanceGraph.' + item.code), item.name + ': ' + JSON.stringify(value.diagnostics));
}
console.log('Snapshot provenance fixtures: ' + cases.length + '/' + cases.length + ' PASS');
JS
