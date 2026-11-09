# ONT-089 — Source-bound protocol conformance

## Problem

`requiredFields` is checked against relation names in the compiler while the
SDK treats it as an instance field. Imported protocol relation obligations are
not validated. This can report false conformance or generate a property that
was never declared by an implementing class.

## Contract and outcome

In the current package format a protocol's `requiredFields` names mandatory
string instance fields. A class implementing it must explicitly declare each
field as required and string, or inherit such a declaration from a verified
ancestor. Protocol declarations alone do not invent fields in instances.
`requiredRelations` names relation declarations whose subject/domain is the
implementing class or a verified ancestor. Relations and instance fields are
separate obligations even when their names are the same.

Resolve each protocol and ancestor in the declaring package's alias scope,
using explicitly supplied package identity and version. An unavailable source
is unverified, not proof of conformance or of a missing obligation. Foundation
export tables and foundation declaration properties are not instance fields.
No network resolution is introduced.

## Acceptance criteria

- Strict source validation and SDK generation reject a missing, optional or
  incompatible required field, including when an unrelated relation has the
  same name. Valid explicit and inherited fields reach TypeScript and Zod.
- Required relations are checked for local and imported protocols and inherited
  class ancestry; an unrelated same-named class or relation cannot satisfy one.
- Exact import versions and declaring-package aliases govern all checks;
  missing protocol or ancestry sources yield explicit unverified diagnostics.
- Snapshot/index advice identifies the affected source. Positive and negative
  tests cover direct, inherited, transitive and alias-collision cases.
- Existing examples are migrated to the clarified contract; generated outputs,
  docs and portable checks remain reproducible.
- Swift quality, coverage and relevant real TypeScript/Zod and portable smokes
  run with build output on the verified TB5 volume.

## Worktree and delivery

Reuse `.worktrees/Ontology-examcalc-speech` on
`feature/ONT-089-protocol-conformance`; retire the execution tree after the PR
is merged and its local state has been checked. Release the updated compiler,
then update actual downstream consumers and verify deployment where affected.
