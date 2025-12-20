# macOS Dev Quick Guide

Practical tips for working on a Mac after running `macos-dev-quick-setup.sh`. This guide is tool‑agnostic and not tied to any specific project.

## Running the Script

- Minimal (safe-by-default):
  - `./macos-dev-quick-setup.sh`
- Full (installs casks, applies defaults, configures shell, etc.):
  - `./macos-dev-quick-setup.sh --full`
- Common combos:
  - `./macos-dev-quick-setup.sh --with-casks --configure-shell --configure-git`
  - `./macos-dev-quick-setup.sh --with-mas --install-vscode-exts --open-links`

## Core Concepts

- Prompt and Shell
  - Starship prompt shows git branch/status and directory info at a glance.
  - Zsh plugins: autosuggestions (accept with Right Arrow) and syntax highlighting catch mistakes early.

- Idempotent Config Blocks
  - When you enable shell-related flags (e.g. `--configure-shell`), the script writes BEGIN/END blocks into `~/.zprofile` and `~/.zshrc`.
  - Re-running the script updates just those blocks.

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
  - If enabled (`--install-node-tools`), the script installs `nvm` and installs/uses the latest Node LTS.
  - Corepack is enabled; use `pnpm`, `yarn`, or `npm` per project.

- Bun
  - Installed via the official installer (`bun.sh`) when `--install-node-tools` is enabled.
  - Adds `~/.bun/bin` to PATH when `--configure-shell` is enabled.
  - Useful commands: `bun --version`, `bun install`, `bunx <pkg>`, `bun run <script>`.

- Python
  - Use `uv` for managing Python versions and global CLI apps (e.g., `httpie`, `ruff`, `black`).
  - Upgrade all global tools: `uv tool upgrade --all`.
  - Install new versions: `uv python install 3.13`.

- .NET
  - Dev HTTPS certs are trusted for local hosts; avoids browser warnings.
  - Global .NET tools path (zsh): add to PATH so global tools like `sqlpackage` resolve
    - Add to `~/.zprofile` (login shells):
      - export PATH="$HOME/.dotnet/tools:$PATH"
  - SqlPackage (DACFx) via .NET tool
    - dotnet tool install -g microsoft.sqlpackage
    - sqlpackage /version
    - Note: macOS binary name is `sqlpackage` (no `.exe`).


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
  - If enabled (`--install-vscode-exts`), extensions for JS/TS, Python, .NET, Docker, GitLens are installed. Open a folder with `code .`.

- Terminals
  - WezTerm (fast) and iTerm (rock‑solid) are both available when installing casks.
  - Configure WezTerm at `~/.config/wezterm/wezterm.lua` (written by `--configure-wezterm`).

## AI Coding Assistants

- Claude CLI
  - If you install it (cask `claude`), run it directly as `claude`.

- Codex CLI
  - If you install it (npm package `@openai/codex`), run it directly as `codex`.
  - Prefer normal/sandboxed modes by default; only bypass approvals deliberately when you understand the risk.

## Writing

- iA Writer
  - Installed via the Brewfile using `mas` (Mac App Store). You must be signed into the App Store, and the app must be previously purchased on your Apple ID. Launch with `open -a "iA Writer"`.

## macOS Quality‑of‑Life

- Finder & Dock
  - The script enables path/status bars, shows hidden files, and tunes Dock animations.

- Screenshots
  - Saved to `~/Screenshots` as PNGs.

## Recommended Apps (Casks)

When you run with `--with-casks`, the following are included:

- **Terminals**: Ghostty, WezTerm, Warp, iTerm2.
- **Editors**: VS Code, Cursor, Zed, Rider, DataGrip.
- **Browsers**: Google Chrome.
- **Dev Tools**: Docker, GitHub Desktop, SourceTree, Insomnia, Postman, TablePlus.
- **Utilities**: Raycast, Rectangle, Maccy, CleanShot X, iStat Menus, Bartender, Superwhisper.
- **Productivity/AI**: Slack, Discord, Zoom, Microsoft Teams, Claude, ChatGPT.

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
