# ONT-055 validation

Local macOS arm64 packaging passed. The extracted CLI checked examcalc and
compiled normalized IR identical to its committed baseline. The archive
contained the executable, build identity, project license and dependency notices.
The read-only resolver peeled the annotated 0.3.0 tag to
`d831e25b46095dfea5e17befbc88c5fdcd03e031` and returned release ID 429541432.

All six publication controls passed, including missing/wrong-platform set,
wrong revision, release recreation, moved tag, digest conflict and identical
asset reuse. The upload test used a simulated release. Swift quality passed
166 tests (45 + 121) with 90.22% line coverage. Workflow YAML, Bash syntax and
the repository's Node 24 action check passed. Hosted platform previews and
publication to a real release have separate evidence.
