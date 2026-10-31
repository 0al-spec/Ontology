# ONT-055 — Release Binaries

A developer should be able to download a built ontologyc from the release page.
GitHub Actions should build the exact tagged source and locked dependencies for
macOS arm64 and Linux x86_64. Package a runnable CLI, license notices and
source identity. Extract each archive and exercise check and TypeScript compile.
Test the Linux download on Ubuntu without a Swift toolchain.

Use a read-only packaging preview on PRs. A release event or a default-branch
dispatch for an existing release may attach both archives and SHA256SUMS after
both platform checks succeed. Preserve existing release notes and assets,
reject conflicting bytes and verify the tag still identifies the build commit.

Validation includes the repository quality gate, negative publication controls,
local packaging and hosted platform previews. Existing tags remain stable.
