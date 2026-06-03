#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

hash_files() {
    local files=()
    for file in "$@"; do
        if [[ -f "$file" ]]; then
            files+=("$file")
        fi
    done

    if [[ ${#files[@]} -eq 0 ]]; then
        printf 'none'
        return 0
    fi

    shasum -a 256 "${files[@]}" | shasum -a 256 | awk '{print $1}'
}

swift_fragment() {
    if command -v swift >/dev/null 2>&1; then
        local version
        version="$(swift --version 2>/dev/null | head -n 1 || true)"
        if [[ -n "$version" ]]; then
            printf '%s' "$version" | shasum -a 256 | awk '{print substr($1, 1, 16)}'
        else
            printf 'swift-version-unavailable'
        fi
    else
        printf 'swift-unavailable'
    fi
}

runner_fragment() {
    local os="${RUNNER_OS:-$(uname -s)}"
    local arch="${RUNNER_ARCH:-$(uname -m)}"
    printf '%s-%s' "$os" "$arch" | tr '[:upper:]' '[:lower:]'
}

package_hash="$(hash_files Package.swift Package.resolved)"
quality_hash="$(hash_files .swiftformat .swiftlint.yml tools/ci-cache-key.sh tools/swift-quality.sh tools/install-quality-tools.sh tools/check-github-actions-node24.sh)"
workflow_hash="$(hash_files tools/ci-cache-key.sh .github/workflows/swift-quality.yml .github/workflows/documentation.yml)"
swift_hash="$(swift_fragment)"
runner="$(runner_fragment)"

cat <<EOF
runner-fragment=$runner
swift-fragment=$swift_hash
package-hash=$package_hash
quality-hash=$quality_hash
workflow-hash=$workflow_hash
swiftpm-cache-key=ontology-swiftpm-$runner-$swift_hash-$package_hash
quality-tools-cache-key=ontology-quality-tools-$runner-$quality_hash
quality-build-cache-key=ontology-quality-build-$runner-$swift_hash-$package_hash
docc-cache-key=ontology-docc-$runner-$swift_hash-$package_hash-$workflow_hash
EOF
