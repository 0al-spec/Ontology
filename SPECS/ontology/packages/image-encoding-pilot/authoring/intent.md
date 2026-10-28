# Intent — Image Encoding Pilot

User request 2026-10-28: build a bounded experiment that keeps user intent,
application ontology, Hypercode composition, actual code and evidence compact and
recognizable. The user should not have to reconstruct the intended action from
large AI-generated code or reasoning. This package is the descriptive ontology
layer, not an imposed general application architecture.

Stay inside one image-encoding behavior. Model the selected image document,
configured encoder, declared reencoding action, observed image-state projection
and explicit size criterion. Keep the same image identity for an in_place action;
a copy has a distinct identity. Preserve dimensions and resize are different
constraints. The pilot action kind is jpeg_reencode.

A SizeGoal selects reduction (before bytes minus after bytes) or final_size,
compares it with targetBytes using at_least, exactly or at_most, and declares
missingInput unknown. Missing observations are not zero values or an empty Delta.
Goal evaluation is unknown when the available information cannot decide it;
known violations may decide not_satisfied. Operation outcome is independent.

Operator/encoder actor/instrument roles depend on the selected interpretation.
The optional agency context preserves this scope without inventing motives,
awareness or prior goals. ImageState is not a complete physical StateSnapshot,
and this package makes no actual consequence, truth or causation claim.

Runtime semantics, supported combinations, measurements and checks belong to the
caller-owned Examples/intent-preservation profile. This package provides a real
draft and generated primitive schemas; it does not prove code equivalence, add an
InstanceGraph profile, build an app, or change surrounding store/device workflows.

The compiler's package format requires a nonempty state machine. The minimal
ReencodeRequest declaration is ready to requested on Reencode; it describes a
request only, with no asserted execution, image state change or goal satisfaction.
