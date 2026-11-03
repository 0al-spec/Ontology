#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
smoke_dir="$root/SPECS/ontology"

# An optional built compiler enables the fresh-generation appointment contract test.
compiler=${1:-}
if [[ -n "$compiler" && "$compiler" != /* ]]; then compiler="$PWD/$compiler"; fi

cd "$smoke_dir"

npm ci --no-audit --no-fund
npm run typecheck
npm run smoke

if [[ -n "$compiler" ]]; then
    work="$(mktemp -d "${TMPDIR:-/tmp}/ontology-typed-appointments.XXXXXX")"
    trap 'rm -rf "$work"' EXIT
    "$compiler" compile "$smoke_dir/examples/appointments.yaml" --target typescript --out "$work/generated"
    cp "$root/Examples/theatre-casting/typed-appointments.ts" "$work/"
    # Resolve the pinned Zod dependency from the freshly generated SDK on both hosts.
    ln -s "$smoke_dir/node_modules" "$work/node_modules"
    cd "$work"
    "$smoke_dir/node_modules/.bin/tsc" --strict --exactOptionalPropertyTypes --noEmit --target ES2022 \
        --module ESNext --moduleResolution Bundler typed-appointments.ts
    "$smoke_dir/node_modules/.bin/tsx" typed-appointments.ts
fi
