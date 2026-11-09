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

    run_consumer() {
        local test_dir="$1" consumer="$2"
        shift 2
        cp "$consumer" "$test_dir/consumer.ts"
        if (( $# )); then cp "$@" "$test_dir/"; fi
        "$smoke_dir/node_modules/.bin/tsc" --strict --exactOptionalPropertyTypes --noEmit --target ES2022 \
            --module ESNext --moduleResolution Bundler --resolveJsonModule "$test_dir/consumer.ts"
        "$smoke_dir/node_modules/.bin/tsx" "$test_dir/consumer.ts"
    }
    check_consumer() {
        local package="$1" consumer="$2" test_dir="$work/$(basename "$2" .ts)"
        shift 2
        mkdir "$test_dir"
        "$compiler" compile "$package" --target typescript --out "$test_dir/generated"
        run_consumer "$test_dir" "$consumer" "$@"
    }
    check_consumer "$smoke_dir/examples/appointments.yaml" "$root/Examples/theatre-casting/typed-appointments.ts"
    check_consumer "$root/Examples/repository-membership/package.yaml" "$root/Examples/repository-membership/membership.ts"
    examcalc="$root/Examples/examcalc"
    check_consumer "$smoke_dir/packages/examcalc/versions/0.3.0-draft.1/domain-ontology-package.yaml" \
        "$examcalc/verify.ts" "$examcalc/verify-handoff.ts" "$examcalc/calculator.ts" "$examcalc/intent.json"
    imported="$root/Examples/imported-typed-reference"
    mkdir "$work/imported-reference"
    "$compiler" compile "$imported/model.yaml" --import "$imported/shared.yaml" \
        --target typescript --out "$work/imported-reference/generated"
    run_consumer "$work/imported-reference" "$imported/consumer.ts"

    inheritance="$root/Examples/typescript-inheritance"
    mkdir "$work/typescript-inheritance"
    "$compiler" compile "$inheritance/shared.yaml" --target typescript --out "$work/typescript-inheritance/base-generated"
    "$compiler" compile "$inheritance/model.yaml" --import "$inheritance/shared.yaml" \
        --target typescript --out "$work/typescript-inheritance/generated"
    run_consumer "$work/typescript-inheritance" "$inheritance/consumer.ts"

    protocols="$root/Examples/typescript-imported-protocol"
    mkdir "$work/typescript-imported-protocol"
    "$compiler" compile "$protocols/model.yaml" --import "$protocols/parent.yaml" --import "$protocols/contracts.yaml" \
        --target typescript --out "$work/typescript-imported-protocol/generated"
    run_consumer "$work/typescript-imported-protocol" "$protocols/consumer.ts"
fi
