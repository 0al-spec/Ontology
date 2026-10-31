## REVIEW REPORT — ONT-062 shared graph projection

**Scope:** `origin/main..5fbb7f2` and the Linux decoding probe recorded in the validation report.
**Method:** author self-review; independent hosted review remains pending.

### Summary verdict

- [x] Approve locally with the documented scope
- [ ] Request changes

### Critical and secondary issues

No unresolved implementation findings in this bounded slice. During development
the raw-byte digest for BOM input was corrected and independently distinguished
from the existing normalized compiler digest. The compiler reads and hashes one
snapshot per selected file; callers must still compare the byte digest again
before any future edit. No editing operation is added here.

### Architecture and tests

- DOT and JSON consume one selection; imported identities, aliases, oneOf,
  unloaded references, source pointers and overwrite protection are covered.
- The projection is a versioned declaration graph, not a lossless YAML AST or
  a ready-made layout. Its arrays and normalized fields still require an adapter
  for a particular interactive canvas. No independent UI or downstream contract
  is claimed to have adopted this version.
- Local Swift quality, coverage, golden image-source parity, TypeScript smoke,
  generated-output baselines and both DocC builds passed. The Linux Foundation
  probe is narrower than the hosted Linux matrix, which remains pending.

### Next steps

Publish the focused PR and retain its task worktree through review. A subsequent
slice can consume this graph in a standalone read-only interactive canvas,
then design source-preserving edits and live file updates. FOLLOW-UP is skipped:
these are the already-agreed next slices, not defects found in ONT-062.

### External review follow-up

An external reviewer found unstable ordering with two contributing imports. The
implementation now sorts by root-scoped import alias before collecting relations;
the regression confirms that reversing the actual imports preserves JSON bytes.
Hosted CI also exposed BOM parsing on older Swift versions; the shared loader now
normalizes the BOM before parsing and both file and string paths are covered.
The focused suite passed on macOS and in Linux/arm64 Swift 6.0. The original
thread remains available for reviewer verification of the updated PR.
