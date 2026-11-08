#!/usr/bin/env bash
set -euo pipefail

# Accept the same prebuilt executable that the portability gate tests.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compiler="$(cd "$(dirname "${1:?supply ontologyc}")" && pwd)/$(basename "$1")"
base="$(mktemp -d "${TMPDIR:-/tmp}/ontology-advice.XXXXXXXX")"
trap 'rm -rf "$base"' EXIT
commit_cmd=(git commit)
case "${2:-}" in
    "") ;;
    --rtk)
        command -v rtk >/dev/null || { echo 'RTK smoke requires rtk on PATH' >&2; exit 1; }
        commit_cmd=(rtk git commit)
        export RTK_DB_PATH="$base/rtk.db" RTK_TELEMETRY_DISABLED=1
        ;;
    *) echo 'usage: staged-package-advice-smoke.sh <ontologyc> [--rtk]' >&2; exit 2 ;;
esac
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
  imports: [{id: ontology.foundation, namespace: ont, version: 0.2.0}]
  classes:
    Entry: {extends: "ont:$1", description: A value.$2}
  relations:
    contains: {domain: Entry, range: Entry, cardinality: {min: 0, max: 1}}
EOF
}
commit() { "${commit_cmd[@]}" -qm "$1" >"$base/log" 2>&1 || { cat "$base/log" >&2; return 1; }; }
quiet() { if grep -F '[ontology advice]' "$base/log"; then return 1; fi; }

# The working copy is valid but the first commit (unborn HEAD) contains a typo.
package Typo '' > "$model"
git add -- "$model"
package ValueObject '' > "$model"
commit 'bad index, good worktree'
if ! grep -F "$model" "$base/log" | grep -F 'class.extends.unresolved' | grep -F 'spec.classes.Entry.extends' >/dev/null; then
    echo "The successful commit did not display the staged package diagnostic (${commit_cmd[*]})." >&2
    cat "$base/log" >&2
    exit 1
fi
git show "HEAD:$model" | grep -F 'ont:Typo' >/dev/null

git add -- "$model"
package Typo '' > "$model"
commit 'good index, bad worktree'
quiet
# Commit only an unrelated YAML, leaving the unstaged package error in place.
printf 'example:\n  kind: DomainOntologyPackage\n' > unrelated.yaml
git add unrelated.yaml
commit unrelated
quiet

package ValueObject ', implements: [ont:Auditable]' > "$model"
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

# Imported targets use the selected Git index, never similarly named worktree files.
mkdir -p 'imported deps'
cp "$root/Examples/imported-typed-reference/model.yaml" 'imported deps/model.yaml'
cp "$root/Examples/imported-typed-reference/shared.yaml" 'imported deps/shared.yaml'
git add -- 'imported deps/model.yaml' 'imported deps/shared.yaml'
printf 'not a package\n' > 'imported deps/model.yaml'
printf 'not a package\n' > 'imported deps/shared.yaml'
"$compiler" advise-staged --import 'imported deps/shared.yaml' > "$base/log" 2>&1
quiet

cp .git/index "$base/import-index"
sed 's/shared:Item/shared:Missing/g' "$root/Examples/imported-typed-reference/model.yaml" > 'imported deps/model.yaml'
GIT_INDEX_FILE="$base/import-index" git add -- 'imported deps/model.yaml'
GIT_INDEX_FILE="$base/import-index" "$compiler" advise-staged --import 'imported deps/shared.yaml' > "$base/log" 2>&1
grep -F 'class.field.target.unresolved' "$base/log" >/dev/null
"$compiler" advise-staged --import 'imported deps/shared.yaml' > "$base/log" 2>&1
quiet

cp "$root/Examples/imported-typed-reference/model.yaml" 'imported deps/model.yaml'
sed 's/version: 1.0.0/version: 2.0.0/' "$root/Examples/imported-typed-reference/shared.yaml" > 'imported deps/shared.yaml'
GIT_INDEX_FILE="$base/import-index" git add -- 'imported deps/model.yaml' 'imported deps/shared.yaml'
GIT_INDEX_FILE="$base/import-index" "$compiler" advise-staged --import 'imported deps/shared.yaml' > "$base/log" 2>&1
grep -F 'class.field.target.unresolved' "$base/log" >/dev/null
"$compiler" advise-staged --import 'imported deps/shared.yaml' > "$base/log" 2>&1
quiet

sed 's/ont:DomainEntity/ont:Typo/g' "$root/Examples/imported-typed-reference/shared.yaml" > 'imported deps/shared.yaml'
GIT_INDEX_FILE="$base/import-index" git add -- 'imported deps/shared.yaml'
GIT_INDEX_FILE="$base/import-index" "$compiler" advise-staged --import 'imported deps/shared.yaml' > "$base/log" 2>&1
test "$(grep -c 'class.extends.unresolved' "$base/log")" = 1
grep -F '"imported deps/shared.yaml" error class.extends.unresolved' "$base/log" >/dev/null

"$compiler" advise-staged --import 'imported deps/missing.yaml' > "$base/log" 2>&1
grep -F 'could not be checked' "$base/log" | grep -F 'missing' >/dev/null
printf '\377' > 'imported deps/non-utf8.yaml'
git add -- 'imported deps/non-utf8.yaml'
"$compiler" advise-staged --import 'imported deps/non-utf8.yaml' > "$base/log" 2>&1
grep -F 'could not be checked' "$base/log" | grep -F 'not UTF-8' >/dev/null
ln -s shared.yaml 'imported deps/symlink.yaml'
git add -- 'imported deps/symlink.yaml'
"$compiler" advise-staged --import 'imported deps/symlink.yaml' > "$base/log" 2>&1
grep -F 'could not be checked' "$base/log" | grep -F 'regular index file' >/dev/null

blob=$(git rev-parse ':imported deps/shared.yaml')
GIT_INDEX_FILE="$base/import-index" git update-index --force-remove 'imported deps/shared.yaml'
printf '100644 %s 1\t%s\n100644 %s 2\t%s\n' "$blob" 'imported deps/shared.yaml' "$blob" 'imported deps/shared.yaml' | \
    GIT_INDEX_FILE="$base/import-index" git update-index --index-info
GIT_INDEX_FILE="$base/import-index" "$compiler" advise-staged --import 'imported deps/shared.yaml' > "$base/log" 2>&1
grep -F 'could not be checked' "$base/log" | grep -F 'unmerged' >/dev/null
git reset -q -- 'imported deps/model.yaml' 'imported deps/shared.yaml' 'imported deps/non-utf8.yaml' 'imported deps/symlink.yaml'

touch veto
if "${commit_cmd[@]}" --allow-empty -qm 'independent hook must block'; then exit 1; fi
rm veto

# A missing executable is an advisory failure too.
ADVICE_TEST_BINARY="$base/missing" "${commit_cmd[@]}" --allow-empty -qm 'advice unavailable' > "$base/log" 2>&1
grep -F 'check unavailable' "$base/log" >/dev/null
echo 'Staged package advice and independent hook behavior: PASS'
