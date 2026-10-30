# REVIEW REPORT — ONT-054 Optional Local Package Sections

Date: 2026-10-30. Reviewer: root agent, separate from the Sol 6.1 High implementer.
Scope: main `1a47f7058228efb412cbdeaabbaf27bca25e9846` through implementation
`1691287` and archive checkpoint `a622125`. Hosted review is still separate.

## Verdict

Approve for focused PR publication. No unresolved actionable findings in this
bounded change. FOLLOW-UP is skipped; optional future capabilities are not
silently converted into defects or implementation commitments.

## Correctness and retained boundaries

- Optionality is limited to the two named maps. Presence uses an explicit key
  check and the existing typed-object reader, so `null` and non-map values do
  not turn into valid empty declarations. Existing diagnostic paths are retained.
- Schema and fixture behavior agree for omitted/empty sections. Classes,
  relations and imports remain required. Existing validation of supplied policy
  and machine definitions is unchanged, including lifecycle reference checks.
- Normalization/emission code is untouched. The existing generated-artifact
  baseline passes, and empty sections retain all documented SDK surfaces.
- Ruby class-field support repairs a reproduced existing fixture failure. It
  validates the known contract and requires all expected negative diagnostics;
  it does not merely allow an unchecked key or claim full schema equivalence.
- Saved image-pilot intent, generated IR and observations remain unchanged.
  README wording identifies the old requirement as historical.

## Independent verification

Reviewed the implementation, schema, fixtures, new tests, compiler contract and
source/log hashes. Independently ran SpecGraph's actual model through its full
pilot after deleting only the padding sections in a scratch copy. Old compiler:
rejection. Candidate: compiler/typecheck/model/behavior all passed, no findings.
The source inventory stayed partial and the production outcome stayed invalid
with its required diagnostics.

The implementer's complete quality log confirms 166 Swift tests, 90.22% line
coverage, formatting/lint/import gates and the byte-for-byte existing baseline.
Ruby fixtures passed 10/10, with 19 additional controls. The first assertion
failure was formatting-sensitive test code and is corrected by parsing exported
JSON; it was not hidden by changing generator output.

## Limits and next action

Local macOS evidence does not certify hosted Linux CI or merge readiness. The
consumer used an explicit unmerged compiler binary, recorded by hash; SpecGraph
has not changed its dependency pin. Review and merge Ontology first, then choose
a stable revision for downstream adoption. Namespace-only imported symbol
handling and profile-specific instance validation retain their prior scope.
