# macOS Dev Quick Guide

Practical tips for working on a Mac after running `macos-dev-quick-setup.sh`. This guide is tool‑agnostic and not tied to any specific project.

## Running the Script

- Full installation (default):
  - `./macos-dev-quick-setup.sh`
  - Installs everything: casks, macOS defaults, shell configuration, dev tools, etc.
- Selective installation:
  - `./macos-dev-quick-setup.sh --with-casks --configure-shell --configure-git`
  - `./macos-dev-quick-setup.sh --install-vscode-exts --open-links`
  - `./macos-dev-quick-setup.sh --install-node-tools --installpython-tools`
- View all options:
  - `./macos-dev-quick-setup.sh --help`

## Core Concepts

- Prompt and Shell
  - Starship prompt shows git branch/status and directory info at a glance.
  - Zsh plugins: autosuggestions (accept with Right Arrow) and syntax highlighting catch mistakes early.

- Idempotent Config Blocks
  - The script writes BEGIN/END blocks into `~/.zprofile` and `~/.zshrc` for shell configuration.
  - Re-running the script updates just those blocks, keeping your other configs intact.

- Debug Mode
  - Set `MAC_DEV_SETUP_DEBUG=1` before running to enable early exit diagnostics.
  - Helps track down silent failures that can occur with tools like nvm.

## Navigation & Discovery

- zoxide (jump to folders)
  - `z foo` jumps to the most relevant folder matching “foo”.
  - `z foo bar` matches a path containing both terms.
  - `zi` opens an interactive picker (uses fzf when available).

- fzf (fuzzy finder)
  - Ctrl‑R: interactive shell history search.
  - Ctrl‑T: insert a fuzzy‑picked file path into the command line.
  - Alt‑C: change directory via a fuzzy picker.

## Modern CLI Replacements

- Listing and viewing
  - `ls` (eza): pretty listings with icons; `l`, `ll`, and `tree` variants are available.
  - `cat` is `bat -pp`: syntax‑highlighted output that preserves pipes.

- Search and find
  - `rg` (ripgrep) is a fast grep that respects `.gitignore`.
  - `fd` is a simpler, faster `find` for common cases.

- Handy docs
  - `tldr <command>` shows concise examples.

## Runtimes & Packages

- Node.js
  - Installed by default (`--install-node-tools`). Installs `nvm` and uses latest Node LTS.
  - Corepack is enabled; use `pnpm`, `yarn`, or `npm` per project.

- Bun
  - Installed via the official installer (`bun.sh`) by default.
  - Adds `~/.bun/bin` to PATH automatically.
  - Useful commands: `bun --version`, `bun install`, `bunx <pkg>`, `bun run <script>`.

- Python
  - Installed by default (`--install-python-tools`). Uses `uv` to manage Python versions and global CLI apps (e.g., `httpie`, `ruff`, `black`, `mypy`).
  - Upgrade all global tools: `uv tool upgrade --all`.
  - Install new versions: `uv python install 3.14`.

- .NET
  - Dev HTTPS certs trusted by default (`--trust-dotnet-dev-certs`) to avoid browser warnings.
  - SQL Server CLI tools installed by default (`--install-mssql-tools`).
  - Global .NET tools path automatically added to PATH.
  - SqlPackage available via `dotnet tool install -g microsoft.sqlpackage`.


## Environment Management (direnv)

- What it does
  - Automatically loads and unloads environment variables when you `cd` into a folder containing an `.envrc` (after you allow it).

- One‑time enablement
  - The script adds `eval "$(direnv hook zsh)"` to `~/.zshrc`.
  - Verify with `direnv --version`.

- Typical usage pattern
  - In a project root: create `.envrc` with safe defaults.
  - Keep secrets in an untracked `.env.local` loaded via `dotenv_if_exists .env.local`.
  - Trust once with `direnv allow` in that directory.
  - Edit and reload with `direnv reload` or by re‑entering the directory.

## Git, Credentials, and Signing

- Git Credential Manager
  - Handles HTTPS auth flows for GitHub/Azure; avoids storing tokens in plain text.

- Git Flow
  - Installed by the setup. Manually install/verify: `brew install git-flow`.
  - Initialize in a repo: `git flow init -d` (uses sane defaults).
  - Example: start a feature branch: `git flow feature start my-feature`.

- GPG via pinentry‑mac
  - Native macOS prompt for passphrases. To sign commits:
    1) `gpg --full-generate-key` (if you don’t have one)
    2) `gpg --list-secret-keys --keyid-format=long`
    3) `git config --global user.signingkey <KEYID>`
    4) `git config --global commit.gpgSign true`

## Containers

- Docker Desktop
  - Validate: `docker version` (Client and Server sections), `docker ps`.
  - Useful helpers:
    - `dps`, `dpsa` – running/all containers
    - `dlog <name>` – tail logs
    - `dex <name> bash` – shell into a container
    - `dprune` – prune unused images/containers (destructive; use carefully)

## Editors & Terminal

- VS Code
  - Extensions installed by default (`--install-vscode-exts`) for JS/TS, Python, .NET, Docker, GitLens, etc.
  - Open a repository with `code .`.

- Terminals
  - WezTerm (fast) and iTerm (rock‑solid) are both available when installing casks.
  - Configure WezTerm at `~/.config/wezterm/wezterm.lua` (written by `--configure-wezterm`).

## AI Coding Assistants

- Claude CLI
  - If you install it (cask `claude`), run it directly as `claude`.

- Codex CLI
  - If you install it (npm package `@openai/codex`), run it directly as `codex`.
  - Prefer normal/sandboxed modes by default; only bypass approvals deliberately when you understand the risk.



## Shell Configuration

Configured by default (`--configure-shell`) includes:

- Zsh plugins (autosuggestions, syntax highlighting)
- Starship prompt with git/context info
- zoxide for smart directory jumping
- direnv for project-specific environments
- fzf for fuzzy finding
- Comprehensive aliases for common commands

## macOS Quality‑of‑Life

Applied by default (`--apply-macos-defaults`):

- Finder & Dock
  - Enables path/status bars, shows hidden files, tunes Dock animations, sets list view as default.

- Screenshots
  - Saved to `~/Screenshots` as PNGs.

- Keyboard & Trackpad
  - Faster key repeat, disables press-and-hold, enables tap-to-click, reverses natural scrolling.

- Sudo Sessions
  - Configured for 30-minute timeout to reduce password prompts during setup.

## Recommended Apps (Casks)

Installed by default (`--with-casks`):

- **Terminals**: Ghostty, WezTerm, Warp, iTerm2.
- **Editors**: VS Code, Cursor, Zed, Rider, DataGrip.
- **Browsers**: Google Chrome.
- **Dev Tools**: Docker, GitHub Desktop, SourceTree, Insomnia, Postman, TablePlus.
- **Utilities**: Raycast, Rectangle, Maccy, CleanShot X, iStat Menus, Bartender, Superwhisper.
- **Productivity/AI**: Slack, Discord, Zoom, Microsoft Teams, Claude, ChatGPT.

## Additional Features

- SSH Keys: Generated by default (`--generate-ssh-key`) with ed25519 and Apple Keychain integration
- Oh My Zsh: Installed by default for familiar zsh environment
- Neovim: Basic configuration installed by default (`--configure-nvim`)
- WezTerm/Ghostty: Terminal configs written by default (`--configure-wezterm`, `--configure-ghostty`)
- Docker: Started and sanity-checked by default (`--setup-docker`)
- Summary File: Written to desktop by default (`--write-summary`) with post-setup checklist

## Utilities
  - Raycast (launcher), Rectangle (tiling), Maccy (clipboard), and more.

## Safety Defaults

- Interactive file ops
  - `rm`, `cp`, and `mv` prompt before destructive actions.

- Grep compatibility
  - In interactive shells only, `grep` maps to `rg`. Scripts keep standard `grep`.

## Maintenance

- Homebrew
  - `brew update && brew upgrade` and occasionally `brew cleanup`.

- Node
  - Prefer project‑local dependencies; update globals carefully.

- Python CLIs
  - `uv tool upgrade --all`.

- Docker
  - Prune periodically to reclaim space: `dprune` (review what’s being removed).

## Troubleshooting Tips

- PATH sanity: `echo $PATH`; `which docker/node/python/sqlcmd` to see what is active.
- Docker engine missing:
  - Ensure “Docker Desktop” is running.
  - `docker context use desktop-linux` and rerun `docker version`.
- direnv not loading:
  - Confirm `.envrc` exists, then `direnv allow`; run `direnv doctor` if needed.
- GPG prompt not appearing:
  - `gpgconf --kill gpg-agent` then try again; ensure `pinentry-mac` exists.

## Cheat Sheet

- Navigation: `z`, `zi`, Alt‑C, Ctrl‑T, Ctrl‑R
- Listings: `ll`, `l`, `tree`
- Search: `rg <term>`, `fd <pattern>`
- Docs: `tldr <cmd>`
- Env (direnv): `direnv allow`, `direnv reload`
- Docker: `dps`, `dpsa`, `dlog`, `dex`, `dprune`

## Customize

- Shell blocks live in:
  - `~/.zprofile` (login PATH like Homebrew, MSSQL tools)
  - `~/.zshrc` (prompt, plugins, zoxide, direnv, Node/Python PATH, aliases)
  - Edit between `# >>> mac-dev-setup NAME >>>` and `# <<< mac-dev-setup NAME <<<`.
