#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
smoke_dir="$root/SPECS/ontology"

cd "$smoke_dir"

npm ci --no-audit --no-fund
npm run typecheck
npm run smoke
