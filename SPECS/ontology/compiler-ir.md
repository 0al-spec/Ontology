# Compiler Intermediate Representation

## Purpose

`ontologyc` MUST compile raw YAML through a normalized intermediate representation before emitting TypeScript SDK files, validators, documentation, or lock metadata. The normalized IR is the deterministic semantic source for generated artifacts.

## NormalizedOntologyIR

```ts
export interface NormalizedOntologyIR {
  readonly id: string;
  readonly namespace: string;
  readonly version: string;
  readonly sourceDigest: string;
  readonly imports: readonly ResolvedOntologyImport[];
  readonly classes: readonly NormalizedClass[];
  readonly relations: readonly NormalizedRelation[];
  readonly protocols: readonly NormalizedProtocol[];
  readonly policies: readonly NormalizedPolicy[];
  readonly stateMachines: readonly NormalizedStateMachine[];
  readonly compatibility?: NormalizedCompatibility;
  readonly diagnostics: readonly Diagnostic[];
}
```

## Import IR

```ts
export interface ResolvedOntologyImport {
  readonly id: string;
  readonly namespace: string;
  readonly version: string;
  readonly digest?: string;
  readonly registryUri?: string;
}
```

## Class IR

```ts
export interface NormalizedClass {
  readonly id: string;
  readonly fqid: string;
  readonly uri: string;
  readonly kind: ConceptKind;
  readonly extends: string;
  readonly implements: readonly string[];
  readonly description: string;
  readonly central: boolean;
  readonly lifecycle?: string;
  readonly aliases: readonly string[];
}
```

Rules:

1. `fqid` MUST be `${namespace}:${id}`.
2. `uri` MUST include ontology id, version, and class id.
3. `extends` MUST resolve to a foundation or imported class.
4. `implements` MUST resolve to protocols.

## Relation IR

```ts
export interface NormalizedRelation {
  readonly id: string;
  readonly fqid: string;
  readonly uri: string;
  readonly domain: string;
  readonly range: string | { readonly oneOf: readonly string[] };
  readonly cardinality?: {
    readonly min?: number;
    readonly max?: number | "*";
  };
  readonly description?: string;
}
```

Rules:

1. `domain` MUST resolve to one class.
2. `range` MUST resolve to one or more classes.
3. Relation ids MUST be unique within an ontology namespace.

## Policy IR

```ts
export interface NormalizedPolicy {
  readonly id: string;
  readonly fqid: string;
  readonly extends: string;
  readonly enforceability: "design" | "runtime" | "manual" | "audit";
  readonly appliesTo: readonly string[];
  readonly text: string;
}
```

## State Machine IR

```ts
export interface NormalizedStateMachine {
  readonly id: string;
  readonly fqid: string;
  readonly states: readonly string[];
  readonly transitions: readonly NormalizedTransition[];
}

export interface NormalizedTransition {
  readonly from: string;
  readonly to: string;
  readonly command?: string;
  readonly event?: string;
}
```

Rules:

1. Every transition `from` and `to` state MUST exist in `states`.
2. A transition trigger MAY be a command or event.
3. A trigger reference, when present, MUST resolve before TypeScript emission.

## Diagnostic Model

```ts
export interface Diagnostic {
  readonly code: string;
  readonly severity: "error" | "warning" | "info";
  readonly path: string;
  readonly message: string;
  readonly hint?: string;
}
```

Required diagnostics:

| Code | Severity | Condition |
|---|---|---|
| `metadata.required` | error | Missing `metadata.id`, `metadata.namespace`, or `metadata.version`. |
| `class.extends.unresolved` | error | Class base type cannot be resolved. |
| `class.extends.multiple` | error | Class declares more than one semantic base. |
| `protocol.unresolved` | error | Protocol reference cannot be resolved. |
| `relation.domain.unresolved` | error | Relation domain class cannot be resolved. |
| `relation.range.unresolved` | error | Relation range class cannot be resolved. |
| `state.transition.invalid_state` | error | Transition references a missing state. |
| `policy.appliesTo.unresolved` | error | Policy target cannot be resolved. |
| `security.executable_content` | error | YAML attempts to define executable hooks or expressions. |

## Determinism Requirements

1. IR arrays MUST be emitted in stable lexical order unless source order is explicitly preserved by a field.
2. Diagnostics MUST be stable for the same input and compiler version.
3. Generated SDK artifacts MUST derive from IR only, not directly from raw YAML.
