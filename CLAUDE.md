# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal Arch Linux dotfiles. The desktop is **Hyprland + Waybar + Fish + Kitty**. The repo is deployed to `~/Documents/config` and the configs are symlinked into `~/.config` by an Ansible playbook.

The README is in Russian; comments throughout the codebase are mostly Russian as well. Keep that style when editing existing files.

## Deployment / how this repo is "installed"

Configs are not copied — Ansible creates symlinks from this repo into `~/.config`. The mapping lives in `ansible/roles/dotfiles/vars/main.yml` (`dotfiles_links`). When adding a new top-level config directory (e.g. `foo/`), add a corresponding entry there or it will not be picked up.

```bash
./run_ansible.sh --ask-vault-pass            # full provision from repo root
cd ansible && ansible-playbook playbooks/main.yml --ask-vault-pass --check --diff   # dry run
cd ansible && ansible-playbook playbooks/main.yml --ask-vault-pass --tags packages  # one role
```

`ansible-playbook` **must be run from the `ansible/` directory**, otherwise role lookup fails. The wrapper script does the `cd` for you.

Roles (in order, all in `ansible/roles/`):
- `packages` — installs pacman + AUR (yay) packages from `roles/packages/vars/main.yml` and `group_vars/all/main.yml` (`system_packages`, `aur_packages`).
- `system` — system-wide configs (SDDM, services, timers).
- `user` — user shell (Fish), Python venv at `~/.python_venv`, SSH.
- `dotfiles` — creates symlinks listed above; also installs the `check-mail.timer` user-systemd unit and copies `scripts/check_mail.py` to `~/.local/bin`.

Secrets (Bitwarden master pass, `ansible_become_pass`, OpenWeatherMap key, etc.) live in `ansible/group_vars/all/vault.yml`. Edit with `ansible-vault edit ansible/group_vars/all/vault.yml`. Because `ansible_become_pass` is in the vault, `-K` is *not* needed.

## Commit checks

`.pre-commit-config.yaml` runs:
- standard hygiene hooks (trailing whitespace, EOF, YAML, JSON)
- `shellcheck` (excludes `*.fish`)
- `python3 scripts/generate_docs.py` whenever `hypr/*.conf` or `ansible/roles/packages/vars/main.yml` change — this regenerates the `### ⌨️ Hotkeys` and packages sections of `README.md` in place. Don't hand-edit those sections; edit the source config and let the hook rewrite them.

## Architecture / what lives where

This is a multi-language repo glued together by Hyprland's `exec-once` lines and Waybar's custom modules. The interesting integrations:

**`hypr/`** — Hyprland config (`hyprland.conf`, `keyboard.conf`, `monitors.conf`, `workspaces.conf`, `hypridle.conf`, `hyprlock.conf`, `hyprpaper.conf`).
- `hypr/scripts/autoname.py` — runs as `exec-once`, listens on the Hyprland IPC socket and rewrites workspace names with Nerd Font icons based on the focused client class. Add new app classes to the `ICONS` dict.
- `hypr/pyprland.toml` — scratchpads (`term`, `volume`, `calc`) toggled with `SUPER+SHIFT+{P,V,C}`.
- Wallpaper daemon is **awww** (not hyprpaper) — see `exec = awww img …`.

**`waybar/`** — Waybar config + custom modules.
- `config.jsonc` wires custom modules: `custom/updates`, `custom/mail`, `custom/weather`, `custom/pension`, `custom/gammastep`, plus `hyprland/language`.
- **Active exec sources are Python/shell, not Rust.** `custom/mail` execs `scripts/check_mail.py`, `custom/pension` execs `scripts/swedbank_pension.py`, `custom/gammastep` execs `waybar/gammastep_status.sh`. `custom/weather` and `custom/updates` just `cat /tmp/weather.json` / `/tmp/updates.json`, which are written out-of-band by `scripts/check_weather.py` and `scripts/check_updates.sh` (the latter via the `check-mail`/update timers).
- `waybar/weather-rs/` and `waybar/mail-rs/` are older Rust reimplementations of the weather/mail modules. They are **not currently referenced** by `config.jsonc` — treat them as legacy unless you re-wire a module to them. Compiled binaries are gitignored (`cargo build --release` inside each crate, source in `waybar/weather-rs/src/`).
- `waybar/launch.sh` does `pkill waybar; sleep; waybar &` — call this after editing `style.css` or `config.jsonc`.

**`hyprland-status/`** — Standalone GTK4/libadwaita Python widget (`main.py`) showing battery / layout / time / pending updates. Triggered by `SUPER+SHIFT+T` (`$runprog`). Reads `/tmp/pending_updates`. Has its own `style.css`.

**`scripts/`** — One-shot Python/Fish/Bash utilities. Notable:
- `bitwarden-extract-ssh.fish` — pulls SSH/GPG/pass secrets out of Bitwarden during bootstrap (called from `playbooks/main.yml` pre-tasks).
- `check-mail.{service,timer}` — user-systemd units installed by the `dotfiles` role; they run `~/.local/bin/check_mail.py`.
- `swedbank_pension.py` (+ `update_sefon.py`, `punto.py`) — personal scrapers, not part of the desktop.
- `generate_docs.py` — pre-commit hook target, see above.
- `wait-for-net.sh` — used as `$waitnet` in `hyprland.conf` to gate `exec-once` lines that need network.

**`fish/`** — Fish shell config. `config.fish` enables `fish_vi_key_bindings`, sets `EDITOR=nvim`, auto-activates `~/.python_venv`, and defines aliases (`v`=nvim, `u`=`yay -Syu`, `fc`/`hc` to edit configs, `bwl` to unlock Bitwarden, …). `gemini_w_key` pulls `GEMINI_API_KEY` from `pass`. Plugins are managed via Fisher (`fish_plugins`).

**`nvim/`** — LazyVim distribution; plugin specs in `lua/plugins/` (e.g. `qml.lua`, `rust.lua`, `gemini-companion.lua`). `lazy-lock.json` is gitignored.

**`aerc/`** — Terminal mail client config (`accounts.conf`, `aerc.conf`, `binds.conf`), symlinked into `~/.config/aerc`. Launched via `scripts/launch-aerc.sh`. The Waybar `custom/mail` module (`scripts/check_mail.py`) reads the same mailbox over IMAP. `fetch_emails.py` is a related standalone IMAP fetcher.

**`Themes/wallpapers/`** — Wallpapers. `Themes/` is symlinked to `~/Documents/Themes` for compatibility.

**Submodule:** `gemini-extensions/gemini-cli-prompt-library` — remember `git submodule update --init --recursive` after a fresh clone.

## Conventions

- File comments and commit messages are mixed Russian/English; match the surrounding file.
- Hardcoded user paths (`/home/napalm/...`) appear in some scripts — when adding a new one, prefer `$HOME` / `~` so it stays portable, since the repo is meant to be reusable per the README.
- The repo lives at `~/Documents/config`; some `exec` lines in `hypr/hyprland.conf` reference this absolute path.
- Don't commit compiled artifacts (`waybar/*-rs/<binary>`, `lazy-lock.json`, `numetal_sefon.m3u`, `scripts/sefon_update.log`, `fish_variables`, `skeys.fish`) — already in `.gitignore`.
