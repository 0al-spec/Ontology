#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
smoke_dir="$root/SPECS/ontology"

# A built compiler enables tests against freshly generated SDKs.
compiler=${1:-}
if [[ -n "$compiler" && "$compiler" != /* ]]; then compiler="$PWD/$compiler"; fi

cd "$smoke_dir"

npm ci --no-audit --no-fund
npm run typecheck
npm run smoke

if [[ -n "$compiler" ]]; then
    work="$(mktemp -d "${TMPDIR:-/tmp}/ontology-typed-actions.XXXXXX")"
    trap 'rm -rf "$work"' EXIT
    ln -s "$smoke_dir/node_modules" "$work/node_modules"

    check_consumer() {
        local package="$1" consumer="$2" test_dir="$work/$(basename "$2" .ts)"
        shift 2
        mkdir "$test_dir"
        "$compiler" compile "$package" --target typescript --out "$test_dir/generated"
        cp "$consumer" "$test_dir/consumer.ts"
        if (( $# )); then cp "$@" "$test_dir/"; fi
        "$smoke_dir/node_modules/.bin/tsc" --strict --exactOptionalPropertyTypes --noEmit --target ES2022 \
            --module ESNext --moduleResolution Bundler --resolveJsonModule "$test_dir/consumer.ts"
        "$smoke_dir/node_modules/.bin/tsx" "$test_dir/consumer.ts"
    }
    check_consumer "$smoke_dir/examples/appointments.yaml" "$root/Examples/theatre-casting/typed-appointments.ts"
    check_consumer "$root/Examples/repository-membership/package.yaml" "$root/Examples/repository-membership/membership.ts"
    examcalc="$root/Examples/examcalc"
    check_consumer "$smoke_dir/packages/examcalc/versions/0.3.0-draft.1/domain-ontology-package.yaml" \
        "$examcalc/verify.ts" "$examcalc/verify-handoff.ts" "$examcalc/calculator.ts" "$examcalc/intent.json"
fi
