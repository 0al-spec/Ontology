# Event Core 0.2.0 — draft provenance revision

Package: `org.0al.events.core@0.2.0`, namespace `eventcore`, approvalStatus draft.
This separately stored revision preserves the frozen [0.1.0 package](../../README.md)
and eventcore-v1 consumers. It adds three origin classes, four relations and two
manual policy declarations: 21 classes, 32 relations and seven policies total.

The governing record/candidate separation stays unchanged. Every snapshot in the
new [eventcore-provenance-v1 profile](../../../../instance-graph/provenance/README.md)
needs exactly one source/direct/operator origin and explicit external confirmation.
Unknown/partial candidates may remain source-only. Known/partial evidence must be
preserved on enrichment. Empty states cannot be substituted for missing data.

Authoring evidence is in authoring/: intent, classification, product draft,
critique, competency questions and domain-ontology-package-draft.yaml. The assembled
YAML is byte-identical to that draft. generated/ contains ten compiler-generated
IR/SDK files. Policy text is inert; relation/admission checks belong to the pinned
instance profile. The generated object schemas alone do not implement them.

Origin confirmation under a caller-selected authority file is separate from source
presence, identity authenticity and factual truth. The prototype does not verify
signatures, fetch artifacts, establish legal responsibility or migrate historical
reports. The source-only NormLab boundary remains available until a producer
explicitly supplies complete states and admissible provenance.
