#!/bin/bash
set -euo pipefail

mode="install"
if [[ "${1:-}" == "--check" ]]; then
    mode="check"
fi

tools_dir="${ONTOLOGY_CI_TOOLS_DIR:-$HOME/.ontology-ci/tools}"
mkdir -p "$tools_dir"

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
        if "$cached" --version 2>/dev/null || "$cached" version 2>/dev/null; then
            return 0
        fi
        echo "Cached $tool is not usable; refreshing it"
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
