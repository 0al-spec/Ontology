# REVIEW — ONT-068 viewer launch manual
Scope: author self-review above #92. Verdict: ready for independent review.

The guide is self-contained: selected tool requirements, pinned source revision,
explicit CLI build paths, full example, read-only/workspace distinction,
preserved disposable copies, troubleshooting and restart. Existing instructions
now link to the guide, while optional browser tests get their own relations
fixture and explicit tools. The manual avoids relying on global installed CLIs.
The new guide lives in tracked LAUNCH.md because docs/ is ignored for generated
documentation. Forty local links and five shell blocks were checked.

Validation is bounded accurately: macOS source archive with fresh build products,
fresh node_modules and shared download caches. HTTP/API and copied-file saving
were checked; the git-clone block, Linux and new visual behavior were not run.
No runtime code changed, so prior product test results are not reattributed here.

Follow-up: the existing pinned npm development dependency tree reported six
advisories (including two critical labels). Compatibility and reachability need
investigation; no automatic force upgrade is appropriate in this documentation
change. Record ONT-069 during FOLLOW-UP. This finding does not invalidate the
tested launch instructions or establish a security acceptance decision.
