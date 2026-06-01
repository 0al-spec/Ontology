# Hypercode Adoption Roadmap

**Status:** Exploratory roadmap
**Date:** 2026-06-01
**Scope:** Ideas for using the sibling `../Hypercode` project inside Ontology without changing current compiler behavior.

## TL;DR

Hypercode should first be used as an optional authoring and projection layer, not as a replacement for the current `DomainOntologyPackage` YAML contract.

The strongest fit is:

- `.hc` captures ontology, workflow, or semantic-binding structure.
- `.hcs` attaches metadata, context overlays, policy configuration, provenance, and environment-specific variants.
- The resolved output compiles ahead-of-time into existing Ontology artifacts: YAML packages, normalized IR, SpecGraph semantic bindings, or documentation examples.

The canonical production path remains:

```text
DomainOntologyPackage YAML -> ontologyc check/compile -> normalized IR + generated artifacts
```

Hypercode becomes safe to promote only after a spike proves that it can express the existing `examcalc` ontology without semantic loss.

## Current Hypercode Baseline

The sibling `../Hypercode` repository currently provides:

- a draft RFC for Hypercode and Hypercode Cascade Sheets;
- a minimal indentation-based `.hc` grammar;
- selectors by type, class, id, and direct-child structure;
- contextual `.hcs` rule groups such as `@env[production]`;
- cascade resolution concepts: specificity and source order;
- an ANTLR playground under `EBNF/`.

Important current constraints:

- `.hc` has hierarchy plus optional class and id markers only.
- `.hc` has no inline attributes or arguments.
- rich metadata must live in `.hcs` or in a later grammar extension.
- no Swift parser/runtime is currently part of Hypercode.
- no provenance, signing, or sandboxing model is specified for `.hcs` rules yet.

## Adoption Principles

1. Preserve existing Ontology behavior.
2. Keep YAML as the canonical compiler input until Hypercode proves lossless.
3. Prefer ahead-of-time compilation over runtime interpretation.
4. Make cascade resolution deterministic and auditable.
5. Require generated output provenance for every field derived from `.hcs`.
6. Do not introduce Ruby tooling.
7. Treat Hypercode as experimental until grammar and resolution semantics stabilize.

## Roadmap

### Phase 0: Alignment Notes

Purpose: capture the intended integration shape before implementation.

Deliverables:

- this roadmap;
- a short mapping note from Hypercode concepts to Ontology concepts;
- explicit non-goals for the first spike.

Success criteria:

- the team agrees that Hypercode is an optional authoring layer, not a new canonical source of truth;
- the first implementation candidate can be planned without touching production compiler logic.

### Phase 1: Ontology Authoring Spike

Purpose: test whether Hypercode can express the current golden ontology shape.

Candidate files:

```text
SPECS/ontology/examples/examcalc.ontology.hc
SPECS/ontology/examples/examcalc.ontology.hcs
SPECS/ontology/examples/examcalc.hypercode-mapping.md
```

Candidate `.hc` shape:

```text
Ontology#examcalc
  Class.DomainEntity#Exam
  Class.DomainEntity#ExamPolicyProfile
  Class.Capability#CalculatorFunction
  Class.DomainEntity#FunctionSet
  Class.DomainEntity#ExamModeSession
  Event#PolicyViolation
  Event#AuditLogEntry
  Command#StartExamMode
  Command#ExitExamMode
  StateMachine#ExamModeSessionState
    State#not_started
    State#pending_device_verification
    State#active
    State#locked
    State#ended
```

Candidate `.hcs` responsibilities:

- descriptions;
- ontology package metadata;
- `central` markers;
- `implements` protocol declarations;
- relation domain/range/cardinality;
- policy metadata;
- state-machine transitions;
- source provenance.

Success criteria:

- the current `examcalc` package is expressible without semantic loss, or gaps are documented;
- no existing generated artifact changes;
- no new production dependency on Hypercode parser/runtime;
- the mapping identifies every required Hypercode grammar or HCS feature gap.

### Phase 2: AOT Import Adapter

Purpose: compile resolved Hypercode authoring files into the existing YAML package contract.

Candidate command:

```bash
ontologyc import-hypercode \
  --hc SPECS/ontology/examples/examcalc.ontology.hc \
  --hcs SPECS/ontology/examples/examcalc.ontology.hcs \
  --out /tmp/domain-ontology-package.yaml
```

Implementation direction:

- keep the adapter separate from `check` and `compile`;
- emit canonical `DomainOntologyPackage` YAML;
- run normal `ontologyc check` on the emitted YAML;
- include source provenance for generated package fields;
- keep resolution deterministic across platforms.

Success criteria:

- emitted YAML passes existing validation;
- emitted YAML can compile to the same normalized IR as the hand-authored package, or differences are explicitly approved;
- adapter failures are diagnostics, not crashes;
- no runtime interpretation is required for normal Ontology use.

### Phase 3: Context Overlays

Purpose: use `.hcs` for controlled ontology variants.

Candidate contexts:

- `@env[offline_exam]`;
- `@env[byod]`;
- `@env[managed_tablet]`;
- `@env[high_stakes_exam]`;
- `@jurisdiction[...]` if Hypercode adopts a general rule namespace.

Use cases:

- tighten or relax policy enforceability by deployment context;
- select profile-specific policy sets;
- generate variant packages for downstream compatibility checks;
- compare overlays through `ontologyc diff`.

Required guardrails:

- every overlay must compile to an explicit package artifact;
- hidden cascade overrides are not acceptable for normative specs;
- conflict reports must explain selector specificity and source order;
- signing/provenance should be planned before using overlays for trusted distribution.

Success criteria:

- at least two context variants compile into explicit YAML packages;
- `ontologyc diff` explains variant differences;
- provenance identifies which `.hcs` selector produced each changed field.

### Phase 4: SpecGraph Semantic Binding Authoring

Purpose: use Hypercode to make requirement-to-ontology binding easier to review.

Candidate `.hc` shape:

```text
Requirement#REQ-Exam-DeviceTrust
  Concept#TabletDevice
  Concept#ExamPolicyProfile
  Relation#requires_policy
  Policy#PolicyMustBeDeviceVerifiable
```

Candidate output:

- `SemanticBinding` YAML;
- `ConceptRefSet`;
- competency-question fixtures;
- semantic validation reports.

Success criteria:

- bindings generated from Hypercode resolve through existing SpecGraph validation;
- missing refs still produce `OntologyGap`;
- generated binding artifacts are deterministic.

### Phase 5: Agent Workflow Contracts

Purpose: reuse Hypercode as a compact structure language for agent workflows around ontology authoring.

Candidate `.hc` shape:

```text
OntologyImportWorkflow
  IntakeRawSource
  ExtractConcepts
  ReviewWithArchitect
  ValidateWithSpecificationCore
  EmitDomainOntologyPackage
  CompileTypeScriptSDK
```

Candidate `.hcs` responsibilities:

- role assignment;
- required validators;
- gate conditions;
- acceptance criteria;
- artifact paths.

Success criteria:

- workflow declarations can generate or validate Flow/SpecGraph planning artifacts;
- agent steps remain declarative and auditable;
- no workflow rule can execute arbitrary code.

### Phase 6: Ecosystem Promotion

Purpose: use Ontology as a credible consumer for the broader 0AL dependency stack.

Promotion targets:

- Hypercode demonstrates a concrete non-toy use case.
- Ontology gains a readable authoring projection.
- SpecificationCore remains the validation engine for resolved artifacts.
- SpecGraph receives cleaner semantic-binding inputs.

Success criteria:

- documentation shows the full stack relationship:

```text
Hypercode authoring -> Ontology package -> SpecificationCore validation -> SpecGraph semantic validation
```

- examples are small enough to review but rich enough to show real policies, relations, and state machines.

## Candidate Backlog Items

These are candidate tasks only. They are not added to `SPECS/Workplan.md` until the team decides to promote the roadmap into PRDs.

| Candidate ID | Title | Priority | Depends On | Outcome |
| --- | --- | --- | --- | --- |
| ONT-HC-001 | Hypercode Ontology Authoring Spike | P2 | ONT-010 | Example `.hc/.hcs` pair plus mapping report |
| ONT-HC-002 | Hypercode-to-YAML AOT Import Adapter | P2 | ONT-HC-001 | Optional `ontologyc import-hypercode` command |
| ONT-HC-003 | Context Overlay Resolution and Provenance | P2 | ONT-HC-002 | Variant packages with auditable selector provenance |
| ONT-HC-004 | Hypercode Semantic Binding Authoring | P3 | ONT-HC-001 | Generated SpecGraph binding fixtures |
| ONT-HC-005 | Agent Workflow Contract Experiment | P3 | ONT-HC-001 | Declarative workflow examples for ontology import |

## Open Questions

- Should `.hcs` remain YAML-compatible, or does Ontology need stricter schema validation for cascade sheets?
- Should Hypercode gain a general rule namespace beyond `@env[...]`, such as `@profile[...]` or `@jurisdiction[...]`?
- How should selector provenance be represented in generated YAML and normalized IR?
- Should the first parser be a small Swift parser for the minimal grammar, or should Ontology wait for Hypercode to publish a reusable package?
- Which fields are allowed to be context-overridden, and which normative fields must remain invariant?

## Non-Goals For The First Spike

- Replacing `DomainOntologyPackage` YAML.
- Changing `ontologyc check` or `ontologyc compile` behavior.
- Adding runtime Hypercode interpretation to generated TypeScript artifacts.
- Adding registry distribution for Hypercode files.
- Extending Hypercode grammar before documenting concrete Ontology gaps.
- Introducing Ruby or non-Swift quality tooling.

## Risk Register

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Hypercode grammar is too small for ontology authoring | The spike cannot express enough semantics | Keep rich fields in `.hcs`; document grammar gaps explicitly |
| Cascade overrides hide normative changes | Specs become harder to audit | Require AOT compiled artifacts and selector provenance |
| Parser/runtime dependency is immature | Production compiler becomes unstable | Keep Hypercode optional until a stable Swift package or adapter exists |
| `.hcs` becomes too powerful | Security and reviewability degrade | Treat `.hcs` as inert data; forbid code execution |
| Duplicate source formats confuse users | Maintenance cost increases | Present Hypercode as authoring projection, not canonical source |

## Decision Gates

Hypercode can move from roadmap to PRD only when:

1. The team accepts the optional-authoring-layer model.
2. The `examcalc` spike has a clear lossless mapping strategy.
3. The provenance model is defined before context overlays are used.
4. The implementation path is Swift-native or build-tool neutral.
5. Existing Ontology regression gates remain unchanged.
