# wsl-arch-bootstrap

A tiny, reusable kit to take a **fresh Arch-on-WSL** instance to a working
Claude Code dev box in one command.

## Files
| File | Purpose |
|------|---------|
| `bootstrap.sh` | Idempotent provisioning: pacman sync/upgrade, core tools, Node, Claude Code, shell + git config. Run this first. |
| `CLAUDE.md` | Dropped into `~/.claude/` so the in-WSL Claude knows the environment, constraints, and your preferences. |
| `kickoff-prompt.md` | Paste into a `claude` session to have the agent finish the "nice setup". |

## Quick start (inside the Arch WSL distro, as root)

```bash
# get the kit into WSL (pick one):
#   git clone <your-repo> wsl-arch-bootstrap   # if you push this to git
#   or copy the folder in via /mnt/c/... once, then work from $HOME

cd wsl-arch-bootstrap
bash bootstrap.sh
source ~/.bashrc
claude                       # sign in on first run
# then paste the contents of kickoff-prompt.md into the session
```

## Re-provisioning a brand-new distro from Windows (optional)

If you want to nuke and recreate the *whole distro* from PowerShell on the host:

```powershell
# list distros
wsl --list --verbose

# export a known-good snapshot once (backup)
wsl --export archlinux C:\wsl\arch-backup.tar

# later: wipe and restore
wsl --unregister archlinux
wsl --import archlinux C:\wsl\arch C:\wsl\arch-backup.tar
wsl -d archlinux
```

Then re-run `bootstrap.sh` inside the fresh distro. Because every step is
idempotent, running it on a restored snapshot is harmless too.

## Customizing

`bootstrap.sh` reads a few env vars:

```bash
GIT_NAME="Your Name" GIT_EMAIL="you@example.com" \
  EDITOR_PKG=neovim DEFAULT_EDITOR=nvim \
  bash bootstrap.sh

SKIP_CLAUDE=1 bash bootstrap.sh   # provision everything except Claude Code
```
