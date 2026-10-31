# Downloading ontologyc and ontologyviz

GitHub Releases built with the Release binaries workflow carry two archives,
`ontologyc-<tag>-macos-arm64.tar.gz` and `ontologyc-<tag>-linux-x86_64.tar.gz`,
plus `ontologyc-SHA256SUMS`. For source tags declaring both products, each
archive contains the `ontologyc` and `ontologyviz` executables, license notices
and `BUILD.txt` with the tag, source commit, platform and Swift toolchain.
Tags predating `ontologyviz` retain compiler-only archives; current workflow
helpers do not add features absent from a selected tag's source.
The macOS CLI is built for Apple Silicon and tested on macOS 15. It has no
Developer ID notarization. The Linux build targets x86_64 Ubuntu 22.04,
links the Swift standard library statically and is exercised in an Ubuntu
environment with system curl, XML and ICU libraries and no Swift toolchain.
Graphviz is an external dependency and is not bundled. Install it for SVG/PNG
(`brew install graphviz` or `sudo apt-get install graphviz`); DOT-only export
with `--format dot` does not need it.

Download the archive for your machine and the checksum list into a fresh directory.
For example, on Linux, replace `TAG` with the published version:

```sh
tag=TAG
archive="ontologyc-$tag-linux-x86_64.tar.gz"
gh release download "$tag" --repo 0al-spec/Ontology --pattern "$archive" --pattern ontologyc-SHA256SUMS
awk -v file="$archive" '$2 == file' ontologyc-SHA256SUMS | sha256sum --check -
tar -xzf "$archive"
"./ontologyc-$tag-linux-x86_64/ontologyc" check path/to/domain-ontology-package.yaml
```

When the selected release includes `ontologyviz`, use the executable beside
`ontologyc` with any local ontology package or saved profile:

```sh
"./ontologyc-$tag-linux-x86_64/ontologyviz" \
  --profile /path/to/Ontology/Examples/package-visualization/motivation-relations.profile.json \
  --out diagrams/motivation-relations
```

The profile and its package inputs remain user-supplied local files; the binary
archives do not contain the examples or repository. See the
[visualization guide](../../Examples/package-visualization/README.md) for profile
path rules and format options. Run from any working directory using absolute
paths to the extracted executable and profile.

On macOS select `macos-arm64` and use `shasum -a 256 -c -` for the checksum
check. GitHub supplies the source archives separately. Source-only releases
can receive binaries through a maintainer backfill.

## Maintainers

Publishing a GitHub Release triggers the workflow and preserves its notes, tag,
prerelease and latest settings. The release tag must be a numeric version, such
as `0.3.0`. Both builds check out the same peeled Git commit, use
`Package.resolved` and exercise the extracted executables from a working directory
outside the checkout. The expected executable inventory is read independently
from the selected source manifest and passed to archive verification; missing,
empty or nonexecutable required binaries stop publication before checksums or
uploads. Both platforms compare compiler IR with the committed baseline. With
the saved motivation-relations profile present, the extracted visualizer produces
DOT/SVG/PNG, compares DOT with its committed baseline and checks rendered content
and PNG signature. Earlier visualization tags without that profile receive a
basic package-rendering smoke instead. The clean Linux runtime repeats both CLI
checks with external Graphviz installed and no Swift toolchain. SVG bytes and PNG
pixels are not compared across Graphviz versions. The publisher rechecks the
release ID and tag and verifies the uploaded asset digests before it succeeds.
Release assets reside on the existing Releases page. PR previews appear under
the corresponding Actions run and have read-only repository permissions.

After the workflow is on the default branch, backfill an existing mutable
release (including the source-only 0.3.0) using:

```sh
gh workflow run release-binaries.yml --repo 0al-spec/Ontology --ref main -f tag=0.3.0
```

A retry preserves byte-identical assets. A conflicting or incomplete asset
stops publication before further uploads. Inspect the existing bytes and
source identity before repairing a partial release. Use the manual entry point
when the release was created by automation that does not trigger another workflow.
Already-published immutable releases cannot be backfilled.
