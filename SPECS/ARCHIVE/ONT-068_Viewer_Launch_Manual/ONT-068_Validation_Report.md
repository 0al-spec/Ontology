# ONT-068 validation

Date: 2026-10-31. Verdict: PASS for the bounded local manual walkthrough.
Hosted CI/review remain separate.

## Executed
The pinned code revision 7da2e7c was extracted with git archive into a new TB5
directory, containing no ignored dependencies, prebuilt tools or pilot data.
The setup shell block was executed with fresh Swift products and npm-installed
node_modules. Download caches were shared by explicit symlinks; this was not
a cache-free machine or a literal execution of the git-clone block.
Dummy ontologyc/ontologyviz executables on PATH exit 99: the recipes still passed
using their explicit source-built paths.

Actual host: macOS arm64, Swift 6.4, Node 26.5.0, npm 12.2.0, Git 2.54.
Node 24 is recommended to match the viewer CI configuration; this walkthrough
did not execute Linux, Node 20/24 or Swift 6.0 locally.

Both launch blocks ran from the manual:
- Read-only Vite endpoint returned HTML; generated full JSON includes two source
  packages, policies and state machines, without a workspace session token.
- Built workspace returned HTML/assets and a full API graph with no tool/graph
  error. Saving changed only copied YAML, preserving the snapshot source.
- Repeating preparation preserved edited copied YAML and a customized existing
  profile. Servers were stopped using SIGINT to their isolated process groups.
- All five shell blocks passed bash syntax checking; 40 local Markdown links in
  the manual and two entry READMEs resolve. Git whitespace checks passed.
- Temporary harness/logs/receipt: TB5 project build directory /launch-manual.
  No user model, NormLab source or installed compiler was modified.

These are startup/HTTP/API checks, not a new visual browser walkthrough or a new
run of the parent viewer regression suite. No product runtime code changed.

## Existing dependency findings
npm ci succeeded but npm audit reported six advisories in the pinned dependency
tree (three moderate, one high, two critical), involving Vite/Vitest and their
transitive development tools. Audit severity is not an exploitability assessment.
No automatic fixes or dependency changes were applied. npm 12 also reported
blocked install scripts; both launch modes still succeeded.
Track dependency investigation separately as a follow-up, not as an assertion
that successful startup is security acceptance.

## Review correction: new-terminal restart

The initial walkthrough did not execute the abbreviated restart paragraph from
the checkout root. Review thread PRRT_kwDOStULqM6yT-hi identified the missing
package-directory change. The manual now includes the explicit directory change
and the complete workspace command instead of referring to an earlier command.

Executed the revised restart shell block in a new Bash process starting from the
isolated checkout root, with restored path variables and recomputed CLI bin path.
HTTP HTML and the session API returned a full graph without compiler/graph errors.
The existing copied YAML and customized profile remained byte-identical; the
test server was stopped. All six current shell blocks pass bash syntax checking.
Receipt: launch-manual/restart-review-fix-receipt.json in the TB5 build directory.
No dependency install, compiler rebuild or new visual browser walkthrough was
needed for this documentation correction.
