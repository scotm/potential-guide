# Agent Guide

## Build & Test
- **Lint**: `shellcheck macos-dev-quick-setup.sh`
- **Format**: `shfmt -i 2 -w macos-dev-quick-setup.sh` (matches 2-space indent)
- **Test**: No automated tests. **CAUTION**: Script modifies system state (files, brews, configs).
- **Run**: `./macos-dev-quick-setup.sh --help` to check syntax/help.

## Code Style
- **Bash**: Strict mode `set -euo pipefail` required. Use `trap` for errors.
- **Formatting**: 2-space indentation. Keep lines < 100 chars where possible.
- **Naming**: `UPPER_CASE` for globals/constants, `snake_case` for functions/locals.
- **Output**: Use `log`, `warn`, `error`, `success` helper functions for consistency.
- **Idempotency**: Ops must be idempotent (check if installed/configured before acting).
- **Blocks**: Use `configure_block` helper for config file edits (Start/End markers).
- **Paths**: Use absolute paths or resolved variables (e.g., `$HOME`, `$BREW_PREFIX`).
