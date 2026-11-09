# REVIEW REPORT — ONT-084

**Scope:** ONT-084 commits above `feature/ONT-083-foundation-model-catalog`.
**Verdict:** Approve locally, with downstream integration and DOT parity pending.

## Findings and corrections

- **Medium, corrected:** a profile's new model file initially was not part of
  the workspace snapshot. It is now resolved and pinned, its bytes are checked
  before and after visualization, and stale output is rejected.
- **Medium, corrected:** an unbounded catalog read could consume arbitrary
  memory. The compiler and workspace now limit count and stream at most 1 MiB
  plus one byte per model; oversized input is covered in both paths.
- No further blocking issue found in local self-review. This is not an
  independent review or evidence of deployment.

## Architectural notes

Version/identity/alias matching uses the explicit reachable import closure.
The legacy import identity and actual catalog identity are both shown. Catalog
digests are checked by the visualizer against known bytes, whereas an arbitrary
projection opened in the browser is only a report, not authenticated evidence.
An absent definition is left unresolved. Existing output is unchanged when no
model is supplied.

## Validation and remaining work

See [validation](ONT-084_Validation_Report.md).
The deployed site still requires a released Ontology version, a regenerated
SpecGraph graph, and a SpecSpace update. DOT and image generation do not yet
display model-backed definitions; the CLI rejects that combination explicitly.
Record the latter as a follow-up rather than silently producing a partial view.
