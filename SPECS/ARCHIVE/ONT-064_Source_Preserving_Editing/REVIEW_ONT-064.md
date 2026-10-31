## REVIEW REPORT — ONT-064 source-preserving editing

**Scope:** ONT-064 commits above `feature/ONT-063-interactive-viewer`.
**Method:** author self-review; independent review remains pending.

### Findings

The initial README test command omitted the compiler, visualizer and frontend
paths required by the new workspace browser tests. Resolved in the follow-up:
the example command now names those inputs.

An external review then identified that refreshing a selected transition could
show another transition from the same machine. The follow-up tracks the exact
edge and clears selection if its transition changes; a Chromium regression uses
the real motivation-core machine and checks both cases.

No further in-scope findings were identified. The service binds to loopback,
restricts writes to the chosen root, rejects stale digests and preserves a dirty
buffer on external edits. Atomic rename is not a filesystem compare-and-swap,
and ACLs, extended attributes and hard-link identity are not guaranteed; these
limits are recorded in the README and validation report.

### Verification

Five model/source-text tests, the production TypeScript build and five desktop/
mobile Chromium tests passed locally with real compiler and visualizer binaries.
These checks do not substitute for hosted CI, independent review or graphical
declaration editing. The latter remains a possible later layer.

### Subsequent review follow-up

Addressed the reported retry and Unicode cases, along with retargeted input
symlinks, transient visualization failures and ambiguous mixed-line-ending
edits. Selection now retains the graph node ID instead of matching its label.
The focused regressions exercise real browser editing and process-level races;
the validation report records their boundaries. Re-review and current-head CI
remain separate from this author follow-up.
