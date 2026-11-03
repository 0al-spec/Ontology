# ONT-072 follow-up: action-bearing relationships

An author needs to reuse one action in multiple domain relationships. Bind the
action once in each relationship declaration and retain its identity for typed
SDK construction. An unrelated action at a call site must fail type checking.

- Declare Appoint and Cancel as foundation Action specializations. CastAppointment
  and CrewAppointment each take Person, Appoint and Person.
- Preserve the selected action in normalized IR and generated TypeScript.
- Refuse an unknown action, a class of the wrong kind and an unverified external
  action. Preserve plain binary relations used by existing packages.
- Demonstrate a valid triple and a rejected substitution of Cancel for Appoint.
- Define package-level diagnostics and keep the boundary with runtime observation explicit.
