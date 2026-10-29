# REVIEW REPORT — ONT-052 Intent Preservation Contract

Scope: a6c781bfd8235ccec6f5bf82d8974f5c23b8884a..current task branch, including the new contract and both example consumers. Base PR #75 is unchanged.

## Summary verdict

Approve within the documented bounded reference scope. Independent review reran its original negative probe after the fixes; no remaining blocker was reported. This local review is not a GitHub approval or merge authorization.

## Correctness and evidence

- Coverage includes every baseline obligation at every declared stage boundary. Semantic change, adjacent/original judgments, actual outcomes and human decisions stay independent.
- Domain adapters own semantics. Generic validation does not infer behavioral truth from names or trust hashes as signatures.
- Freshness compares explicit current inventory. Import-time source/schema guards and snapshotted fresh workers prevent old cached code from claiming new bytes.
- A decision digest binds the complete receipt excluding the decision itself, preventing silent acceptance transfer to changed artifacts, observations or mappings.
- The shared report preserves unsupported content, missing coverage and known failures; empty known Delta and absent observations differ.

## Findings closed before publication

1. P2 cached cancellation module: reproduced independently; fixed with a snapshotted fixed worker in a fresh isolated Python process. Reproduction now reports violated for the changed failing implementation and binds its actual bytes.
2. CI discovery import path: the exact command initially failed. Added the explicit Examples import root; independent rerun passes 34 shared tests.
3. Final image baseline now conjoins observed configured behavior and original criterion retention. Separate goal outcomes remain visible when the evaluator is correct but the numerical goal is not achieved.
4. Shared report coverage denominator uses declared stages, so a missing boundary does not reduce expected coverage. Missing evidence remains visible.

## Tests

Primary run: 110 tests (34 common contract/render, 59 image including real tools, 17 cancellation). Independent reviewer reran 34 common and 17 cancellation tests plus isolated code-cache and human-decision transfer probes. Fresh CLI runs cover both successful profiles, image/cancellation drift and unknown initial state. Relative links, Python syntax and diff whitespace checks pass.

No Swift source or generated ontology IR changed. Hosted checks on the final PR revision remain separate from these local observations. No browser/device visual audit is claimed.

## Next steps

Review the compact common reports and the domain-bound profile claims in the separate PR above #75. Broader semantic adapters or application integration require their own bounded contracts. FOLLOW-UP skipped: no unresolved actionable defect; declared evidence limits are scope, not hidden guarantees.

## PR #76 bot feedback

Closed the two concrete follow-up defects: exporter cached-source mismatch and collapsed rows whose cited evidence does not support their declared success. Regression coverage includes both exporter import orders, all three problematic evidence variants, and a stale renderer module. No unresolved defect remains in this scope.

## Second external review follow-up

The review of ab53346 found two additional false-success paths, now covered by
real cancellation receipt mutations and shared validator tests:

1. Contradictory `change` and `adjacent` declarations now contribute `unknown`
   with a diagnostic. Independently supported violations remain visible. Valid
   refinement and correction back toward baseline have explicit positive controls.
2. Every evidence kind declares exact boundary/obligation subjects. The consumer
   rejects cross-subject reuse and dangling targets; no subjects are inferred from
   identifiers or artifact hashes. Explicit multi-subject evidence is permitted
   within the declared producer trust boundary.

The report's first card presents correspondence, freshness and human decision
together, without turning `satisfied` into acceptance. Unsupported subjects cannot
hide a row among collapsed preserved mappings. Historical draft receipts stay
unchanged and are not automatically upgraded.

All 129 local tests pass, including real ontologyc/Hypercode integration. Independent
review repeated both bypasses on a fresh receipt and ran 49 common/render plus 20
cancellation tests; no blocking finding. This update remains within ONT-052 and
does not change the earlier stack layers or authorize a merge.
