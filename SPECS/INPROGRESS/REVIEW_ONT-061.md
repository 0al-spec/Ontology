# Review of ONT-061

Reviewed the release workflow from source selection through preview and publication. The publishing job receives the expected executables from a separate read-only job that evaluates the selected revision's SwiftPM manifest. The two builds run the unpacked compiler and visualizer. The Linux runtime consumes the archive in Ubuntu 22.04 with Graphviz installed.

Two findings were addressed before delivery. Identifying a product by its entrypoint filename would silently omit a renamed entrypoint. SwiftPM now supplies the product names. The archive verifier also rejects a managed executable absent from the expected inventory, including a visualizer inserted into an older compiler-only archive. Regression cases cover both directions of mismatch.

Local compiler-only and two-tool archives passed their smoke tests. The user-facing archive names and expected checksum entries match the existing download instructions. The release preview provides the separate hosted evidence for each platform.
