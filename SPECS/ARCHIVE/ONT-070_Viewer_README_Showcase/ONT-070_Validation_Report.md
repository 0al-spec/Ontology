# ONT-070 validation

Date: 2026-10-31. PASS for the bounded documentation change; hosted review/CI
are separate.

- Captured the real running desktop Viewer at 1600 × 1000 CSS pixels and inspected
  both the initial overview and final focused PNG. The initial overview was too
  small to read; the final screenshot uses the ordinary search/result selection
  to focus the imported motivcore:Motive in the NormLab full graph.
- The UI reported 104 nodes and 287 visual links. The screenshot intentionally
  shows a zoomed fragment, source inspector and root YAML workspace, not the
  complete graph at readable scale. Source provenance uses package identity,
  logical YAML pointer and digest; no local absolute paths or tokens are visible.
- Used the existing built viewer preview; no source save, runtime change,
  dependency install, rebuild or new runtime regression run was performed.
- Browser capture scope: 15 UI calls including one denied screenshot destination
  and its successful retry; two screenshots inspected. The browser tool restricts
  output paths, so capture used its allowed ignored output folder; evidence was
  then copied to TB5 and the selected PNG into this repository.
- Console observation: favicon.ico returned 404. This documentation task did not
  fix or investigate that unrelated missing icon.
- Checked 41 local README link/image targets, PNG signature and dimensions
  (145201 bytes), image placement before the problem section and whitespace.
- The README uses a repository-relative image and launch link. No claim of
  hosted README rendering, mobile validation, visual graph editing or SpecSpace
  integration is made.

Only browser presentation state changed (search and selected node). Existing
NormLab preview services were left running; no model edits were performed.
