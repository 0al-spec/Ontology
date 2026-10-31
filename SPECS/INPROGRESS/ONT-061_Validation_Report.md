# ONT-061 validation

On macOS arm64, the packaging script built from two clean source checkouts. At `82955e22` the archive contained executable `ontologyc` and `ontologyviz`. At the 0.4.0 release commit `46a4af4a` it contained the compiler alone. Both extracted compilers checked the examcalc package and reproduced its normalized IR.

From a separate working directory, the extracted visualizer rendered the saved motivation profile using Graphviz 16.1.0. Its DOT matched the committed fixture byte for byte. The SVG parsed with 13 nodes and 23 edges. macOS Image I/O decoded the 2392 × 997 PNG.

The two published 0.4.0 archives matched their released checksum list. Verification against the historical compiler-only inventory succeeded. All 15 inventory and publication tests passed. They include missing and unexpected executables, invalid permissions, identity mismatch, and retry behavior. The repository's Swift quality gate passed 211 tests (55 rules and 156 compiler/CLI tests), with zero SwiftLint violations.

The GitHub release preview builds the two supported platforms and repeats the extracted CLI checks in Ubuntu 22.04 without a Swift toolchain. The preview retains the platform archives and their checksum list as Actions artifacts.
