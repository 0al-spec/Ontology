# ONT-072 follow-up — Read a relationship from JSON

Generate a runtime schema for action-bearing relationships in the TypeScript SDK.
Select the branch by relationship name and validate subject, action and object
against the same class references as the static type. A consumer reading JSON
can pass an unknown value directly to the schema.

Use the theatre fixture to verify both appointments and the cancellation.
Reject a swapped action at `action.$type` with the expected action identifier.
Exercise a missing action and an unrecognized relationship. Keep existing
generated SDKs for packages without action-bearing relationships reproducible.
