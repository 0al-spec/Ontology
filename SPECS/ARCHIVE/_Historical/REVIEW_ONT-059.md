# ONT-059 implementation review

Reviewed the delta from ONT-057. The Git adapter reads object IDs from the active index, validates the staged text in memory and uses the original path in compiler diagnostics. Its Git commands read raw objects and suppress lazy fetching. The adapter neither follows staged symlinks nor writes to the index. Each blob has a 4 MiB limit. A clone with unrelated or intentionally invalid packages elsewhere does not trigger a full repository scan.

The strict package checker and the advisory share loading and diagnostic sorting. The hook itself prints findings to stderr and returns success even when its Git inspection fails. The documented registration also covers a missing compiler. A separate project hook retains its own return status, as demonstrated with a real failing commit.

The setup is per clone. The operator's Git 2.54 supports independent configured hooks. Users of a filtering command wrapper need unfiltered commit output. [Validation](../ONT-059_Staged_Package_Advice/ONT-059_Validation_Report.md) documents that difference. Self-review outcome: ready for external review. FOLLOW-UP skipped.
