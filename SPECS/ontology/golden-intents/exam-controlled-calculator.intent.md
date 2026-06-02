# Golden Intent: Exam-Controlled Calculator

## Intent

Build a calculator application for university tablets used during exams. Different exams
may allow different calculator functions. The system must enforce the active exam policy,
deny unapproved functions by default, verify that the policy is signed and available on the
device, prevent network access during exam mode, and produce audit records for violations
and enforcement events.

## Expected Induction Pressure

- Surface product: calculator application.
- Deep domain: exam-controlled computation.
- Governing concept: `ExamPolicyProfile`.
- Policy-heavy: yes.
- Lifecycle-heavy: yes, for exam mode runtime.
- Trust/evidence-heavy: yes.

## Useful Competency Questions

- Which calculator functions are allowed for a given exam?
- Which functions are explicitly denied for a given exam?
- Can exam mode become active if the policy is unsigned or not device-verifiable?
- What evidence records that a policy violation occurred during an exam session?
