# Competency questions — Generic Agency Core

| Question | Representation | Checked boundary |
|---|---|---|
| What content is considered? | PropositionContent | No physical assertion or expression evaluation |
| Who acts in which episode? | AgencyContext -> existing view -> optional actor role | Envelope checks index identity and reachability; caller validates underlying graph |
| May the actor stay unknown? | No selected actor role | No speaker/author/default entity substitution |
| Can a motive be unrecognized by its actor? | AwarenessHypothesis -> exact MotivationHypothesis | Same view, optional actor role and contribution kind; awareness itself is not proven |
| Is unawareness the same as uncertainty? | Explicit unaware claim vs no awareness claim | No missing-value conversion |
| Can psychology be inapplicable? | Explicit not_applicable | Never inferred from machine/natural/human kind |
| What does the actor seek, avoid or maintain? | GoalHypothesis -> PropositionContent | Content reference and direction enum; no truth/performance inference |
| Is an intention the goal? | Independent IntentionHypothesis, optional intentionGoal | Target must be a goal claim in this context |
| Can an outcome be anticipated but unwanted? | AnticipationHypothesis and OutcomeAttitudeHypothesis | No automatic entailment between claim types |
| Can support conflict? | Independent positive/negative support per claim | Both retained; review does not erase or establish truth |
| Is the time of a report the time of the stance? | Separate optional perspective/report time | Known clock/instant shape; no defaulting or chronology proof |
| Does any of this establish actual consequences? | Existing event record/states/Delta remain separate | Source-only envelope rejects physical and authority fields |
| Can a downstream normative model use these? | Explicit separately versioned mapping with extra grounds | No automatic normative classification in core |
