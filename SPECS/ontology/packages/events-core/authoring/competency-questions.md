# Event core competency questions

These are review questions derived from the merged proposal, not executed
semantic checks. Compiler validation establishes vocabulary/reference structure.

| Question | Vocabulary / expected interpretation | Executable guarantee |
|---|---|---|
| Can a hurricane or abstract community be actor? | Entity is the target of a RoleBinding whose roleName is actor. | Instance validation deferred to ONT-043. |
| Can the moving car be actor in one reading and instrument in another? | Two Interpretations refer to one RecordedEvent and use distinct RoleBindings. | Observation preservation remains a manual policy here; existing NormLab proofs are separate. |
| Can a relation persist after its origin event? | RelationInstance retains its role bindings and optional origin record. | Persistence/rule reasoning is not executed by this package. |
| What does a source without physical states become? | EventCandidate plus InterpretationCandidate and SourceAssertion; StateObservation availability unknown, no invented snapshots or Delta. | Conditional presence/exactness checks are ONT-043 work. |
| Can complete known empty states have empty Delta? | Yes within the same schema/scope/projection. | Exact set comparison is not implemented here. |
| Does I in a letter identify the narrator? | No; SourceAssertion retains the statement's speakerKey or keeps it absent. | Identity/quote relevance checking is not implemented here. |
| Does reviewed candidate mean a checked event? | No; candidate review lifecycle never promotes it into RecordedEvent. | The declared lifecycle contains no promotion transition; object-graph integrity is deferred. |
| Does a causal hypothesis establish physical causation? | No; profileRef and manual review retain its hypothetical status. | Temporal profile checks are deferred; responsibility is outside events-core. |
| Where is recordKey unique? | Within the EventRegistry revision reached by recordInRegistry; not across unrelated revisions. | InstanceGraph membership/uniqueness checks are ONT-043 work. |
| Can Delta choose different states from its record? | It has only deltaOfRecord; both states derive from that record. | Exact Added/Removed validation is ONT-043 work. |
| Whose roles apply at each causal endpoint? | hypothesisCauseView/effectView preserve each Interpretation; records derive through interpretsRecord. | Endpoint registry/profile consistency is ONT-043 work. |
