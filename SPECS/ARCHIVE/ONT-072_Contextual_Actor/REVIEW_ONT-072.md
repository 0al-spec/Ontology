# ONT-072 author review

Reviewed the vocabulary change, import binding, public authoring examples and theatre replay against the PRD. The compiler picks the catalog by both package ID and version; the current catalog excludes both actor kinds. Each import alias carries its own symbol table. Updated the fixture checker and release smoke to use the matching version, and checked the authoring prompts for stale guidance.

The two casting observations use the existing eventcore-v1 structural authority. The negative delta and dangling reference fail for their expected codes, while changing a director to another existing person remains structurally admissible. The domain cast relation still has multiplicity zero or one. No new runtime event primitive is necessary.

Local verdict: pass. Hosted CI and independent review belong to the PR.

For the action-bearing relationship follow-up, the CLI and a freshly generated
TypeScript consumer check two different boundaries: a declaration must name a
verified Action class, and a constructed relationship must carry the specific
action declared for it. Both tests include a legitimate second action. A
domain author can deliberately rebind the declaration; the compatibility diff
reports such a change as breaking. The previously installed commit hook does
not recognize the new field. Running `advise-staged` from the branch build on
the same staged fixture produced no warnings.
