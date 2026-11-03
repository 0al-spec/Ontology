# ONT-072 author review

Reviewed the vocabulary change, import binding, public authoring examples and theatre replay against the PRD. The compiler picks the catalog by both package ID and version; the current catalog excludes both actor kinds. Each import alias carries its own symbol table. Updated the fixture checker and release smoke to use the matching version, and checked the authoring prompts for stale guidance.

The two casting observations use the existing eventcore-v1 structural authority. The negative delta and dangling reference fail for their expected codes, while changing a director to another existing person remains structurally admissible. The domain cast relation still has multiplicity zero or one. No new runtime event primitive is necessary.

Local verdict: pass. Hosted CI and independent review belong to the PR.
