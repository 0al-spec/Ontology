#!/usr/bin/env bash
set -euo pipefail

# Accept the same prebuilt executable that the portability gate tests.
compiler="$(cd "$(dirname "${1:?supply ontologyc}")" && pwd)/$(basename "$1")"
base="$(mktemp -d "${TMPDIR:-/tmp}/ontology-advice.XXXXXXXX")"
trap 'rm -rf "$base"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null ADVICE_TEST_BINARY="$compiler"
# A caller can itself be a Git hook or a CI checkout.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
git init -q "$base/repo"
cd "$base/repo"
git config user.name 'Ontology smoke'
git config user.email 'smoke@example.invalid'
mkdir -p "$base/hooks" 'models with spaces'
git config core.hooksPath "$base/hooks"
advisory='"$ADVICE_TEST_BINARY" advise-staged || echo "[ontology advice] check unavailable" >&2'
# Modern Git composes config hooks with the existing file hook. Older Git
# projects can call the same command from their hook manager.
if git -c hook.probe.command=true -c hook.probe.event=pre-commit hook list pre-commit >/dev/null 2>&1; then
    git config --local hook.ontology-package-advice.command "$advisory"
    git config --local hook.ontology-package-advice.event pre-commit
    printf '#!/bin/sh\n' > "$base/hooks/pre-commit"
else
    printf '#!/bin/sh\n%s\n' "$advisory" > "$base/hooks/pre-commit"
fi
echo 'test ! -e veto' >> "$base/hooks/pre-commit"
chmod +x "$base/hooks/pre-commit"

model='models with spaces/custom.yml'
package() {
    cat <<EOF
apiVersion: ontology.specgraph.io/v1alpha1
kind: DomainOntologyPackage
metadata: {id: test.staged, namespace: sample, version: 0.1.0}
spec:
  imports: [{id: specgraph.foundation, namespace: sg, version: 0.1.0}]
  classes:
    Entry: {extends: "sg:$1", description: A value.$2}
  relations:
    contains: {domain: Entry, range: Entry, cardinality: {min: 0, max: 1}}
EOF
}
commit() { git commit -qm "$1" >"$base/log" 2>&1 || { cat "$base/log" >&2; return 1; }; }
quiet() { if grep -F '[ontology advice]' "$base/log"; then return 1; fi; }

# The working copy is valid but the first commit (unborn HEAD) contains a typo.
package Typo '' > "$model"
git add -- "$model"
package ValueObject '' > "$model"
commit 'bad index, good worktree'
grep -F "$model" "$base/log" | grep -F 'class.extends.unresolved' | grep -F 'spec.classes.Entry.extends' >/dev/null
git show "HEAD:$model" | grep -F 'sg:Typo' >/dev/null

git add -- "$model"
package Typo '' > "$model"
commit 'good index, bad worktree'
quiet
# Commit only an unrelated YAML, leaving the unstaged package error in place.
printf 'example:\n  kind: DomainOntologyPackage\n' > unrelated.yaml
git add unrelated.yaml
commit unrelated
quiet

package ValueObject ', implements: [sg:Auditable]' > "$model"
git add -- "$model"
commit 'package warning'
grep -F 'warning protocol.imported.emit_unsupported' "$base/log" >/dev/null

printf 'kind: Unrelated\n' > "$model"
git add -- "$model"
commit 'accidentally removed package header'
grep -F 'kind.invalid' "$base/log" >/dev/null

git mv "$model" 'models with spaces/renamed.yaml'
package Typo '' > 'models with spaces/renamed.yaml'
git add -- 'models with spaces/renamed.yaml'
commit 'renamed package'
grep -F 'renamed.yaml' "$base/log" | grep -F 'class.extends.unresolved' >/dev/null

printf 'broken: [\n' > domain-ontology-package.yaml
git add domain-ontology-package.yaml
commit 'malformed canonical file'
grep -F 'yaml.parse' "$base/log" >/dev/null
git rm -q domain-ontology-package.yaml 'models with spaces/renamed.yaml'
ln -s "$base/nonexistent" domain-ontology-package.yaml
git add domain-ontology-package.yaml
commit 'deletion and symlink'
quiet

# The alternate index selects a different snapshot even with a clean default index.
alternate="$base/alternate-index"
GIT_INDEX_FILE="$alternate" git read-tree HEAD
package Typo '' > custom.YAML
GIT_INDEX_FILE="$alternate" git add custom.YAML
GIT_INDEX_FILE="$alternate" "$compiler" advise-staged > "$base/log" 2>&1
grep -F 'custom.YAML' "$base/log" | grep -F 'class.extends.unresolved' >/dev/null
"$compiler" advise-staged > "$base/log" 2>&1
quiet

printf 'kind: "DomainOntologyPackage"\nbroken: [\n' > custom.YAML
git add custom.YAML
commit 'broken new custom package with intact header'
grep -F 'yaml.parse' "$base/log" >/dev/null

dd if=/dev/zero of=large.yaml bs=1048576 count=5 2>/dev/null
git add large.yaml
commit 'large YAML'
grep -F 'large.yaml' "$base/log" | grep -F '4 MiB' >/dev/null

touch veto
if git commit --allow-empty -qm 'independent hook must block'; then exit 1; fi
rm veto

# A missing executable is an advisory failure too.
ADVICE_TEST_BINARY="$base/missing" git commit --allow-empty -qm 'advice unavailable' > "$base/log" 2>&1
grep -F 'check unavailable' "$base/log" >/dev/null
echo 'Staged package advice and independent hook behavior: PASS'
