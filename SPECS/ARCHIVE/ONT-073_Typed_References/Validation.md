# ONT-073 validation

- Swift quality gate passed, including 181 tests, SwiftFormat and SwiftLint.
- All 14 YAML fixtures passed. Draft 2020-12 JSON Schema accepted the new field and rejected missing and misplaced targets.
- Portable contract checks passed, including byte comparisons with existing generated packages.
- TypeScript smoke passed with fresh SDKs. Removing the suppression on the negative assignment produced TS2322 for `Ref<Project>` in the generated `Ref<Repository>` field.
- The same consumer ran on two isolated downstream candidate package sources. Both locator encodings selected the same repository. An unknown key, missing graph node and unknown revision left existing membership intact.
- The pilot uses in-memory lookups. External storage, imported target declarations and publication of a release are outside this evidence.
