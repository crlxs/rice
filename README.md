# Rice

Ansible installation of crlxs' Debian desktop: dwm, dmenu, st, Zsh,
Neovim and a bare Git repository for dotfiles. Supports Debian 12 or newer
on x86_64 and ARM64. Run as the desktop user, **without sudo**; Ansible
requests sudo only for system packages and shell selection.
A working internet connection and sudo access are required.

## Install

On a fresh machine, install Ansible and clone this repository over HTTPS so
the installer is available before any SSH key is restored:

```sh
sudo apt update
sudo apt install -y ansible-core git ca-certificates
mkdir -p ~/.local/src ~/.local/share
git clone https://github.com/crlxs/rice.git ~/.local/src/rice
cd ~/.local/src/rice
ansible-playbook -i localhost, setup.yaml --ask-become-pass
```

**The default first run does not set up an SSH key.** To restore the vaulted
key during the first run, replace the final `ansible-playbook` command above
with this one and enter the vault password when prompted:

```sh
ansible-playbook -i localhost, setup.yaml --tags common,suckless,gitssh --ask-become-pass --ask-vault-pass
```

If you already have `~/.local/src/rice`, skip the clone. No Galaxy collections are required.
The default run installs both the shell environment and desktop. Neither run
grants inbound SSH access.

For shell and dotfiles only:

```sh
ansible-playbook -i localhost, setup.yaml --tags common --ask-become-pass
```

For desktop tools only (including their own prerequisites):

```sh
ansible-playbook -i localhost, setup.yaml --tags suckless --ask-become-pass
```

Optionally restore the repository's vaulted SSH identity (backing up any
existing key); supply its existing vault password. This also configures SSH
pushes for the rice repository while keeping its HTTPS fetch URL:

```sh
ansible-playbook -i localhost, setup.yaml --tags gitssh --ask-become-pass --ask-vault-pass
```

SSH pushes require that the public key is authorized on your GitHub account.
The first push may ask you to verify GitHub's host key. Installation uses HTTPS
and never pushes changes to GitHub.

## Start the desktop

Log out and log back in after installation so Zsh and its environment are active.
From a local text console, run:

```sh
startx
```

The dotfiles Zsh bootstrap exports `XINITRC=$HOME/.config/x11/xinitrc`, so plain
`startx` selects this session. If you have installed only the desktop tasks or
have not loaded the shell environment, use `startx "$HOME/.config/x11/xinitrc"`.

The session adds `~/.local/bin` to PATH and starts dwm, picom, a clock/status
loop, and the bundled jaguar wallpaper. Picom uses the XRender backend, which
does not require OpenGL/3D acceleration. Its output goes to `~/.cache/picom.log`.
It does not automatically launch X at login. Mouse device IDs are deliberately
not hardcoded; add machine-specific settings to `~/.config/x11/xprofile`.
Desktop-only installation supports the same explicit start command.

## Existing files and reruns

Initial dotfile conflicts are moved into `~/.local/state/rice/backups/<timestamp>/`
before checkout. No Bash configuration or history is deleted. Already tracked
local dotfile edits are preserved. A symlink or file used as a parent directory
causes checkout to stop with an explanation rather than writing through it.
Restore individual backups manually after reviewing the installed configuration.

The desktop task manages `~/.config/x11/xinitrc` and `xprofile` and backs up
previous versions beside them. It switches the compositor from compton to picom.
It also installs `files/wallpapers/jaguar.jpg` as `~/.local/share/wallpaper`,
backing up a previous wallpaper when replaced. The image is bundled in this
repository so new machines receive the same default without a separate download.
The Neovim launcher at `~/.local/bin/nvim` is managed by this installer.

Existing Git clones are not automatically updated or reset. To update them,
review local changes, fetch and select the desired revision manually, then
rerun the playbook. New clones use the upstream default revision at clone time;
their exact commits are not locked by this repository. Suckless tools rebuild
and install as your user with an explicit `PREFIX=$HOME/.local` on every desktop
run. The sources are your `crlxs/dwm`, `crlxs/dmenu`, and `crlxs/st` forks;
their patches, bindings and nonappearance settings are preserved. The `st` terminfo
entry is installed under `~/.local/share/terminfo`. Installation
therefore reports changes even when the sources have not changed.

If an earlier run succeeded but X reports `failed to exec dwm`, rerun the
desktop installation command above. Earlier versions ran `make install` as
root while the forks used `PREFIX = ~/.local`, installing into root's home.
The corrected installer verifies that all three binaries exist and are executable
in your `~/.local/bin`.

Neovim is pinned in `vars/main.yaml` and downloaded with upstream SHA256
verification. Its tarball needs no FUSE. The playbook checks that it can start.
Plugin managers may download plugins on first shell/editor startup.
Package installation refreshes the apt cache but does not upgrade the whole OS.

## Home directory layout and migration

The default installation keeps configuration in `~/.config`, data in
`~/.local/share`, persistent state in `~/.local/state`, and disposable caches in
`~/.cache`. The installer checkout lives in `~/.local/src/rice`; bare dotfiles
metadata lives in `~/.local/share/dotfiles`. Your home remains the dotfiles work
tree. The small `~/.zshenv` bootstrap is the one required top-level shell file.
The dotfiles README is stored at `~/.config/dotfiles/README.md`; ignore rules
are stored at `~/.config/git/ignore`.

Zsh loads XDG and tool environment settings before interactive or login startup.
History is stored under `~/.local/state/zsh`; completion dumps under
`~/.cache/zsh`. less and fallback Vim history also use the state directory.
The repository's `ansible.cfg` keeps first-run temporary files out of
`~/.ansible`, even before dotfiles have been installed. Run Ansible from the
installer checkout as shown above.

For an older installation, update the installer and dotfiles revisions first,
then run the `common` tasks. The migration moves `~/.dotfiles` without changing
its index or local Git configuration, relocates known histories and completion
caches, and archives displaced files under
`~/.local/state/rice/backups/<timestamp>/`. Conflicting histories are retained
in backups; both old and new contents are preserved. Existing repository
destinations are never overwritten. Ansible never moves its own working
directory. After running from a legacy `~/rice` checkout, relocate it as a
separate command, then use the new path:

```sh
cd "$HOME"
python3 "$HOME/rice/files/migrate_home.py" "$HOME" --installer-only
cd "$HOME/.local/src/rice"
```

Only recognized managed startup links and redundant files are archived. Bash
fallback files, credentials, unmanaged application directories, and current X
authentication files are retained. A clean `~/dotfiles` duplicate is archived
only if its current commit is already part of the canonical repository history.
The original `~/jaguar.jpg` upload is archived only if it matches the installed
wallpaper. Backups are private and can be restored after review.

Close old shell sessions and log back in after migration so they stop using
legacy history paths. New X authentication files use `$XDG_RUNTIME_DIR` when
available and `~/.local/state/x11` otherwise. Inherited authentication paths
are preserved for existing sessions. Root-level documentation and ignore files
from this setup are migrated only when recognized; personal files are kept.

## Appearance

The forks own the appearance defaults in their tracked `config.def.h` files;
this playbook does not override `config.h`. Fresh clones use the improved Noto
Sans Mono typography, 6-pixel terminal padding, and muted Kanagawa Dragon
terminal colors. Dwm and dmenu use gray selections and gray window borders.
Dwm retains its original 80% focused / 50% inactive opacity and translucent bar;
picom applies window transparency. The existing Neovim theme is unchanged.

Change and push `config.def.h` in `crlxs/st`, `crlxs/dwm`, and `crlxs/dmenu` to
publish new defaults. Push the installer changes in `crlxs/rice` too. Until those
changes are pushed, another PC will still clone the old GitHub defaults.
The installer preserves existing clones and their local `config.h` settings.
After manually updating an existing fork, review and back up `config.h` before
removing it to let make regenerate it from `config.def.h`.

The font tasks run for both `common` and `suckless` installations. They install
Noto Sans Mono, Noto Color Emoji, and checksum-verified Nerd Font Symbols v3.4.0.
Nerd Font symbols supply Neovim file and status icons; they supplement the
normal text font. Fontconfig fallback settings are installed separately from
the forks' appearance defaults. To install or refresh fonts alone:

```sh
ansible-playbook -i localhost, setup.yaml --tags fonts --ask-become-pass
```

Start a new terminal and Neovim after font installation. Complex emoji sequences
still depend on terminal rendering support. New st and dmenu processes use
rebuilt settings immediately. To load dwm changes, save your work, exit with
Super + Shift + q, then start X again.

## Validate and customize

```sh
ansible-playbook -i localhost, setup.yaml --syntax-check
ansible-playbook -i localhost, setup.yaml --list-tasks
python3 -m unittest discover -s tests -v
```

Edit package lists and Neovim version in `vars/main.yaml`. Check mode can preview
parts of an existing installation, but cannot fully simulate cloning, dotfile
checkout, archive extraction or compilation on a fresh machine. A real fresh
installation is the final integration test.

## Repositories and publishing changes

| Repository | Local checkout | Owns |
| --- | --- | --- |
| [rice](https://github.com/crlxs/rice) | `~/.local/src/rice` | Ansible, dependencies, font setup, X startup templates, jaguar wallpaper |
| [dotfiles](https://github.com/crlxs/dotfiles) | `~/.local/share/dotfiles` (bare; home is its work tree) | Shell, Neovim, tmux, X session files and wallpaper |
| [st](https://github.com/crlxs/st) | `~/.local/src/st` | Terminal patches and appearance defaults |
| [dwm](https://github.com/crlxs/dwm) | `~/.local/src/dwm` | Layouts, shortcuts, window appearance and opacity |
| [dmenu](https://github.com/crlxs/dmenu) | `~/.local/src/dmenu` | Launcher patches and appearance defaults |

The fork defaults live in `config.def.h`; local builds generate `config.h`.
Commit defaults and source files. Binaries, object files, local `config.h`, and
configuration backups are ignored. When changing X startup or wallpaper, keep
the copies in `rice/files/` and the dotfiles work tree aligned: desktop runs
install the versions bundled in rice.

After reviewing and committing changes, publish every changed repository.
From the standard installation paths:

```sh
git -C "$HOME/.local/src/st" push origin HEAD
git -C "$HOME/.local/src/dwm" push origin HEAD
git -C "$HOME/.local/src/dmenu" push origin HEAD
git --git-dir="$HOME/.local/share/dotfiles" --work-tree="$HOME" push origin HEAD
git -C "$HOME/.local/src/rice" push origin HEAD
```

Commit and push are separate steps. A new PC receives only commits published to
GitHub. Installation always clones using HTTPS; pushing requires authentication.
Existing installations preserve clones rather than automatically pulling updates.
After reviewing local changes, update the desired repositories manually, refresh
local `config.h` where needed, and rerun the relevant playbook tags.

## Shortcuts

MODKEY is the Windows key. Your forks define the authoritative bindings.

- Terminal: MODKEY + Shift + Enter
- dmenu: MODKEY + p
- Close window: MODKEY + Shift + c
- Exit dwm: MODKEY + Shift + q
- Tile / floating / monocle: MODKEY + t / f / m
- Terminal zoom: Control + Shift + PgUp / PgDown

![Desktop](img/desktop.jpg)
