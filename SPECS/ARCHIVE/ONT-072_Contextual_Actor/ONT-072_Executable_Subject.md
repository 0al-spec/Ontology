# ONT-072 follow-up — Execute a relationship through its subject

An author declares a named relationship with `subject`, `action` and `object`.
The subject and object are entities. The subject is the Actor for this action
on this object. The application supplies the behavior on that same identified
entity. Two appointment relationships can share one Appoint.

- Accept the named triple in package YAML. Keep existing endpoint pairs readable,
  reject mixed spellings and point diagnostics at the field the author wrote.
- Generate distinct TypeScript types for a stored record and an executable
  relationship. In the latter, require an identified subject that implements
  `run(action, object)` for the declared types and an identified object.
- In a fresh SDK, exercise an explicit call on Ivan appointing Anna. Reading or
  constructing a record performs zero actions. Reject a subject missing
  `run`, a subject that can only cancel, and a substituted action at typecheck.

Verification uses the compiler tests, Ruby fixtures, the strict generated SDK
consumer and the package's existing quality and portability checks.
