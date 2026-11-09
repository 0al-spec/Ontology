# ONT-089 validation report

- Before the fix, targeted tests reproduced three failures: a same-named
  relation masked a missing instance field, an explicitly declared field was
  rejected without such a relation, and imported protocol relations were not
  checked. The regressions now pass.
- `RUN_COVERAGE=1 tools/swift-quality.sh` passed SwiftFormat, SwiftLint and the
  complete Swift suite; aggregate line coverage was 90.51%.
- The TypeScript/Zod and portable package smoke suites passed with the task
  compiler. Existing SDK examples now declare their required instance fields;
  the built-in SDK `id` remains a protocol-requirable special case.
- A staged-index smoke confirms that a missing field in an imported parent is
  reported with source attribution even if the working copy has been repaired.
- Five SpecGraph advisory integration tests passed with the candidate compiler.
- The existing locally installed Ontology hook used an older compiler and
  reported the pre-fix `protocol.field.missing` false positives when these
  examples were committed. The new compiler's staged-index smoke passed;
  update the installed hook after publishing the release.
- Class identities and aliases are resolved in their declaring package; missing
  ancestor and protocol sources remain explicit warnings. No network import
  resolution, runtime execution or factual truth is implied.

Local builds and caches were routed to TB5. Hosted CI, review, release and
downstream installation are separate from these local results.
