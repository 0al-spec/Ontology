# Review: ONT-076 exam calculator

**Scope:** changed package, human source, two-clause reading, consumer, SDK/fixture checks and the Viewer artifact. **Verdict:** ready for independent PR review.

- The desired-result example is separate from both the classroom state and the interpreter. The original human message and the clarification have separate provenance; example allowances are not represented as additional human instructions.
- A well-typed cross-exam substitution is rejected before altering the applied set. An empty set has known membership; no assignment yields unknown. The type-correct latest-set mutation is observed failing at arithmetic/sine.
- The sample workflow compiles the YAML placed in its archive and runs the manifest emitter from the same build. Local replay verified every manifest path. Legacy bindings, input and generated directory have no diff.
- Local checks: 181 Swift tests, 15 Ruby fixtures, the SDK type-check and execution, SVG generation and archive replay. There is no claim about broad Russian parsing, tablet hardware or human acceptance.

No actionable repository findings; skip FOLLOW-UP. An older locally pinned Git advisory flags the new action syntax; on identical staged bytes the freshly built advisory is silent and the strict compiler passes. The machine-local pin is a separate operator handoff.
