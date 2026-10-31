#!/usr/bin/env bash
# Arguments are absolute paths so SwiftPM and tar can run outside the checkout.
set -euo pipefail
source_dir=$1
scratch=$2
out=$3
platform=$4
: "${BUILD_LABEL:?}" "${SOURCE_SHA:?}"
test "$(git -c safe.directory="$source_dir" -C "$source_dir" rev-parse HEAD)" = "$SOURCE_SHA"
case "$BUILD_LABEL" in ''|*[!A-Za-z0-9.+-]*) exit 2 ;; esac

build=(--package-path "$source_dir" --scratch-path "$scratch" --configuration release --force-resolved-versions)
if [[ -n ${SWIFT_PACKAGE_CACHE:-} ]]; then build+=(--cache-path "$SWIFT_PACKAGE_CACHE"); fi
case "$platform:$(uname -sm)" in
  macos-arm64:Darwin\ arm64) ;;
  linux-x86_64:Linux\ x86_64) build+=(--static-swift-stdlib) ;;
  *) echo "Runner does not match $platform" >&2; exit 1 ;;
esac
swift build "${build[@]}" --product ontologyc
bin_dir=$(swift build "${build[@]}" --show-bin-path)

name="ontologyc-$BUILD_LABEL-$platform"
mkdir -p "$out"
stage=$(mktemp -d "${TMPDIR:-/tmp}/ontologyc-stage.XXXXXXXX")
trap 'rm -rf "$stage"' EXIT
root="$stage/$name"
mkdir -p "$root/licenses"
install -m 755 "$bin_dir/ontologyc" "$root/ontologyc"
cp "$source_dir/LICENSE" "$root/LICENSE"
cp "$scratch/checkouts/Yams/LICENSE" "$root/licenses/Yams.txt"
cp "$(dirname "$0")/notices/libyaml.txt" "$root/licenses/libyaml.txt"
if [[ -d "$source_dir/Vendor/SpecificationCore" ]]; then
  cp "$(dirname "$0")/notices/SpecificationCore.txt" "$root/licenses/SpecificationCore.txt"
elif [[ -d "$scratch/checkouts/SpecificationCore" ]]; then
  cp "$scratch/checkouts/SpecificationCore/LICENSE" "$root/licenses/SpecificationCore.txt"
fi
if [[ $platform == linux-x86_64 ]]; then
  cp "$(dirname "$0")/notices/BoringSSL.txt" "$root/licenses/BoringSSL.txt"
  cp /usr/share/swift/LICENSE.txt "$root/licenses/Swift-runtime.txt"
  for dep in swift-crypto swift-asn1; do
    for notice in LICENSE NOTICE; do
      cp "$scratch/checkouts/$dep/$notice.txt" "$root/licenses/$dep-$notice.txt"
    done
  done
fi
{
  printf 'ref=%s\ncommit=%s\nplatform=%s\n' "$BUILD_LABEL" "$SOURCE_SHA" "$platform"
  swift --version
} > "$root/BUILD.txt"
COPYFILE_DISABLE=1 tar -C "$stage" -czf "$out/$name.tar.gz" "$name"
mkdir "$stage/smoke"
tar -xzf "$out/$name.tar.gz" -C "$stage/smoke"
fixture="$source_dir/SPECS/ontology/packages/examcalc/domain-ontology-package.yaml"
"$stage/smoke/$name/ontologyc" check "$fixture"
"$stage/smoke/$name/ontologyc" compile "$fixture" --target typescript --out "$stage/generated"
cmp "$stage/generated/ontology.normalized.json" "$source_dir/SPECS/ontology/packages/examcalc/generated/ontology.normalized.json"
