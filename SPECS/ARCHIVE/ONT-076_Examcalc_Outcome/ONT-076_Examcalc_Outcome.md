# ONT-076: Rebuild examcalc from the desired outcome

The human asks for a university tablet calculator whose available functions depend on the exam. The agreed clarification is: «Преподаватель задаёт для экзамена набор разрешённых функций, а калькулятор применяет этот набор». The original utterance is user message `9cfde494-fc96-4962-9b0a-a31ba63e48ca` in the archived ontology discussion. The user supplies the result; the following operational reading is one proposed way to achieve it.

The agent reads the person's free-form intent, preserves the quote and proposes a draft ontology. It can correct spelling and punctuation in its own restatement. A change to the actor, the chosen set or the requested outcome needs separate clarification. Show how the typed actions could produce that outcome and exercise the saved model through its generated SDK. Retain the published 0.1 fixture at its existing path.

Acceptance:

1. Compile the new package and its TypeScript SDK using the current foundation. The instructor selects a set for an exam; the calculator applies the same set for that exam. A function set lists its member functions.
2. Exercise one calculator on two exams with different allowances; the same operation must yield different availability. Reject substitution of a different set (including one with equal contents). Distinguish absent input from an explicitly empty set; do not choose a product default for missing data.
3. Show which checks concern structure, which concern the example's behavior and which conditions remain unspecified. Exercise both a bad type and a structurally plausible but behaviorally wrong choice. Keep the legacy golden and its smoke tests intact.
