# Downloading ontologyc

GitHub Releases built with the Release binaries workflow carry two archives,
`ontologyc-<tag>-macos-arm64.tar.gz` and `ontologyc-<tag>-linux-x86_64.tar.gz`,
plus `ontologyc-SHA256SUMS`. Each archive contains an executable, license
notices and `BUILD.txt` with the tag, source commit, platform and Swift toolchain.
The macOS CLI is built for Apple Silicon and tested on macOS 15. It has no
Developer ID notarization. The Linux build targets x86_64 Ubuntu 22.04,
links the Swift standard library statically and is exercised in an Ubuntu
environment with system curl, XML and ICU libraries and no Swift toolchain.

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

On macOS select `macos-arm64` and use `shasum -a 256 -c -` for the checksum
check. GitHub supplies the source archives separately. Source-only releases
can receive binaries through a maintainer backfill.

## Maintainers

Publishing a GitHub Release triggers the workflow and preserves its notes, tag,
prerelease and latest settings. The release tag must be a numeric version, such
as `0.3.0`. Both builds check out the same peeled Git commit, use
`Package.resolved` and exercise the extracted CLI. The publisher rechecks the
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
