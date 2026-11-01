# Rice

Ansible setup for crlxs' Debian desktop: dwm, dmenu, st, Zsh, Neovim, fonts, and bare-repository dotfiles. Requires Debian 12+, x86_64 or ARM64, internet, and sudo access. Run as your desktop user **without sudo**; Ansible elevates only for packages and the login shell. No Galaxy collections are needed.

## Install

Clone over HTTPS before any SSH key is restored:

```sh
sudo apt update
sudo apt install -y ansible-core git ca-certificates
mkdir -p ~/.local/src ~/.local/share
git clone https://github.com/crlxs/rice.git ~/.local/src/rice
cd ~/.local/src/rice
ansible-playbook -i localhost, setup.yaml --ask-become-pass
```

Skip the clone if `~/.local/src/rice` already exists. The default run installs the shell and desktop **without restoring an SSH key**. To restore the vaulted key on the first run, replace the last command above with:

```sh
ansible-playbook -i localhost, setup.yaml --tags common,suckless,gitssh --ask-become-pass --ask-vault-pass
```

Other runs from the rice checkout:

| Scope | Command |
| --- | --- |
| Shell, dotfiles, Neovim, fonts | `ansible-playbook -i localhost, setup.yaml --tags common --ask-become-pass` |
| Desktop and prerequisites, including fonts | `ansible-playbook -i localhost, setup.yaml --tags suckless --ask-become-pass` |
| Fonts only | `ansible-playbook -i localhost, setup.yaml --tags fonts --ask-become-pass` |
| Restore vaulted SSH key later | `ansible-playbook -i localhost, setup.yaml --tags gitssh --ask-become-pass --ask-vault-pass` |

The `gitssh` task needs the existing vault password, backs up any existing key, and sets rice's SSH **push** URL while retaining HTTPS fetches. Its public key must already be authorized on GitHub; the first push may ask you to verify GitHub's host key. Installation never pushes or grants inbound SSH access. All installation clones use HTTPS.

## Start the desktop

Log out and back in to load Zsh and its `XINITRC` setting. At a local text console, run `startx`. If you installed only the desktop or have not loaded the shell environment, run `startx "$HOME/.config/x11/xinitrc"`. X does not start automatically at login.

The session puts `~/.local/bin` on PATH and starts dwm, picom, a clock/status loop, and the bundled jaguar wallpaper. Picom uses XRender (no OpenGL/3D required) and logs to `~/.cache/picom.log`. Set machine-specific mouse IDs in `~/.config/x11/xprofile`; none are hardcoded. If X reports `failed to exec dwm` after an older installation, rerun the desktop task: older versions installed the binaries in root's home. The current task verifies all three executables in `~/.local/bin`.

## Files, reruns, and Neovim

Initial dotfile conflicts go to private `~/.local/state/rice/backups/<timestamp>/` directories; review backups before restoring them. Tracked local edits, Bash configuration and history, credentials, and unmanaged files are preserved. Checkout stops at file or symlink parent directories instead of writing through them. Desktop copies `xinitrc` and `xprofile` with adjacent backups, replaces compton with picom, and installs the bundled `files/wallpapers/jaguar.jpg` as `~/.local/share/wallpaper` with a backup if needed and no extra download. The installer manages `~/.local/bin/nvim`.

Existing Git clones are never updated or reset; review edits, fetch and choose a revision yourself, then rerun. Fresh clones use each upstream default revision, not pinned commits. The suckless forks (`crlxs/st`, `crlxs/dwm`, `crlxs/dmenu`) preserve their patches, bindings, and local `config.h`. Desktop runs build and install as your user with `PREFIX=$HOME/.local`, install st terminfo under `~/.local/share/terminfo`, and report changes on every install.

Neovim is pinned in `vars/main.yaml`, downloaded with SHA256 verification, and extracted without FUSE. The playbook checks out `init.lua`, restores plugins from the dotfiles lockfile, and verifies the Kanagawa theme and Neo-tree; plugin restoration needs network access. Zsh plugins may download on first shell startup. If an older dotfiles revision makes `:Lazy` unavailable, run `unset VIMINIT` in that session and update dotfiles: the old `VIMINIT` export made Neovim skip `init.lua`. Packages refresh the apt cache; the playbook does not upgrade the OS.

## Layout and migration

| Path | Purpose |
| --- | --- |
| `~/.config` | Configuration; dotfiles README at `.config/dotfiles/README.md`, Git ignores at `.config/git/ignore` |
| `~/.local/share` | Data and bare Git metadata at `.local/share/dotfiles`; home is its work tree |
| `~/.local/state` | Persistent Zsh, less, and Vim history; rice backups |
| `~/.cache` | Disposable caches, including Zsh completion and Ansible temporary files |
| `~/.local/src/rice` | Installer checkout |

`~/.zshenv` bootstraps XDG and tool settings before login or interactive startup; `~/.vimrc` loads fallback Vim settings without overriding Neovim. The repository's `ansible.cfg` keeps first-run temporary files out of `~/.ansible`. Run Ansible from the rice checkout.

For a legacy install, update rice and dotfiles first, then run the `common` tasks. Migration moves `~/.dotfiles` without changing its index or Git config, relocates known histories and caches, and backs up conflicts without losing either copy. It never overwrites an existing repository destination or moves the running installer. After a run from legacy `~/rice`, relocate that checkout separately:

```sh
cd "$HOME"
python3 "$HOME/rice/files/migrate_home.py" "$HOME" --installer-only
cd "$HOME/.local/src/rice"
```

Only recognized managed startup links and redundant files are archived. A clean `~/dotfiles` duplicate is archived only if its commit belongs to the canonical history; `~/jaguar.jpg` only if it matches the installed wallpaper. Recognized root-level documentation and ignore files are migrated; personal versions remain. Existing X authentication paths remain; new ones use `$XDG_RUNTIME_DIR` when available or `~/.local/state/x11` otherwise. Close old shells and log back in after migration so they stop using legacy history paths.

## Appearance

Fork defaults live in tracked `config.def.h`; this playbook does not overwrite `config.h`. Fresh clones use Noto Sans Mono, 6-pixel terminal padding, muted Kanagawa Dragon terminal colors, gray dwm/dmenu selections and borders, and dwm's 80% focused / 50% inactive opacity and translucent bar. Picom handles window transparency; the Neovim theme is unchanged.

The `common` and `suckless` tags install Noto Sans Mono, Noto Color Emoji, checksum-verified Nerd Font Symbols v3.4.0, and separate fontconfig fallbacks. Symbols supply Neovim icons without replacing the text font. After font installation, restart the terminal and Neovim; complex emoji still depend on terminal rendering. New st/dmenu processes use rebuilt settings immediately. To reload dwm, save your work, exit with Super + Shift + q, and restart X.

Publish `config.def.h` changes in each fork and installer changes in rice for other machines to receive them. After manually updating a fork, review and back up local `config.h` before removing it to regenerate from `config.def.h`.

## Validate and publish

```sh
ansible-playbook -i localhost, setup.yaml --syntax-check
ansible-playbook -i localhost, setup.yaml --list-tasks
python3 -m unittest discover -s tests -v
```

Edit packages and the Neovim version in `vars/main.yaml`. Check mode previews parts of an existing install; it cannot fully simulate fresh clones, dotfile checkout, archive extraction, or compilation. A real fresh install is the final integration test.

| Repository | Location | Owns |
| --- | --- | --- |
| [rice](https://github.com/crlxs/rice) | `~/.local/src/rice` | Ansible, packages, fonts, X templates, wallpaper |
| [dotfiles](https://github.com/crlxs/dotfiles) | bare `~/.local/share/dotfiles` | Shell, Neovim, tmux, X files, wallpaper |
| [st](https://github.com/crlxs/st) | `~/.local/src/st` | Terminal |
| [dwm](https://github.com/crlxs/dwm) | `~/.local/src/dwm` | Window manager |
| [dmenu](https://github.com/crlxs/dmenu) | `~/.local/src/dmenu` | Launcher |

Commit source and defaults, then authenticate and push each changed repository; binaries, objects, local `config.h`, and backups are ignored. Keep X startup and wallpaper copies in rice and dotfiles aligned: desktop runs install rice's versions. From standard paths:

```sh
git -C "$HOME/.local/src/st" push origin HEAD
git -C "$HOME/.local/src/dwm" push origin HEAD
git -C "$HOME/.local/src/dmenu" push origin HEAD
git --git-dir="$HOME/.local/share/dotfiles" --work-tree="$HOME" push origin HEAD
git -C "$HOME/.local/src/rice" push origin HEAD
```

Only published commits reach new machines. Existing clones require manual updates; after updating a fork, refresh local `config.h` as needed and rerun its playbook tags.

## Shortcuts

MODKEY is the Windows key; the forks define the authoritative bindings.

| Action | Shortcut |
| --- | --- |
| Terminal | MODKEY + Shift + Enter |
| dmenu | MODKEY + p |
| Close window | MODKEY + Shift + c |
| Tile / floating / monocle | MODKEY + t / f / m |
| Terminal zoom | Control + Shift + PgUp / PgDown |

![Desktop](img/desktop.jpg)
