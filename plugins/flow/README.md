# Flow Plugin

This plugin packages Flow skills from this repository.

## Included Skills

- `flow-setup`: Installs and initializes Flow in a target repository.
- `flow-update`: Updates Flow-managed files in an existing repository safely.
- `flow-run`: Runs the full FLOW process from `BRANCH` through `ARCHIVE-REVIEW`.

## Example Prompt

Setup prompt:

`Use $flow-setup to install Flow into this repository and configure it for my stack.`

Execution prompt:

`Use $flow-run: Strictly follow the instructions in @SPECS/COMMANDS/FLOW.md for the next task, do not stop between steps, and complete each FLOW phase one by one without pausing.`

Update prompt:

`Use $flow-update to refresh this repository to the latest pinned Flow version and verify user-owned files were preserved.`
