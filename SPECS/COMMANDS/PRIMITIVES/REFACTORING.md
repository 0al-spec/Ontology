---
name: "refactoring"
description: "Use when code needs restructuring for clarity, maintainability, or separation of concerns."
---

# REFACTORING — Code Restructuring Guide

**Version:** 1.5.0

## Purpose

Guide for refactoring code while maintaining functionality and test coverage.

## When to Refactor

- Functions exceed 50 lines
- Multiple responsibilities in one module
- Duplicate code patterns
- Poor naming conventions
- Circular import risks
- Code smells (long parameter lists, deep nesting, etc.)

## Guidelines

### Function Extraction

- Extract helper functions for complex logic
- Keep functions focused on single responsibility
- Use descriptive names with verb prefixes

### Module Organization

Language-specific examples:

**Python:**
```
src/
├── __init__.py          # Package exports
├── __main__.py          # CLI entry point
├── core.py              # Core business logic
├── utils.py             # Shared utilities
└── models.py            # Data structures
```

**JavaScript/TypeScript:**
```
src/
├── index.ts             # Package exports
├── cli.ts               # CLI entry point
├── core/                # Core business logic
├── utils/               # Shared utilities
└── types/               # Type definitions
```

**Rust:**
```
src/
├── main.rs              # Binary entry point
├── lib.rs               # Library exports
├── core.rs              # Core business logic
└── utils.rs             # Shared utilities
```

### Testing During Refactor

1. Ensure tests pass before refactoring
2. Make incremental changes
3. Run tests after each change
4. Maintain coverage threshold (e.g., ≥80%)

### Language-Specific Patterns

**Python:**
- Use type hints for function signatures
- Prefer dataclasses for structured data
- Use context managers (`with` statements) for resource management
- Follow PEP 8 naming conventions
- Use f-strings for string formatting

**JavaScript/TypeScript:**
- Use TypeScript for type safety
- Prefer `const`/`let` over `var`
- Use async/await for asynchronous code
- Follow ESLint configuration
- Use template literals for string formatting

**Rust:**
- Use strong typing with enums and structs
- Leverage the ownership system
- Use `Result` and `Option` for error handling
- Follow `rustfmt` and `clippy` guidance

**Go:**
- Use idiomatic error handling
- Keep interfaces small
- Use goroutines and channels for concurrency
- Follow `gofmt` formatting

## Verification

After refactoring, run your project's quality gates:

```bash
# Tests
npm test / pytest / cargo test / go test

# Linting
npm run lint / ruff check src/ / cargo clippy / golangci-lint

# Coverage
npm run test:coverage / pytest --cov / cargo tarpaulin / go test -cover
```

Check [Params](.flow/params.yaml) under `verify.*` for project-specific commands.
