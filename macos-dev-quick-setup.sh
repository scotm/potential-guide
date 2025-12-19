#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}▶${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }

trap 'error "Failed at line $LINENO: $BASH_COMMAND"' ERR

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  error "This script is for macOS only"
  exit 1
fi

usage() {
  cat <<'USAGE'
Usage: macos-dev-quick-setup.sh [options]

Safe-by-default: installs Xcode CLT + Homebrew + CLI Brewfile packages.
Invasive steps (macOS defaults, casks, MAS apps, SSH keys, dotfiles, etc.)
are opt-in via flags.

Options:
  --full                  Enable all optional steps
  --with-casks            Install Homebrew casks (GUI apps/fonts)
  --with-mas              Install Mac App Store apps (requires sign-in)
  --apply-macos-defaults  Apply macOS defaults (Finder/Dock/etc.)
  --configure-shell       Configure zsh enhancements + aliases
  --install-oh-my-zsh     Install Oh My Zsh (unattended)
  --configure-git         Apply global git configuration
  --configure-gpg         Configure GPG pinentry settings
  --generate-ssh-key      Generate ~/.ssh/id_ed25519 and ssh config block
  --trust-dotnet-dev-certs Trust .NET HTTPS dev certs
  --setup-docker          Start Docker Desktop + sanity check
  --configure-wezterm     Write WezTerm config (backs up existing)
  --configure-nvim        Write minimal Neovim config (backs up existing)
  --install-node-tools    Install Node LTS (nvm) + Bun/Deno tools
  --install-python-tools  Install Python tooling via pipx
  --install-mssql-tools   Install SQL Server CLI tools
  --install-vscode-exts   Install VS Code extensions
  --open-links            Open helpful URLs at the end
  --write-summary         Write ~/Desktop/setup-complete.md
  -h, --help              Show this help
USAGE
}

# Defaults: safe/minimal
INSTALL_CASKS=0
INSTALL_MAS=0
APPLY_MACOS_DEFAULTS=0
CONFIGURE_SHELL=0
INSTALL_OH_MY_ZSH=0
CONFIGURE_GIT=0
CONFIGURE_GPG=0
GENERATE_SSH_KEY=0
TRUST_DOTNET_DEV_CERTS=0
SETUP_DOCKER=0
CONFIGURE_WEZTERM=0
CONFIGURE_NVIM=0
INSTALL_NODE_TOOLS=0
INSTALL_PYTHON_TOOLS=0
INSTALL_MSSQL_TOOLS=0
INSTALL_VSCODE_EXTS=0
OPEN_LINKS=0
WRITE_SUMMARY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --full)
      INSTALL_CASKS=1
      INSTALL_MAS=1
      APPLY_MACOS_DEFAULTS=1
      CONFIGURE_SHELL=1
      INSTALL_OH_MY_ZSH=1
      CONFIGURE_GIT=1
      CONFIGURE_GPG=1
      GENERATE_SSH_KEY=1
      TRUST_DOTNET_DEV_CERTS=1
      SETUP_DOCKER=1
      CONFIGURE_WEZTERM=1
      CONFIGURE_NVIM=1
      INSTALL_NODE_TOOLS=1
      INSTALL_PYTHON_TOOLS=1
      INSTALL_MSSQL_TOOLS=1
      INSTALL_VSCODE_EXTS=1
      OPEN_LINKS=1
      WRITE_SUMMARY=1
      shift
      ;;
    --with-casks) INSTALL_CASKS=1; shift ;;
    --with-mas) INSTALL_MAS=1; shift ;;
    --apply-macos-defaults) APPLY_MACOS_DEFAULTS=1; shift ;;
    --configure-shell) CONFIGURE_SHELL=1; shift ;;
    --install-oh-my-zsh) INSTALL_OH_MY_ZSH=1; shift ;;
    --configure-git) CONFIGURE_GIT=1; shift ;;
    --configure-gpg) CONFIGURE_GPG=1; shift ;;
    --generate-ssh-key) GENERATE_SSH_KEY=1; shift ;;
    --trust-dotnet-dev-certs) TRUST_DOTNET_DEV_CERTS=1; shift ;;
    --setup-docker) SETUP_DOCKER=1; shift ;;
    --configure-wezterm) CONFIGURE_WEZTERM=1; shift ;;
    --configure-ghostty) CONFIGURE_WEZTERM=1; shift ;; # backwards-compat alias
    --configure-nvim) CONFIGURE_NVIM=1; shift ;;
    --install-node-tools) INSTALL_NODE_TOOLS=1; shift ;;
    --install-python-tools) INSTALL_PYTHON_TOOLS=1; shift ;;
    --install-mssql-tools) INSTALL_MSSQL_TOOLS=1; shift ;;
    --install-vscode-exts) INSTALL_VSCODE_EXTS=1; shift ;;
    --open-links) OPEN_LINKS=1; shift ;;
    --write-summary) WRITE_SUMMARY=1; shift ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      usage
      exit 2
      ;;
  esac
done

log "Starting Mac development environment setup..."

### 0) Xcode command line tools
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools..."
  xcode-select --install
  warn "If a dialog appeared, accept it and re-run this script after installation completes."
  exit 0
fi
success "Xcode Command Line Tools installed"

### 1) Homebrew
# Homebrew is the package manager used for installing CLI tools and apps.
# We detect Apple Silicon (/opt/homebrew) vs Intel (/usr/local) so PATHs are correct.
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew..."
  /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Setup Homebrew PATH for Apple Silicon and Intel Macs
if [[ -f /opt/homebrew/bin/brew ]]; then
  BREW_PREFIX="/opt/homebrew"
elif [[ -f /usr/local/bin/brew ]]; then
  BREW_PREFIX="/usr/local"
else
  error "Homebrew installation not found"
  exit 1
fi

# Activate Homebrew in the current shell
eval "$($BREW_PREFIX/bin/brew shellenv)"
success "Homebrew ready"

# Idempotent config block helper
configure_block() {
  # usage: configure_block <file> <name> <content...>
  local FILE="$1"; shift
  local NAME="$1"; shift
  local BEGIN="# >>> mac-dev-setup ${NAME} >>>"
  local END="# <<< mac-dev-setup ${NAME} <<<"
  mkdir -p "$(dirname "$FILE")"
  touch "$FILE"
  sed -i '' "/$BEGIN/,/$END/d" "$FILE" 2>/dev/null || true
  {
    echo "$BEGIN"
    printf "%s\n" "$@"
    echo "$END"
  } >> "$FILE"
}

backup_file_if_exists() {
  # usage: backup_file_if_exists <file>
  local FILE="$1"
  if [[ -f "$FILE" ]]; then
    cp "$FILE" "$FILE.bak.$(date -u +%Y%m%d-%H%M%S)"
  fi
}

# Ensure brew shellenv is loaded for future shells (login shells use .zprofile)
configure_block "$HOME/.zprofile" brew-shellenv 'if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi'

### 2) Create comprehensive Brewfile
# The Brewfile documents and installs your toolchain in one place.
# We bias toward dev CLIs and editors; GUI apps are included as casks.
BREWFILE="$HOME/Brewfile"
log "Creating Brewfile..."
backup_file_if_exists "$BREWFILE"
cat > "$BREWFILE" <<'EOF'

# === Essential CLI Tools ===
brew "git"
brew "git-flow"             # Git Flow (AVH edition via alias)
brew "gh"                    # GitHub CLI
brew "mas"                   # Mac App Store CLI
brew "wget"
brew "curl"
brew "tree"
brew "htop"
brew "ncdu"                  # disk usage analyzer

# === Modern CLI Replacements ===
# Faster, ergonomic drop-in replacements for common UNIX tools.
brew "fzf"                   # fuzzy finder
brew "ripgrep"               # better grep (rg)
brew "fd"                    # better find
brew "bat"                   # better cat with syntax highlighting
brew "eza"                   # better ls
brew "zoxide"                # better cd
brew "tldr"                  # simplified man pages
brew "jq"                    # JSON processor
brew "yq"                    # YAML processor

# === Development Languages ===
# Pin sane baselines for polyglot projects (Python, Node LTS, Go, Rust).
brew "python@3.13"
brew "nvm"                   # Node Version Manager (installs latest LTS below)
brew "go"
brew "rust"

# === Modern JavaScript Runtimes ===
# Deno as an alternative JS/TS runtime. Bun is installed via bun.sh (optional).
brew "deno"                  # Secure JavaScript/TypeScript runtime

# === Package Managers ===
# pipx isolates Python apps (ruff, httpie) from system/site-packages.
brew "pipx"                  # Python app installer
brew "poetry"                # Python dependency management

# === Shell Enhancements ===
# Prompt, zsh plugins; configured later via idempotent blocks in .zshrc.
brew "starship"              # cross-shell prompt
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# === Development Tools ===
# Cloud CLIs, IaC, editor helpers, shell quality tools.
brew "kubernetes-cli"
brew "helm"
brew "terraform"
brew "awscli"
brew "azure-cli"
brew "flyctl"                # Fly.io CLI
brew "shellcheck"            # shell lint
brew "shfmt"                 # shell formatter
brew "direnv"                # per-project envs
brew "sops"                  # secrets with age/GPG
brew "k9s"                   # k8s TUI
brew "neovim"                # modern terminal-based editor
brew "docker-compose"        # Docker Compose V2

# === Database Tools ===
# Local services and shells; SQL Server tools are added later (optional).
brew "postgresql@16"
brew "redis"
brew "sqlite"
brew "mongosh"               # MongoDB Shell

# === Network Tools ===
# Troubleshooting DNS/latency and general networking.
brew "gping"                 # ping with graph
brew "doggo"                 # better dig (DNS client)
brew "nmap"
brew "mtr"                   # network diagnostic

# === Security Tools ===
# GPG for commit signing and sops; pinentry-mac gives macOS GUI prompts.
brew "gnupg"
brew "age"                   # modern encryption
brew "pinentry-mac"          # GUI pinentry for GPG
EOF

if [[ "$INSTALL_CASKS" == "1" ]]; then
  cat >> "$BREWFILE" <<'EOF'

# === GUI Apps (Homebrew Casks) ===
# Optional: enable with --with-casks
cask "dotnet-sdk"

# Terminals
cask "wezterm"
cask "warp"
cask "iterm2"                # most stable terminal

# Code Editors & IDEs
cask "visual-studio-code"
cask "cursor"
cask "rider"
cask "datagrip"              # database IDE
cask "zed"                   # fast collaborative editor

# Browsers
cask "google-chrome"

# Development Tools
cask "docker"
cask "github"                # GitHub Desktop
cask "sourcetree"            # Git GUI
cask "insomnia"              # API client
cask "postman"
cask "tableplus"             # database GUI
cask "azure-data-studio"
cask "microsoft-azure-storage-explorer"

# Utilities
cask "raycast"               # better than Spotlight
cask "rectangle"             # window management
cask "maccy"                 # clipboard manager
cask "cleanshot"             # CleanShot X - screenshots and annotations
cask "istat-menus"           # system monitoring
cask "bartender"             # menu bar organizer
cask "the-unarchiver"        # archive utility
cask "appcleaner"            # uninstall apps completely
cask "numi"                  # calculator

# Cloud Storage & Sync
cask "google-drive"

# Communication
cask "slack"
cask "discord"
cask "zoom"
cask "microsoft-teams"
cask "whatsapp"

# Productivity
cask "typora"                # markdown editor
cask "microsoft-office"      # Includes OneDrive

# Design
cask "figma"

# AI Tools
cask "claude"
cask "claude-code"
cask "chatgpt"

# Media
cask "iina"
cask "handbrake"             # video converter

# Fonts
tap "homebrew/cask-fonts"
cask "font-jetbrains-mono"
cask "font-jetbrains-mono-nerd-font"
cask "font-fira-code"
cask "font-fira-code-nerd-font"
cask "font-hack-nerd-font"
cask "font-meslo-lg-nerd-font"
EOF
else
  warn "Skipping Homebrew casks (GUI apps/fonts). Re-run with --with-casks to install them."
fi

log "Installing packages from Brewfile..."
brew update
brew bundle --file="$BREWFILE" || warn "Some packages may have failed to install"

# Ensure Git Flow is installed explicitly (requested)
log "Ensuring git-flow is installed..."
brew install git-flow >/dev/null 2>&1 || brew install git-flow-avh >/dev/null 2>&1 || warn "git-flow install failed"

# Optional: SQL Server CLI tools for local/staging connectivity
if [[ "$INSTALL_MSSQL_TOOLS" == "1" ]]; then
  if ! command -v sqlcmd >/dev/null 2>&1; then
    log "Installing SQL Server CLI tools (msodbcsql18, mssql-tools18)..."
    brew tap microsoft/mssql-release https://github.com/microsoft/homebrew-mssql-release || true
    ACCEPT_EULA=Y brew install msodbcsql18 mssql-tools18 || warn "mssql tools install may have partially failed"
  fi

  # Ensure MSSQL tools are on PATH for future shells (login shells read .zprofile)
  if [ -d "$(brew --prefix)/opt/mssql-tools18/bin" ]; then
    configure_block "$HOME/.zprofile" mssql-path "export PATH=\"$(brew --prefix)/opt/mssql-tools18/bin:\$PATH\""
  fi
else
  warn "Skipping SQL Server CLI tools. Re-run with --install-mssql-tools if needed."
fi

# Ensure .NET global tools are on PATH (login shells via .zprofile; interactive via .zshrc)
if [[ "$CONFIGURE_SHELL" == "1" ]]; then
  configure_block "$HOME/.zprofile" dotnet-tools 'if [ -d "$HOME/.dotnet/tools" ]; then
  case ":$PATH:" in
    *":$HOME/.dotnet/tools:"*) ;;
    *) export PATH="$HOME/.dotnet/tools:$PATH" ;;
  esac
fi'
  configure_block "$HOME/.zshrc" dotnet-tools 'if [ -d "$HOME/.dotnet/tools" ]; then
  case ":$PATH:" in
    *":$HOME/.dotnet/tools:"*) ;;
    *) export PATH="$HOME/.dotnet/tools:$PATH" ;;
  esac
fi'
fi

### 3) Configure Node.js and package managers
# Optional: install Node via nvm (latest LTS).
if [[ "$INSTALL_NODE_TOOLS" == "1" ]]; then
  log "Configuring Node.js via nvm (latest LTS)..."

  # nvm is installed via Homebrew (in the Brewfile). Ensure it's initialized.
  NVM_DIR="$HOME/.nvm"
  mkdir -p "$NVM_DIR"

  # Persist nvm init for future shells.
  if [[ "$CONFIGURE_SHELL" == "1" ]]; then
    configure_block "$HOME/.zshrc" nvm 'export NVM_DIR="$HOME/.nvm"
# Homebrew installs nvm to /opt/homebrew/opt/nvm or /usr/local/opt/nvm
[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && . "$(brew --prefix)/opt/nvm/nvm.sh"'
  fi

  # Load nvm into the current shell.
  if [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ]; then
    # shellcheck disable=SC1090
    . "$(brew --prefix)/opt/nvm/nvm.sh"
  fi

  if command -v nvm >/dev/null 2>&1; then
    nvm install --lts --latest-npm >/dev/null 2>&1 || nvm install --lts >/dev/null 2>&1
    nvm alias default 'lts/*' >/dev/null 2>&1 || true
    nvm use --lts >/dev/null 2>&1 || true
  else
    warn "nvm not available in this shell; try restarting your terminal."
  fi

  if command -v node >/dev/null 2>&1; then
    success "Node.js available: $(node --version)"
  else
    warn "Node not on PATH yet. Open a new terminal or run: source ~/.zshrc"
  fi

  # Enable Corepack for pnpm/yarn
  if command -v corepack >/dev/null 2>&1; then
    corepack enable || true
    corepack prepare pnpm@latest --activate || true
  fi

  # Configure Bun and Deno environments
  log "Configuring modern JavaScript runtimes..."

  # Bun (recommended installer)
  BUN_BIN_DIR="$HOME/.bun/bin"
  if ! command -v bun >/dev/null 2>&1; then
    log "Installing Bun (bun.sh installer)..."
    curl -fsSL https://bun.sh/install | bash >/dev/null 2>&1 || warn "Bun install failed"
  fi

  if [[ -d "$BUN_BIN_DIR" ]]; then
    export PATH="$BUN_BIN_DIR:$PATH"
    if [[ "$CONFIGURE_SHELL" == "1" ]]; then
      configure_block "$HOME/.zshrc" bun-path 'if [ -d "$HOME/.bun/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.bun/bin:"*) ;;
    *) export PATH="$HOME/.bun/bin:$PATH" ;;
  esac
fi'
    fi
  fi

  if command -v bun >/dev/null 2>&1; then
    success "Bun available: $(bun --version)"
    bun install -g typescript eslint prettier 2>/dev/null || true
  else
    warn "Bun not available on PATH"
  fi

  # Deno (Homebrew)
  if command -v deno >/dev/null 2>&1; then
    success "Deno installed: $(deno --version)"
    deno install --allow-read --allow-write --allow-net --allow-env --no-check -n vscode-deno https://deno.land/x/vscode_deno@0.9.0/main.ts 2>/dev/null || true
  fi

  # Optional: global npm CLIs
  if command -v npm >/dev/null 2>&1; then
    log "Installing essential npm packages..."
    npm install -g \
      @openai/codex \
      typescript \
      tsx \
      eslint \
      prettier \
      serve \
      npm-check-updates \
      vercel \
      netlify-cli \
      2>/dev/null || warn "Some npm packages may have failed"
  else
    warn "npm not available; skipping global npm packages"
  fi
else
  warn "Skipping Node (nvm) setup. Re-run with --install-node-tools to enable it."
fi

### 4) Configure Python
# Optional: install developer tooling via pipx.
if [[ "$INSTALL_PYTHON_TOOLS" == "1" ]]; then
  log "Configuring Python tooling (pipx)..."

  PYTHON_BIN="$BREW_PREFIX/opt/python@3.13/libexec/bin"
  if [[ "$CONFIGURE_SHELL" == "1" ]]; then
    configure_block "$HOME/.zshrc" python313-path 'if command -v brew >/dev/null 2>&1; then
  PY_BIN="$(brew --prefix)/opt/python@3.13/libexec/bin"
  if [ -d "$PY_BIN" ]; then export PATH="$PY_BIN:$PATH"; fi
fi'
    configure_block "$HOME/.zshrc" pipx-path 'if [ -d "$HOME/.local/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
fi'
  fi

  export PATH="$PYTHON_BIN:$PATH"
  [ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

  # Install essential Python tools
  pipx install --force ruff
  pipx install --force black
  pipx install --force mypy
  pipx install --force ipython
  pipx install --force httpie
else
  warn "Skipping pipx Python tooling. Re-run with --install-python-tools if desired."
fi

# Oh My Zsh keeps a familiar zsh environment; Starship configured below.
### 5) Setup Oh My Zsh + shell enhancements
if [[ "$INSTALL_OH_MY_ZSH" == "1" ]]; then
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi
else
  warn "Skipping Oh My Zsh. Re-run with --install-oh-my-zsh to install it."
fi

if [[ "$CONFIGURE_SHELL" == "1" ]]; then
  log "Configuring shell enhancements..."

  # Starship is a fast, cross-shell prompt with git/dir segments.
  configure_block "$HOME/.zshrc" starship 'eval "$(starship init zsh)"'

  # Zsh plugins
  configure_block "$HOME/.zshrc" zsh-plugins "# Zsh plugins
source $BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

  if command -v zoxide >/dev/null 2>&1; then
    configure_block "$HOME/.zshrc" zoxide 'eval "$(zoxide init zsh)"'
  fi

  if command -v direnv >/dev/null 2>&1; then
    configure_block "$HOME/.zshrc" direnv 'eval "$(direnv hook zsh)"'
  fi

  ### 6) Configure fzf
  log "Configuring fzf..."
  "$BREW_PREFIX"/opt/fzf/install --all --no-bash --no-fish 2>/dev/null || true
else
  warn "Skipping shell enhancements. Re-run with --configure-shell to enable them."
fi

### 7) Git configuration
# Optional: sets global defaults and credential manager.
if [[ "$CONFIGURE_GIT" == "1" ]]; then
  log "Configuring Git..."
  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global core.autocrlf input
  git config --global core.editor "code --wait"
  git config --global merge.tool vscode
  git config --global mergetool.vscode.cmd 'code --wait $MERGED'
  git config --global diff.tool vscode
  git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'

  if command -v git-credential-manager >/dev/null 2>&1; then
    git-credential-manager configure || true
  else
    brew install --cask git-credential-manager >/dev/null 2>&1 || true
    git-credential-manager configure || true
  fi
else
  warn "Skipping global Git configuration. Re-run with --configure-git if desired."
fi

# GUI passphrase prompts for GPG commit signing and sops usage.
### 7.5) GPG pinentry (GUI)
if [[ "$CONFIGURE_GPG" == "1" ]] && command -v gpg >/dev/null 2>&1; then
  log "Configuring GPG pinentry (GUI)..."
  mkdir -p "$HOME/.gnupg" && chmod 700 "$HOME/.gnupg"
  PINENTRY_BIN="$(command -v pinentry-mac || true)"
  if [ -z "$PINENTRY_BIN" ]; then
    [ -x /opt/homebrew/bin/pinentry-mac ] && PINENTRY_BIN=/opt/homebrew/bin/pinentry-mac || PINENTRY_BIN=/usr/local/bin/pinentry-mac
  fi
  configure_block "$HOME/.gnupg/gpg-agent.conf" pinentry "pinentry-program $PINENTRY_BIN
default-cache-ttl 600
max-cache-ttl 7200"
  chmod 600 "$HOME/.gnupg/gpg-agent.conf" 2>/dev/null || true
  gpgconf --kill gpg-agent 2>/dev/null || true
elif [[ "$CONFIGURE_GPG" == "1" ]]; then
  warn "GPG not available; skipping pinentry configuration."
else
  warn "Skipping GPG pinentry configuration. Re-run with --configure-gpg to enable it."
fi

### 8) Setup SSH key
if [[ "$GENERATE_SSH_KEY" == "1" ]]; then
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"

  if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    log "Generating SSH key..."
    ssh-keygen -t ed25519 -C "$(hostname)" -f "$HOME/.ssh/id_ed25519" -N ""
    success "SSH key generated at ~/.ssh/id_ed25519.pub"
  else
    success "SSH key already exists at ~/.ssh/id_ed25519"
  fi

  # Start ssh-agent and add key
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519" 2>/dev/null || ssh-add "$HOME/.ssh/id_ed25519" || true

  # Configure SSH to use keychain (non-destructive block)
  SSH_CONFIG="$HOME/.ssh/config"
  backup_file_if_exists "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG" 2>/dev/null || true
  configure_block "$SSH_CONFIG" macos-keychain "Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519"
  chmod 600 "$SSH_CONFIG" 2>/dev/null || true

  warn "Add your SSH key to GitHub: pbcopy < ~/.ssh/id_ed25519.pub"
else
  warn "Skipping SSH key generation. Re-run with --generate-ssh-key to enable it."
fi

### 9) .NET development certificates
# Optional: trusts dev HTTPS certs so local HTTPS hosts work without warnings.
if [[ "$TRUST_DOTNET_DEV_CERTS" == "1" ]]; then
  log "Trusting .NET development certificates..."
  if command -v dotnet >/dev/null 2>&1; then
    dotnet dev-certs https --trust 2>/dev/null || true
  else
    warn "dotnet not found; skipping dev-certs trust"
  fi
else
  warn "Skipping .NET dev-certs trust. Re-run with --trust-dotnet-dev-certs if desired."
fi

### 10) Docker configuration
# Optional: starts Docker Desktop and runs a hello-world sanity check.
if [[ "$SETUP_DOCKER" == "1" ]]; then
  log "Configuring Docker..."

  if [ -d "/Applications/Docker.app" ]; then
    open -g -a "Docker" || true
  else
    warn "Docker.app not found (install via --with-casks or manually)."
  fi

  # Ensure Docker Desktop CLI + credential helper resolve
  DD="/Applications/Docker.app/Contents/Resources/bin"
  if [ -x "$DD/docker" ] && [ -x "$DD/docker-credential-osxkeychain" ]; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$DD/docker" "$HOME/.local/bin/docker" || true
    ln -sf "$DD/docker-credential-osxkeychain" "$HOME/.local/bin/docker-credential-osxkeychain" || true
  fi

  # Preflight: engine reachability, set Desktop context, pull hello-world
  if command -v docker >/dev/null 2>&1; then
    docker context use desktop-linux >/dev/null 2>&1 || true
    if ! docker version >/dev/null 2>&1; then
      warn "Docker engine not reachable yet; waiting briefly..."
      sleep 5
    fi
    if ! docker run --rm hello-world >/dev/null 2>&1; then
      warn "hello-world still failing; try again after Docker fully starts"
    fi
  else
    warn "docker CLI not found on PATH."
  fi
else
  warn "Skipping Docker setup. Re-run with --setup-docker if desired."
fi

### 11) Setup WezTerm
# Writes a minimal WezTerm config; backs up existing config if present.
if [[ "$CONFIGURE_WEZTERM" == "1" ]]; then
  log "Configuring WezTerm..."
  WEZTERM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm"
  WEZTERM_CONFIG_FILE="$WEZTERM_CONFIG_DIR/wezterm.lua"
  mkdir -p "$WEZTERM_CONFIG_DIR"
  backup_file_if_exists "$WEZTERM_CONFIG_FILE"

  cat > "$WEZTERM_CONFIG_FILE" <<'WEZTERM'
local wezterm = require 'wezterm'

return {
  font = wezterm.font('JetBrains Mono'),
  font_size = 13.0,
  color_scheme = 'Catppuccin Mocha',
  window_padding = { left = 10, right = 10, top = 10, bottom = 10 },
  window_background_opacity = 0.95,
}
WEZTERM
else
  warn "Skipping WezTerm config. Re-run with --configure-wezterm to write it."
fi

### 12) macOS System Preferences
# Optional: sensible defaults (Finder visibility, Dock behavior, keyboard/trackpad, etc.)
if [[ "$APPLY_MACOS_DEFAULTS" == "1" ]]; then
  log "Configuring macOS preferences..."

  # Finder
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"  # Search current folder
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

  # Set list view as default for all Finder windows
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  # Arrange by name in list view
  defaults write com.apple.finder FXArrangeGroupViewBy -string "Name"
  defaults write com.apple.finder FXPreferredGroupBy -string "None"

  # Dock
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock autohide-time-modifier -float 0.3
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock minimize-to-application -bool true

  # Screenshots
  mkdir -p "$HOME/Screenshots"
  defaults write com.apple.screencapture location -string "$HOME/Screenshots"
  defaults write com.apple.screencapture type -string "png"

  # Keyboard
  defaults write NSGlobalDomain KeyRepeat -int 1
  defaults write NSGlobalDomain InitialKeyRepeat -int 10
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  # Trackpad
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

  # Safari Developer Menu
  defaults write com.apple.Safari IncludeDevelopMenu -bool true

  # TextEdit plain text by default
  defaults write com.apple.TextEdit RichText -int 0

  # Restart affected services
  killall Finder 2>/dev/null || true
  killall Dock 2>/dev/null || true
else
  warn "Skipping macOS defaults. Re-run with --apply-macos-defaults to enable them."
fi

### 13) Install Mac App Store apps
# Optional: requires sign-in; run `mas signin` or open App Store.
if [[ "$INSTALL_MAS" == "1" ]]; then
  log "Installing Mac App Store apps..."
  if command -v mas >/dev/null 2>&1 && mas account >/dev/null 2>&1; then
    mas install 775737590  # iA Writer
    mas install 1352778147 # Bitwarden
    mas install 904280696  # Things 3
    mas install 1153157709 # Speedtest
  else
    warn "Not signed into Mac App Store (or mas missing) - skipping app installations"
  fi
else
  warn "Skipping Mac App Store apps. Re-run with --with-mas to enable them."
fi

### 14) Create useful directories
log "Creating development directories..."
mkdir -p "$HOME/Projects"
mkdir -p "$HOME/Scripts"
mkdir -p "$HOME/.config"

### 15) Setup shell aliases
# Optional: installs aliases into ~/.zshrc.
if [[ "$CONFIGURE_SHELL" == "1" ]]; then
  # Safer defaults (no aliasing cd). `cat` uses bat -pp to preserve pipes.
  ALIASES_CONTENT=''
  read -r -d '' ALIASES_CONTENT <<'ALIASES'

# Custom aliases
alias ll='eza -la --icons --git'
alias l='eza -l --icons --git'
alias ls='eza --icons'
alias tree='eza --tree --icons'
alias cat='bat -pp'
# Only alias grep in interactive shells
if [[ $- == *i* ]]; then alias grep='rg'; fi
alias find='fd'
alias du='ncdu'
alias top='htop'
alias g='git'
alias d='docker'
alias k='kubectl'
alias tf='terraform'
alias py='python3'
alias pip='pip3'
alias n='npm'
alias p='pnpm'
alias y='yarn'

# Git aliases
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias ga='git add'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# Directory shortcuts
alias proj='cd ~/Projects'
alias projects='cd ~/Projects'
alias dl='cd ~/Downloads'
alias dt='cd ~/Desktop'
alias docs='cd ~/Documents'

# Quick edits
alias zshrc='code ~/.zshrc'
alias reload='source ~/.zshrc'
alias nvimrc='nvim ~/.config/nvim/init.lua'
alias vimrc='nvim ~/.vimrc'

# Network
alias ip='curl ifconfig.me'
alias localip='ipconfig getifaddr en0'
alias flush='dscacheutil -flushcache'

# Development
alias serve='python3 -m http.server 8000'
alias json='python3 -m json.tool'

# Modern JavaScript runtimes
alias bun-dev='bun --hot'
alias deno-dev='deno run --watch'
alias deno-task='deno task'

# Docker
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs -f'
alias dprune='docker system prune'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
ALIASES
  configure_block "$HOME/.zshrc" aliases "$ALIASES_CONTENT"
else
  warn "Skipping aliases. Re-run with --configure-shell to enable them."
fi

### 16) Configure Neovim
if [[ "$CONFIGURE_NVIM" == "1" ]]; then
  log "Configuring Neovim..."
  NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  mkdir -p "$NVIM_CONFIG"
  backup_file_if_exists "$NVIM_CONFIG/init.lua"

  # Create basic Neovim config
  cat > "$NVIM_CONFIG/init.lua" <<'NVIM'
-- Basic Neovim configuration
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic keybindings
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "<leader>w", "<C-w>v")
vim.keymap.set("n", "<leader>s", "<C-w>s")

-- Netrw settings
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
NVIM

  # Create backup directory for undofile
  mkdir -p "$HOME/.vim/undodir"

  success "Neovim configured with basic settings"
else
  warn "Skipping Neovim config. Re-run with --configure-nvim to write it."
fi

### 17) Final setup steps
log "Running final setup..."

# VS Code extensions
if [[ "$INSTALL_VSCODE_EXTS" == "1" ]]; then
  if command -v code >/dev/null 2>&1; then
    log "Installing VS Code extensions..."
    code --install-extension dbaeumer.vscode-eslint
    code --install-extension esbenp.prettier-vscode
    code --install-extension ms-python.python
    code --install-extension ms-vscode.cpptools
    code --install-extension golang.go
    code --install-extension rust-lang.rust-analyzer
    code --install-extension ms-dotnettools.csharp
    code --install-extension GitHub.copilot
    code --install-extension eamodio.gitlens
    code --install-extension ms-vscode-remote.remote-containers
    code --install-extension ms-azuretools.vscode-docker
    code --install-extension denoland.vscode-deno
    code --install-extension oven.bun-vscode
    2>/dev/null || warn "Some VS Code extensions may have failed"
  else
    warn "VS Code CLI ('code') not found; skipping extensions"
  fi
else
  warn "Skipping VS Code extensions. Re-run with --install-vscode-exts to enable them."
fi

# Open useful links
if [[ "$OPEN_LINKS" == "1" ]]; then
  log "Opening helpful resources..."
  open "https://github.com/settings/keys" || true
else
  warn "Skipping opening browser links. Re-run with --open-links if desired."
fi

# Create a summary file
if [[ "$WRITE_SUMMARY" == "1" ]]; then
  SUMMARY_FILE="$HOME/Desktop/setup-complete.md"
  backup_file_if_exists "$SUMMARY_FILE"

  cat > "$SUMMARY_FILE" <<'SUMMARY'
# Mac Development Setup Complete

## Quick Checks
- Node (nvm): `node --version`
- Bun: `bun --version`

## Maintenance
- Homebrew: `brew update && brew upgrade` (and occasionally `brew cleanup`)
- Python tools (pipx): `pipx upgrade-all`

## Next Steps
- Restart your terminal or run: `exec zsh`
- Set Git identity:
  - `git config --global user.name "Your Name"`
  - `git config --global user.email "you@example.com"`
SUMMARY
else
  warn "Skipping summary file. Re-run with --write-summary to enable it."
fi

success "Setup complete"
echo ""
warn "Important next steps:"
echo "  1. Restart your terminal or run: exec zsh"
if [[ "$GENERATE_SSH_KEY" == "1" ]]; then
  echo "  2. Add SSH key to GitHub: pbcopy < ~/.ssh/id_ed25519.pub"
else
  echo "  2. (Optional) Generate SSH key: re-run with --generate-ssh-key"
fi
if [[ "$CONFIGURE_GIT" == "0" ]]; then
  echo "  3. (Optional) Configure Git defaults: re-run with --configure-git"
else
  echo "  3. Configure Git identity (name/email)"
fi
if [[ "$WRITE_SUMMARY" == "1" ]]; then
  echo "  4. Check ~/Desktop/setup-complete.md for a cheat sheet"
fi
