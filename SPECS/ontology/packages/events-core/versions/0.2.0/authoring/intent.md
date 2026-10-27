# Event Core 0.2.0 — Snapshot provenance

ONT-047 revises the vocabulary while freezing 0.1.0/eventcore-v1. Keep recorded
states, source-only candidates and role interpretations separate. Add three
explicit origins: cited extraction, direct capture, and deliberate operator
supply. A separately supplied graph-bound authority input admits declared origin
and enrichment; a graph cannot authorize itself. Presence of evidence and an
admitted provenance claim do not establish physical truth or responsibility.

Unknown/partial states may stay source-only. Only explicit complete states with
confirmed origins admit exact Delta, including genuinely supplied empty sets.
The caller must choose the new profile and trusted authority input explicitly.
