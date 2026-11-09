# ONT-083 validation

Verdict: PASS locally on 2026-11-09; hosted CI and review are separate.

- `python3 tools/generate_foundation_models.py --check` verified both catalogs
  against their pinned source bytes and generated output.
- Four Python unit tests cover pinned-source drift, stale output, missing or
  ambiguous interfaces, and extraction of optional/nested properties.
- `bash tools/swift-quality.sh`, with the checkout-specific scratch on TB5,
  passed SwiftFormat, SwiftLint, build and the full Swift suite, including
  199 compiler tests.
- Focused `FoundationModelCatalogTests` additionally check catalog names
  against both built-in export sets, retained source digests and exact
  declarations, plus representative inheritance and fields.
- The catalogs do not yet change visualizer output or publish a website view.
