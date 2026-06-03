#!/bin/bash
set -euo pipefail

mode="install"
if [[ "${1:-}" == "--check" ]]; then
    mode="check"
fi

tools_dir="${ONTOLOGY_CI_TOOLS_DIR:-$HOME/.ontology-ci/tools}"
mkdir -p "$tools_dir"
fingerprint_file="$tools_dir/.quality-tools-fingerprint"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

hash_files() {
    local files=()
    local file
    for file in "$@"; do
        if [[ -f "$root/$file" ]]; then
            files+=("$root/$file")
        fi
    done

    if [[ ${#files[@]} -eq 0 ]]; then
        printf 'none'
        return 0
    fi

    shasum -a 256 "${files[@]}" | shasum -a 256 | awk '{print $1}'
}

expected_fingerprint="$(hash_files .swiftformat .swiftlint.yml tools/ci-cache-key.sh tools/swift-quality.sh tools/install-quality-tools.sh)"

cache_fingerprint_matches() {
    [[ -f "$fingerprint_file" ]] && [[ "$(cat "$fingerprint_file")" == "$expected_fingerprint" ]]
}

if [[ -n "${GITHUB_PATH:-}" ]]; then
    echo "$tools_dir" >> "$GITHUB_PATH"
fi

export PATH="$tools_dir:$PATH"

ensure_tool() {
    local tool="$1"
    local formula="$2"
    local cached="$tools_dir/$tool"

    if [[ -x "$cached" ]]; then
        echo "Using cached $tool from $cached"
        if cache_fingerprint_matches && { "$cached" --version 2>/dev/null || "$cached" version 2>/dev/null; }; then
            return 0
        fi
        echo "Cached $tool is stale or unusable; refreshing it"
        rm -f "$cached"
    fi

    if command -v "$tool" >/dev/null 2>&1; then
        local resolved
        resolved="$(command -v "$tool")"
        echo "Using system $tool from $resolved"
        if [[ "$mode" != "check" ]]; then
            cp "$resolved" "$cached"
            chmod +x "$cached"
            echo "Cached $tool at $cached"
        fi
        return 0
    fi

    if [[ "$mode" == "check" ]]; then
        echo "error: $tool is not installed and not cached in $tools_dir" >&2
        return 127
    fi

    if ! command -v brew >/dev/null 2>&1; then
        echo "error: $tool is missing and Homebrew is not available" >&2
        return 127
    fi

    echo "Installing $formula with Homebrew"
    brew list "$formula" >/dev/null 2>&1 || brew install "$formula"

    local installed
    installed="$(command -v "$tool")"
    cp "$installed" "$cached"
    chmod +x "$cached"
    echo "Cached $tool at $cached"
}

ensure_tool swiftformat swiftformat
ensure_tool swiftlint swiftlint

if [[ "$mode" != "check" ]]; then
    printf '%s' "$expected_fingerprint" > "$fingerprint_file"
fi
