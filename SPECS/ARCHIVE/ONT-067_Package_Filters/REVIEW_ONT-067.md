# REVIEW — ONT-067 package filters
Scope: author self-review above feature/ONT-066-full-imports (#91).
Verdict: ready for independent review; hosted CI pending.

Reviewed ownership separately from presentation origin: generated states use
machine source, external references use declared identity, and unattributed data
has an explicit bucket. Distinct versions remain independently selectable.
Links need their own package and both endpoint packages. Counts use the full
graph; hide/dim, search and inspector share the same visibility.

Package enumeration uses loaded source metadata plus declared imports, so a
zero-count dependency is still visible without claiming its declarations loaded.
Refresh retains choices; explicit file open and reset clear package choices.
The full graph remains unchanged, preserving canvas positions and viewport.

Validation: production build, 17 unit tests and all 18 browser scenarios passed.
The browser verified real NormLab package toggling. No Swift source changed;
this slice did not repeat its parent Swift suite. No performance/coverage
percentage, source approval or semantic-truth claim is made.

No remaining in-scope actionable issue identified. FOLLOW-UP skipped.
Worktree remains active for the dependent PR; pilot snapshots and services are
outside its sources. Persistent filter/layout profiles remain future work.
