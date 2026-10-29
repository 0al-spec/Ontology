# ONT-053 — Reader-Oriented Project Story

Status: PRD Ready. Selected by the user on 2026-10-29.

## Problem and intended result

The root README leads with compiler internals and a historical golden package.
The action/state vocabulary, working intent-preservation examples and connection
to formal verification are buried or absent. Some roadmap statements are stale.
The reader should understand why the repository exists before choosing a command.

## Deliverables

- An English README, preserving the repository's existing public language, with
  a concise problem/solution opening, a concrete image example, a visual action
  model, current capabilities and meaningful next actions.
- An explicit Lean section linking NormLab's implemented formal models, while
  distinguishing ontologyc structural checks and Python pilot evidence.
- Accessible operational documentation for compiler/integration workflows moved
  out of the entry point if needed, with valid relative links.
- A claim/link validation report and independent review of readability and scope.

## Acceptance and evidence

1. Explain semantic drift and the cost of reading generated code; show how a
   small original intent and per-boundary differences expose an unwanted change.
2. Explain Entity, actor roles, Action/Omission, State/Delta, Goal and Motive
   without restricting actors to humans or inferring responsibility from a role.
3. Identify implemented components and draft/profile limits accurately. Do not
   claim automatic universal translation, arbitrary-code equivalence, physical
   truth or that the current Python pilots run Lean.
4. Explain the useful combination of modeling, versioning and scoped evidence;
   avoid unsupported claims to invention of ontologies or formal methods.
5. Preserve build/check examples, supported platforms, documentation and license.
6. Verify local links and referenced implementation/docs; run the documentation
   gates in .flow/params.yaml and git diff checks. No runtime changes or new tests.

## Scope and workflow

Only documentation and FLOW records. No compiler, package IR, Lean or application
code changes. NormLab's README is a coordinated separate PR owned in that repo.
Use a new branch from merged main, then PLAN → EXECUTE → ARCHIVE → REVIEW →
ARCHIVE-REVIEW. FOLLOW-UP only for unresolved actionable findings. Publish a PR;
merge/release/deployment are not part of this task.
