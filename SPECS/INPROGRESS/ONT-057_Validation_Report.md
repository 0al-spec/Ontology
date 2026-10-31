# ONT-057 validation

## Reproduce the downstream defect

Use the SG-SPEC-0072 package from [SpecGraph #843 at `2db71a68`](https://github.com/0al-spec/SpecGraph/blob/2db71a682325b57c4c9a9d096d9d90f4c20722ff/specs/models/SG-SPEC-0072/foundation-member.yaml).
For the negative control change only `Entry.extends` from `sg:ValueObject` to `sg:Typo`. Run `ontologyc check` and `ontologyc compile --target typescript --out <fresh-directory>` on each file with each release-configuration executable.

| Input | 0.3.0 check / compile | Candidate check / compile |
| --- | --- | --- |
| `sg:ValueObject` | 0 / 0 | 0 / 0, SDK written |
| `sg:Typo` | 0 / 0, SDK written | 1 / 1, destination absent |

The candidate ran as a standalone binary outside the checkout. For the typo,
`check --format json` returned one error with code `class.extends.unresolved`,
path `spec.classes.Entry.extends`, and the literal `sg:Typo` in its message.
The valid control returned an empty diagnostic array. The 0.3.0 reference binary
was built from `d831e25b46095dfea5e17befbc88c5fdcd03e031`.

## Local macOS checks

- `RUN_COVERAGE=1 bash tools/swift-quality.sh` passed the format, lint, dependency-import, build and test gates. 46 rules tests and 125 compiler/CLI tests passed. Line coverage reported by the gate was 90.40%.
- `ruby SPECS/ontology/fixtures/validate-fixtures.rb` passed all 11 fixtures. An additional run on the minimal state-machine package with the foundation alias changed to `base` accepted its command triggers.
- `swift build -c release --product ontologyc` and `bash tools/portable-contract-smoke.sh` passed using the release executable.
- Compiled each of the eight tracked package sources (including events-core 0.2.0). All 80 generated files matched both the 0.3.0 output and the checked-in baselines byte for byte.
- The `export-foundation` output matched the checked-in catalog, SHA-256 `ef07cf4e8dd4cdc8c8dd583971fc3cabfe82e4b00fb0e680b6d1db48cfe262ad`. CLI regression tests also check a custom alias, the default alias, unknown version, name conflict, symbol roles and original `oneOf` member indices.

## Finding in existing data

The voice-recorder induction example modeled `AudioSegment` with `extends: sg:Evidence`.
Foundation 0.1.0 exports no such class. The segment has its own identity and now
extends `sg:DomainEntity`. Its evidence category, description and links remain in
the draft. Its four intentionally invalid variations received the same base correction
so their failures still exercise their named checks.

The compiler owns membership for the built-in foundation version. Other imports
still use their declared namespace when an export table is unavailable. SpecGraph
can consume the JSON diagnostic after adopting a compiler release with this change.
