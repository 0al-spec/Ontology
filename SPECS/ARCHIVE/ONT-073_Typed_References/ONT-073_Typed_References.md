# ONT-073 — Typed action reference pilot

Allow a package to declare a field with `type: ref` and a local class `target`.
Preserve the target in normalized IR, compatibility diffs, the generated TypeScript
field and incoming record validation. Existing primitive fields keep their contracts.

Use one `AddRepository.repository` field in the pilot. Its target is Repository.
A consumer chooses and resolves either a database key or a graph address. Verify
both reach the same repository, a Project reference fails type checking, and
unknown addresses leave membership unchanged. Compilation cannot prove liveness.
