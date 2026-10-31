# ONT-057 — Resolve Foundation Exports

A declared namespace currently makes a nonexistent imported class pass validation.
The source case from SpecGraph #843 changes only Entry.extends from sg:ValueObject
to sg:Typo. Both release 0.3.0 commands accepted the typo.

Bind specgraph.foundation 0.1.0 to an embedded typed inventory and publish a
deterministic JSON export. Check import aliases, version and name collisions.
Apply role-specific exports at every package slot that accepts imported class,
protocol or policy refs. Preserve successful IR/SDK bytes. Keep other packages'
namespace-only compatibility explicit until their exports are supplied.

Expose check diagnostics in JSON for downstream code and keep text as the
default. Run rule, CLI, Ruby fixture and real downstream reproduction controls.
Publish the upstream change through its own PR. The release pin and migration
of SpecGraph's open pilot depend on a later release.
