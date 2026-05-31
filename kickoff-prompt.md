You're running inside a fresh Arch Linux WSL2 instance (root mode, disposable
sandbox — see ~/.claude/CLAUDE.md). The base bootstrap script has already run:
system is updated, and git, nodejs/npm, ripgrep/fd/bat/fzf/jq, vim, and Claude
Code itself are installed.

I want you to finish turning this into a comfortable dev environment. Work in
small, explained steps and confirm before anything destructive. Specifically:

1. Audit what's installed and report the state (kernel, pacman mirror health,
   node/npm versions, disk usage).
2. Set up a clean, fast shell prompt and history (bash is fine; don't switch me
   to zsh unless you ask first). Sensible aliases, good history settings.
3. Configure git sensibly (it's already got my name/email — verify, then add
   useful defaults: better diffs, aliases, credential caching for WSL).
4. Make sure `claude` and any user-installed binaries are reliably on PATH for
   new shells.
5. Install a small, tasteful set of dev conveniences you'd recommend for this
   kind of sandbox — ask me before adding anything large.
6. Generate an SSH key for me if one doesn't exist, and print the public key so
   I can add it to GitHub.
7. At the end, write a short ~/SETUP-NOTES.md summarizing what you changed and
   how to redo or undo it.

Constraints: stay inside the WSL filesystem, never touch /mnt/c, keep everything
idempotent, and tell me the one-line command to re-run if I rebuild this box.
