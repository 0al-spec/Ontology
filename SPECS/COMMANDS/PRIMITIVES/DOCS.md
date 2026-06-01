---
name: "docs"
description: "Use when updating project documentation, README, or code documentation."
---

# DOCS — Documentation Updates

**Version:** 1.5.0

## Purpose

Update project documentation, code comments, and README files.

## Documentation Types

### Code Documentation

Add documentation to all public functions and classes. Follow your language's standard conventions:

**Python (Google/NumPy style):**
```python
def process_data(input_data: str) -> dict:
    """Process input data and return structured result.
    
    Args:
        input_data: Raw string data to process.
        
    Returns:
        Structured dictionary with processed fields.
    """
```

**JavaScript/TypeScript (JSDoc):**
```javascript
/**
 * Process input data and return structured result.
 * @param {string} inputData - Raw string data to process
 * @returns {Object} Structured object with processed fields
 */
function processData(inputData) { ... }
```

**Rust (rustdoc):**
```rust
/// Process input data and return structured result.
///
/// # Arguments
///
/// * `input_data` - Raw string data to process
///
/// # Returns
///
/// Structured data with processed fields
fn process_data(input_data: &str) -> Result<Data, Error> { ... }
```

### Project Documentation

- Update `README.md` for user-facing changes
- Update `AGENTS.md` for agent-specific context (if used)
- Update `SPECS/` documentation for design decisions

### Configuration Documentation

- Document config options in code
- Update example configuration files
- Keep setup instructions current

## Checklist

- [ ] Code documentation added/updated for modified functions
- [ ] README updated if behavior changes
- [ ] `AGENTS.md` updated if present and agent workflow changes
- [ ] Configuration examples remain valid
