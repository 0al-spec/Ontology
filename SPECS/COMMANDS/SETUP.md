# SETUP — Project Configuration

**Version:** 1.5.0

## Purpose

SETUP creates `.flow/params.yaml` — the single configuration file that tells Flow about your project. This file lives outside `SPECS/` so it survives Flow updates.

## How It Works

Flow reads project-specific values from `.flow/params.yaml` at the repo root. Commands reference it as `[Params](.flow/params.yaml)` and read only the sections they need.

**Update story:** drop a new `SPECS/` folder into your repo — `.flow/params.yaml` is untouched.

## Create `.flow/params.yaml`

```bash
mkdir -p .flow
```

Paste and fill in this template:

```yaml
# .flow/params.yaml
# Your project config for Flow.
# Safe to edit freely — update Flow by replacing SPECS/, not this file.

project:
  name: MyProject
  description: Short description of what this project does
  language: TypeScript          # e.g. Swift, Python, Rust, Go
  package_manager: npm          # e.g. yarn, pip, cargo, swift
  default_branch: main

verify:
  tests: npm test
  lint: npm run lint
  format: npm run format
  typecheck: npm run typecheck  # optional, remove if not applicable
  coverage: npm run test:coverage
  coverage_threshold: 80        # percent

task_system:
  kind: file                    # required: file | github | jira | linear | none
  project_key: PROJ             # optional lightweight scope key
  task_url_template: "SPECS/Workplan.md#{task_id}-{task_name_slug}"  # optional markdown anchor template

# Optional: performance budgets checked during REVIEW
nfrs:
  api_response_ms: 200
  memory_mb: 512

# Optional: key paths used in EXECUTE and ARCHIVE
structure:
  source: src/
  tests: tests/

# Optional: GitHub template links (detected by SETUP, used by REVIEW)
# github:
#   pr_template: .github/pull_request_template.md
#   issue_templates_dir: .github/ISSUE_TEMPLATE/
```

## Required vs Optional Fields

| Field | Required | Used By |
|-------|----------|---------|
| `project.name` | yes | all commands |
| `project.default_branch` | yes | BRANCH, SELECT |
| `verify.tests` | yes | EXECUTE |
| `verify.lint` | yes | EXECUTE |
| `verify.format` | no | EXECUTE |
| `verify.typecheck` | no | EXECUTE |
| `verify.coverage` | no | EXECUTE |
| `verify.coverage_threshold` | no | EXECUTE, REVIEW |
| `task_system.kind` | yes | SELECT, PLAN, ARCHIVE |
| `task_system.project_key` | no | SELECT, PLAN |
| `task_system.task_url_template` | no | SELECT, ARCHIVE |
| `nfrs.*` | no | REVIEW |
| `structure.*` | no | EXECUTE, ARCHIVE |
| `github.pr_template` | no | REVIEW |
| `github.issue_templates_dir` | no | REVIEW |

## Quick SETUP (For AI Agents)

If you're an AI agent setting up Flow for a user, work through these phases in order. Stop as soon as you have enough to fill `verify.*` confidently.

### Phase 1 — Detect task runner

Check for a task runner first. If one exists, its targets are the ground truth — use them directly rather than reconstructing individual tool commands.

| File | Likely commands |
|------|----------------|
| `Makefile` with `test`/`lint`/`check` targets | `make test`, `make lint`, `make check` |
| `Makefile` with a master `check` or `all` target | single `make check` covers everything |
| `justfile` | `just test`, `just lint` |
| `Taskfile.yml` | `task test`, `task lint` |
| `scripts/local-ci/run-all.sh` | `./scripts/local-ci/run-all.sh` |

> **Rule:** if `make check` exists and runs tests + lint together, set `verify.tests: make check` and omit `verify.lint`. Don't duplicate.

### Phase 2 — Detect language and package manager

| File | Language | Package manager |
|------|----------|----------------|
| `Package.swift` | Swift | swift |
| `package.json` | JavaScript/TypeScript | npm / yarn / pnpm |
| `pyproject.toml`, `requirements.txt` | Python | pip / uv |
| `Cargo.toml` | Rust | cargo |
| `go.mod` | Go | go |

### Phase 3 — Detect quality gate configuration

Read these files to infer the actual commands and thresholds:

**Swift:**
- `.swiftlint.yml` present → `verify.lint: swiftlint lint`
- `.swift-format` present → `verify.format: swift-format lint --recursive Sources/`
- `.swiftlint.baseline.json` present → add `--baseline .swiftlint.baseline.json` to lint command
- `.swift-version` / `.xcode-version` → note version constraints in `project.description`

**Python:**
- `pyproject.toml` with `[tool.pytest.ini_options]` → `verify.tests: pytest`; read `--cov-fail-under` for `coverage_threshold`
- `pyproject.toml` with `[tool.ruff]` → `verify.lint: ruff check src/`, `verify.format: ruff format --check src/`
- `pyproject.toml` with `[tool.mypy]` → `verify.typecheck: mypy src/`

**JavaScript/TypeScript:**
- `package.json` scripts → use `npm run <script>` for each detected script (`test`, `lint`, `format`, `typecheck`)

**Rust:**
- `verify.tests: cargo test`, `verify.lint: cargo clippy -- -D warnings`, `verify.format: cargo fmt --check`

**Go:**
- `verify.tests: go test ./...`, `verify.lint: golangci-lint run`

### Phase 4 — Detect CI, pre-commit, and GitHub templates

These don't change `verify.*` commands but inform coverage thresholds, completeness, and PR workflow:

- `.github/workflows/` — scan for coverage threshold values and what gates are enforced in CI
- `.pre-commit-config.yaml` — lists configured hooks; note any linters or formatters not yet captured
- `.githooks/` — project-specific git hooks

**GitHub templates** — if any of these exist, add a `github:` section to `params.yaml`:

| Path | Key |
|------|-----|
| `.github/pull_request_template.md` | `github.pr_template` |
| `docs/pull_request_template.md` | `github.pr_template` |
| `pull_request_template.md` | `github.pr_template` |
| `.github/PULL_REQUEST_TEMPLATE/` | `github.pr_templates_dir` |
| `.github/ISSUE_TEMPLATE/` | `github.issue_templates_dir` |

Example `params.yaml` snippet when templates are found:
```yaml
github:
  pr_template: .github/pull_request_template.md
  issue_templates_dir: .github/ISSUE_TEMPLATE/
```

Commands like REVIEW reference `github.pr_template` to remind contributors what the PR body should contain before merging.

### Phase 5 — Fill in params.yaml

With the above, generate `.flow/params.yaml`. Prefer task runner commands (Phase 1) over individual tool commands (Phase 3) when both exist.

**Verify** the key commands actually work:
```bash
<test_command> --help || echo "Adjust verify.tests in .flow/params.yaml"
<lint_command> --help || echo "Adjust verify.lint in .flow/params.yaml"
```

## Verification Checklist

- [ ] `.flow/params.yaml` exists at repo root (same level as `SPECS/`)
- [ ] `project.name` is filled in
- [ ] `project.default_branch` matches your repo (e.g., `main`)
- [ ] `verify.tests` command runs successfully
- [ ] `verify.lint` command runs successfully

## Troubleshooting

**Problem:** Commands can't find params
**Solution:** Ensure `.flow/params.yaml` exists at the repo root

**Problem:** Quality gate commands fail
**Solution:** Edit `verify.*` in `.flow/params.yaml` with commands that work in your project

## Next Steps

After SETUP completes:

1. Read `FLOW.md` to understand the workflow
2. Create your first task in `Workplan.md`
3. Run `SELECT` to choose a task
4. Run `PLAN` to create the PRD
5. Run `EXECUTE` to implement


## Task System Contract

`task_system` is intentionally lightweight. It stores only static metadata and link templates. Tool-specific behavior (how tasks are selected, transitioned, or synchronized) should be implemented by runtime Skills/adapters, not encoded directly in `params.yaml`. For `kind: file`, set `task_url_template` to a markdown anchor pattern that includes task identifiers/names (for example: `SPECS/Workplan.md#{task_id}-{task_name_slug}`).
