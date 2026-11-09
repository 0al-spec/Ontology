# Foundation TypeScript Model

## Purpose

The foundation model defines the stable semantic target for product ontologies. YAML ontology packages declare semantic inheritance and protocol implementation; generated TypeScript projects those declarations into typed references, interfaces, relations, policies, state machines, and validators.

New packages import `ontology.foundation@0.2.0` with the default namespace `ont`. For the compiler-owned names and their export roles, see the [versioned foundation catalog](foundation/0.2.0/exports.json) or run `ontologyc export-foundation`.

In a named relationship the subject is the Actor for its declared action and
object. Ivan and Anna can both be People. To appoint Anna, Ivan must be able
to perform `Appoint` on her. An event interpretation can subsequently record
who acted.

## Concept Kind Set

```ts
export type ConceptKind =
  | "Action"
  | "DomainEntity"
  | "ValueObject"
  | "Capability"
  | "Command"
  | "Event"
  | "Policy"
  | "Invariant"
  | "StateMachine";
```

## Base Node

```ts
export interface OntologyNode {
  readonly id: string;
  readonly fqid: string;
  readonly uri: string;
  readonly kind: ConceptKind;
  readonly description?: string;
  readonly aliases?: readonly string[];
}
```

## Foundation Interfaces

```ts
export interface Action extends OntologyNode {
  readonly kind: "Action";
}

export interface DomainEntity extends OntologyNode {
  readonly kind: "DomainEntity";
  readonly lifecycle?: StateMachineRef;
}

export interface ValueObject extends OntologyNode {
  readonly kind: "ValueObject";
}

export interface Capability extends OntologyNode {
  readonly kind: "Capability";
}

export interface Command extends OntologyNode {
  readonly kind: "Command";
}

export interface Event extends OntologyNode {
  readonly kind: "Event";
}

export interface Policy extends OntologyNode {
  readonly kind: "Policy";
  readonly enforceability: "design" | "runtime" | "manual" | "audit";
  readonly appliesTo: readonly ConceptRef[];
}

export interface Invariant extends OntologyNode {
  readonly kind: "Invariant";
  readonly appliesTo: readonly ConceptRef[];
}

export interface StateMachine extends OntologyNode {
  readonly kind: "StateMachine";
  readonly states: readonly string[];
  readonly transitions: readonly StateTransition[];
}
```

## ConceptRef

```ts
export interface ConceptRef<
  TOntology extends string = string,
  TVersion extends string = string,
  TConcept extends string = string,
  TKind extends ConceptKind = ConceptKind
> {
  readonly ontology: TOntology;
  readonly version: TVersion;
  readonly namespace: string;
  readonly concept: TConcept;
  readonly kind: TKind;
  readonly alias: `${string}:${string}`;
  readonly uri: `ontology://${TOntology}/${TVersion}/${string}`;
}
```

## Relations

An author declares the subject entity, reusable action class and object entity
in the package. Two relationships can use the same action.

```yaml
CastAppointment: {subject: Person, action: Appoint, object: Person}
CrewAppointment: {subject: Person, action: Appoint, object: Person}
```

The generated TypeScript type `ActionRelationship<"pilot:CastAppointment">`
requires `Person & Actor<Appoint, Person & Entity>` as its subject and
`Person & Entity` as its object. `Entity` supplies the instance ID.
`trigger(relationship)` calls `relationship.subject.run(relationship.action,
relationship.object)` and returns the implementation's result. The application
implements the action on that identified subject. `ActionRelationshipRecord`
describes the serializable data. See the [casting example](../../Examples/theatre-casting/README.md).

The compiler stores endpoint types in the following normalized metadata shape.

```ts
export interface RelationDefinition<
  TId extends string = string,
  TDomain extends ConceptRef = ConceptRef,
  TRange extends ConceptRef | OneOfRange = ConceptRef,
  TAction extends ConceptRef = ConceptRef
> {
  readonly id: TId;
  readonly domain: TDomain;
  readonly range: TRange;
  readonly action?: TAction;
  readonly cardinality?: {
    readonly min?: number;
    readonly max?: number;
  };
}

export interface OneOfRange {
  readonly oneOf: readonly ConceptRef[];
}
```

The compiler resolves the action class to `ont:Action` through its inheritance
chain. Plain binary relations such as containment use `domain` and `range`.

## State Transitions

```ts
export interface StateMachineRef {
  readonly alias: `${string}:${string}`;
}

export interface StateTransition {
  readonly from: string;
  readonly to: string;
  readonly command?: ConceptRef;
  readonly event?: ConceptRef;
}
```

## Protocols

Protocols are semantic obligations mixed into generated instance interfaces.

```ts
export interface Versioned {
  readonly version: string;
}

export interface Approvable {
  readonly approvalStatus: "draft" | "submitted" | "approved" | "rejected";
  readonly approvedBy?: string;
}

export interface Signable {
  readonly signature?: {
    readonly algorithm: string;
    readonly publicKeyRef: string;
    readonly value?: string;
  };
}

export interface Auditable {
  readonly auditRefs?: readonly string[];
}

export interface TimeBound {
  readonly validFrom?: string;
  readonly validUntil?: string;
}

export interface DeviceBound {
  readonly deviceRef?: string;
}

export interface RestrictableCapability {
  readonly restrictionMode?: "allow" | "deny" | "conditional";
}
```

## Inheritance Rule

YAML `extends` controls semantic inheritance. YAML `implements` controls protocol obligations. TypeScript `extends` is generated as a projection of those semantic declarations and MUST NOT become the source of truth.

Example:

```yaml
ExamPolicyProfile:
  extends: ont:DomainEntity
  implements:
    - ont:Versioned
    - ont:Approvable
    - ont:Signable
```

Generated projection:

```ts
export interface ExamPolicyProfile
  extends DomainEntityInstance,
    Versioned,
    Approvable,
    Signable {}
```
