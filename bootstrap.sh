#!/usr/bin/env bash
#
# bootstrap.sh — provision a fresh Arch-on-WSL instance for Claude Code.
#
# Designed to run as root inside a freshly-installed Arch WSL distro.
# Safe to re-run: every step is idempotent (--needed / existence checks).
#
# Usage:
#   bash bootstrap.sh                     # full setup
#   EDITOR_PKG=neovim bash bootstrap.sh   # override default editor
#   SKIP_CLAUDE=1 bash bootstrap.sh       # skip Claude Code install
#   INSTALL_RUST=0 bash bootstrap.sh      # skip the large rust toolchain (~300MB)
#   INSTALL_EXTRAS=0 bash bootstrap.sh    # core only, no convenience tools
#
# Note: the AUR is intentionally NOT used. makepkg refuses to run as root and
# this box stays root-only (no build user), so AUR-only packages (PowerShell,
# ruby-install, ...) are out of scope by design. Everything here is in the
# official repos.
#
set -euo pipefail

# ── tunables ────────────────────────────────────────────────────────────────
GIT_NAME="${GIT_NAME:-Carl Joakim Damsleth}"
GIT_EMAIL="${GIT_EMAIL:-Carl.Joakim.Damsleth@crayon.no}"
EDITOR_PKG="${EDITOR_PKG:-vim}"          # vim by default; set to neovim/nano/etc
DEFAULT_EDITOR="${DEFAULT_EDITOR:-vim}"  # what $EDITOR points to
SKIP_CLAUDE="${SKIP_CLAUDE:-0}"
INSTALL_EXTRAS="${INSTALL_EXTRAS:-1}"    # starship/eza/zoxide/tmux/btop/...
INSTALL_RUST="${INSTALL_RUST:-1}"        # rust toolchain is ~300MB; set 0 to skip

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

# ── 2b. developer conveniences (official repos only — no AUR) ────────────────
if [[ "$INSTALL_EXTRAS" == "1" ]]; then
  log "Installing developer conveniences..."
  # starship  prompt        eza   modern ls     zoxide  smart cd
  # tmux      multiplexer   btop  resource mon   nmap    network scan
  # msedit    Microsoft Edit (provides `edit`)   openbsd-netcat  nc provider
  # github-cli gh           ruby  official ruby + gem
  EXTRAS=(starship eza zoxide tmux btop nmap msedit openbsd-netcat github-cli ruby)
  if [[ "$INSTALL_RUST" == "1" ]]; then
    EXTRAS+=(rust)   # full toolchain, ~300MB — set INSTALL_RUST=0 to skip
  fi
  $SUDO pacman -S --needed --noconfirm "${EXTRAS[@]}"
fi

# ── 3. shell quality-of-life ─────────────────────────────────────────────────
log "Configuring shell defaults..."
PROFILE="$HOME/.bashrc"
touch "$PROFILE"
# Back up the original .bashrc once, before we ever touch it.
[[ -f "$PROFILE" && ! -f "$PROFILE.orig" ]] && cp "$PROFILE" "$PROFILE.orig"

# Everything we manage lives in ONE guarded block. Writing it once (instead of
# appending line-by-line on every run) is what prevents duplicated PATH/alias
# lines. PATH entries dedupe themselves at runtime via the case-glob guards.
if ! grep -q '# >>> wsl-arch-bootstrap >>>' "$PROFILE"; then
  {
    printf '\n# >>> wsl-arch-bootstrap >>>\n'
    printf 'export EDITOR=%s\n' "$DEFAULT_EDITOR"
    printf 'export VISUAL=%s\n' "$DEFAULT_EDITOR"
    cat <<'EOF'
# --- PATH (self-deduping) ---
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
# user-installed ruby gems
for _d in "$HOME"/.local/share/gem/ruby/*/bin; do
  [ -d "$_d" ] && case ":$PATH:" in *":$_d:"*) ;; *) PATH="$_d:$PATH" ;; esac
done; export PATH; unset _d

# --- history ---
export HISTSIZE=100000 HISTFILESIZE=200000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT='%F %T '
shopt -s histappend checkwinsize
PROMPT_COMMAND="history -a; ${PROMPT_COMMAND:-}"

# --- aliases ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -alh --group-directories-first --git'
  alias la='eza -a --group-directories-first'
else
  alias ll='ls -alh --color=auto'
fi
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'
# IS_SANDBOX=1 lets --dangerously-skip-permissions run as root (disposable WSL
# sandbox); without it Claude Code refuses for security reasons.
alias claude-yolo='IS_SANDBOX=1 claude --dangerously-skip-permissions'

# --- tool init ---
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
command -v zoxide   >/dev/null 2>&1 && eval "$(zoxide init bash)"
[ -f /usr/share/fzf/key-bindings.bash ] && . /usr/share/fzf/key-bindings.bash
[ -f /usr/share/fzf/completion.bash ]   && . /usr/share/fzf/completion.bash
# <<< wsl-arch-bootstrap <<<
EOF
  } >> "$PROFILE"
fi

# Ensure login shells (WSL default) actually source .bashrc.
BP="$HOME/.bash_profile"
if [[ ! -f "$BP" ]] || ! grep -q 'bashrc' "$BP"; then
  printf '%s\n' '[ -f ~/.bashrc ] && . ~/.bashrc' >> "$BP"
fi

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
  # Future shells get ~/.local/bin via the guarded block in section 3;
  # just make claude reachable for the rest of THIS script run.
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
