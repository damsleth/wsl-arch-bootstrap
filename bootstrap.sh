#!/usr/bin/env bash
#
# bootstrap.sh — provision a fresh Arch-on-WSL instance for Claude Code.
#
# Designed to run as root inside a freshly-installed Arch WSL distro.
# Safe to re-run: every step is idempotent (--needed / existence checks).
#
# Usage:
#   bash bootstrap.sh              # full setup
#   EDITOR_PKG=neovim bash bootstrap.sh   # override default editor
#   SKIP_CLAUDE=1 bash bootstrap.sh       # skip Claude Code install
#
set -euo pipefail

# ── tunables ────────────────────────────────────────────────────────────────
GIT_NAME="${GIT_NAME:-Carl Joakim Damsleth}"
GIT_EMAIL="${GIT_EMAIL:-Carl.Joakim.Damsleth@crayon.no}"
EDITOR_PKG="${EDITOR_PKG:-vim}"          # vim by default; set to neovim/nano/etc
DEFAULT_EDITOR="${DEFAULT_EDITOR:-vim}"  # what $EDITOR points to
SKIP_CLAUDE="${SKIP_CLAUDE:-0}"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# ── 0. sanity ────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  warn "Not running as root. This kit assumes root-mode WSL; sudo will be used where present."
  SUDO="sudo"
else
  SUDO=""
fi

# ── 1. pacman: sync DBs, tune, full upgrade ─────────────────────────────────
log "Syncing package databases and upgrading the system..."
# Make pacman nicer: parallel downloads + color (idempotent edits)
if ! grep -q '^ParallelDownloads' /etc/pacman.conf; then
  sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf || true
fi
if ! grep -q '^Color' /etc/pacman.conf; then
  sed -i 's/^#Color/Color/' /etc/pacman.conf || true
fi
$SUDO pacman -Syu --noconfirm

# ── 2. core packages ─────────────────────────────────────────────────────────
log "Installing core toolchain and CLI utilities..."
$SUDO pacman -S --needed --noconfirm \
  base-devel git curl wget unzip \
  nodejs npm \
  ripgrep fd bat fzf jq \
  openssh man-db which \
  "$EDITOR_PKG"

# ── 3. shell quality-of-life ─────────────────────────────────────────────────
log "Configuring shell defaults..."
PROFILE="$HOME/.bashrc"
touch "$PROFILE"
add_line() { grep -qxF "$1" "$PROFILE" || echo "$1" >> "$PROFILE"; }

add_line "export EDITOR=${DEFAULT_EDITOR}"
add_line "export VISUAL=${DEFAULT_EDITOR}"
add_line "alias ll='ls -alh --color=auto'"
add_line "alias cat='bat --paging=never'"
add_line "alias claude-yolo='claude --dangerously-skip-permissions'"
# fzf keybindings if present
add_line '[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash'
add_line '[ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash'

# ── 4. git config ────────────────────────────────────────────────────────────
log "Configuring git..."
git config --global user.name  "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global pull.rebase false

# ── 5. Claude Code ───────────────────────────────────────────────────────────
if [[ "$SKIP_CLAUDE" != "1" ]]; then
  if command -v claude >/dev/null 2>&1; then
    log "Claude Code already installed ($(command -v claude)) — skipping."
  else
    log "Installing Claude Code (native installer)..."
    if curl -fsSL https://claude.ai/install.sh | bash; then
      :
    else
      warn "Native installer failed; falling back to npm."
      $SUDO npm install -g @anthropic-ai/claude-code
    fi
  fi
  # Ensure the install dir is on PATH for future shells
  add_line 'export PATH="$HOME/.local/bin:$PATH"'
  export PATH="$HOME/.local/bin:$PATH"
fi

# ── 6. drop a CLAUDE.md so the in-WSL agent knows its environment ────────────
log "Writing ~/.claude/CLAUDE.md..."
mkdir -p "$HOME/.claude"
if [[ -f "$(dirname "$0")/CLAUDE.md" ]]; then
  cp "$(dirname "$0")/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
else
  warn "CLAUDE.md not found next to script; skipping copy."
fi

log "Done."
echo
echo "Next steps:"
echo "  1. source ~/.bashrc        # load aliases/PATH in this shell"
echo "  2. claude                  # first run signs you in"
echo "  3. Paste the kickoff prompt (kickoff-prompt.md) to let Claude finish the setup."
