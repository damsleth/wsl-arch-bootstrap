# Environment

This is **Arch Linux running under WSL2** on a Windows cloud PC. Treat it as a
disposable, root-mode dev sandbox — the *WSL distro* is expendable (yolo mode is
fine), but the **Windows host underneath is not throwaway**, so never touch the
host filesystem (`/mnt/c`) destructively.

## Operating assumptions
- You are running as **root**. `sudo` is unnecessary (and may be absent).
- Package manager is **pacman**. Use `pacman -S --needed --noconfirm <pkg>`.
- AUR is *not* set up by default. If something is AUR-only, install `yay` first
  (clone from aur.archlinux.org and `makepkg -si`) and say so before doing it.
- Network logins (OAuth) may need a URL copied to a browser on the Windows host.

## Preferences
- Editor: **vim** locally. Do not install `micro`.
- Keep changes idempotent and re-runnable; this box gets reprovisioned.
- Prefer modern CLI tools already installed: `rg`, `fd`, `bat`, `fzf`, `jq`.
- Explain pacman/system changes briefly before making them.

## Don'ts
- Don't modify Windows-side files under `/mnt/`.
- Don't create extra users unless asked — this is intentionally a root box.
- Don't add heavyweight desktop/GUI packages unless explicitly requested.
