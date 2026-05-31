# wsl-arch-bootstrap

A tiny, reusable kit to take a **fresh Arch-on-WSL** instance to a working
Claude Code dev box in one command.

## Files
| File | Purpose |
|------|---------|
| `bootstrap.sh` | Idempotent provisioning: pacman sync/upgrade, core tools, Node, Claude Code, shell + git config. Run this first. |
| `CLAUDE.md` | Dropped into `~/.claude/` so the in-WSL Claude knows the environment, constraints, and your preferences. |
| `kickoff-prompt.md` | Paste into a `claude` session to have the agent finish the "nice setup". |
| `snapshot.ps1` | Windows-host PowerShell: export the provisioned distro to a timestamped `.tar`. |
| `restore.ps1` | Windows-host PowerShell: recreate a distro from a snapshot (`-Force` to replace an existing one). |

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

## Snapshot & restore from Windows (the warm-start path)

The script is the source of truth; a snapshot is just a warm cache so you don't
recompile rust/etc. every time. Workflow:

```powershell
# 1. once the box is dialed in, snapshot it (timestamped .tar in C:\wsl\snapshots)
.\snapshot.ps1

# 2. later, spin up a fresh copy from that snapshot
.\restore.ps1 -Tar C:\wsl\snapshots\archlinux-YYYYMMDD-HHMMSS.tar

# replace the live distro in place (DESTRUCTIVE — unregisters it first):
.\restore.ps1 -Tar ...\archlinux-....tar -Force

# or restore alongside under a different name (safe, no -Force needed):
.\restore.ps1 -Tar ...\archlinux-....tar -Distro arch-test -InstallDir C:\wsl\arch-test
```

Both scripts take `-Distro` (default `archlinux`) — check yours with
`wsl --list --verbose` if the name differs. Running PowerShell as admin isn't
required for import/export.

If a snapshot ever feels stale, `git pull` the kit inside the restored distro
and re-run `bootstrap.sh` over it (idempotent), then `snapshot.ps1` again.

### Raw commands (no scripts)

```powershell
wsl --export archlinux C:\wsl\arch-backup.tar
wsl --shutdown; wsl --unregister archlinux
wsl --import archlinux C:\wsl\arch C:\wsl\arch-backup.tar
wsl -d archlinux
```

## Customizing

`bootstrap.sh` reads a few env vars:

```bash
GIT_NAME="Your Name" GIT_EMAIL="you@example.com" \
  EDITOR_PKG=neovim DEFAULT_EDITOR=nvim \
  bash bootstrap.sh

SKIP_CLAUDE=1 bash bootstrap.sh   # provision everything except Claude Code
```
