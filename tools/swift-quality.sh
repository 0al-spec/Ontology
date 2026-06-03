#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

require_tool() {
    local tool="$1"
    local install_hint="$2"

    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "error: $tool is not installed. $install_hint" >&2
        exit 127
    fi
}

run_tests() {
    local scratch="$1"
    # Use the default (native) build system: it works on the package's
    # declared Swift 6.0 floor (`--build-system swiftbuild` requires 6.2+)
    # and matches the coverage path, which must stay native because
    # swiftbuild does not emit a usable default.profdata.
    swift test --scratch-path "$scratch"
}

run_coverage() {
    local scratch="$1"
    swift test --enable-code-coverage --scratch-path "$scratch"

    local profile
    profile="$(find "$scratch" -name default.profdata -print -quit)"
    if [[ -z "$profile" ]]; then
        echo "error: coverage profile was not generated" >&2
        exit 1
    fi

    local test_binary
    test_binary="$(find "$scratch" -path "*.xctest/Contents/MacOS/*" -type f ! -path "*.dSYM/*" -print -quit)"
    if [[ -z "$test_binary" ]]; then
        echo "error: XCTest binary was not found for coverage reporting" >&2
        exit 1
    fi

    xcrun llvm-cov report "$test_binary" \
        -instr-profile "$profile" \
        -ignore-filename-regex="(\\.build|checkouts|Tests|OntologyPackageTests\\.derived)/"
}

require_tool swiftformat "Install with: brew install swiftformat"
require_tool swiftlint "Install with: brew install swiftlint"

swiftformat Sources Tests --lint
if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    swiftlint lint --config .swiftlint.yml --reporter github-actions-logging
else
    swiftlint lint --config .swiftlint.yml
fi
if [[ -n "${ONTOLOGY_SWIFT_SCRATCH_PATH:-}" ]]; then
    scratch="$ONTOLOGY_SWIFT_SCRATCH_PATH"
    mkdir -p "$scratch"
else
    tmp_root="${TMPDIR:-/tmp}"
    scratch="$(mktemp -d "${tmp_root%/}/ontology-quality.XXXXXX")"
    trap 'rm -rf "$scratch"' EXIT
fi

# Run the build gate inside the scratch path too, so it does not write to
# the repo's default .build/ and all gate artifacts stay contained.
swift build --explicit-target-dependency-import-check error --scratch-path "$scratch"

if [[ "${RUN_COVERAGE:-0}" == "1" ]]; then
    run_coverage "$scratch"
else
    run_tests "$scratch"
fi
