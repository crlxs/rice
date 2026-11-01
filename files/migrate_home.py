#!/usr/bin/env python3
"""Relocate known legacy paths; retain displaced files in private backups."""
import argparse
import datetime
import os
from pathlib import Path
import subprocess


class Migration:
    def __init__(self, home):
        self.home = Path(home).resolve()
        self.backup = None

    def path(self, relative):
        path = self.home / relative
        if not path.is_relative_to(self.home) or '..' in path.parts:
            raise RuntimeError(f'Unsafe migration path: {relative}')
        for parent in path.parents:
            if parent == self.home:
                break
            if parent.is_symlink() or (parent.exists() and not parent.is_dir()):
                raise RuntimeError(f'Migration parent must be a real directory: {parent}')
        return path

    def directory(self, relative):
        path = self.path(relative)
        if path.is_symlink():
            raise RuntimeError(f'Migration directory must not be a symlink: {path}')
        path.mkdir(parents=True, exist_ok=True, mode=0o700)
        return path

    def archive(self, relative):
        source = self.path(relative)
        if not os.path.lexists(source):
            return
        if self.backup is None:
            stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
            self.backup = self.directory(f'.local/state/rice/backups/{stamp}')
        target = self.backup / relative
        target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        source.rename(target)
        print(f'CHANGED: Backed up {source} to {target}')

    def move(self, old, new, conflict='backup'):
        source, target = self.path(old), self.path(new)
        if not os.path.lexists(source):
            return
        if os.path.lexists(target):
            if conflict == 'fail':
                raise RuntimeError(f'Both {source} and {target} exist; reconcile them before migration.')
            self.archive(old)
            return
        self.directory(str(target.parent.relative_to(self.home)))
        source.rename(target)
        print(f'CHANGED: Moved {source} to {target}')

    def repository(self):
        old = self.path('.dotfiles')
        if not os.path.lexists(old):
            return
        if old.is_symlink():
            raise RuntimeError('Refusing to relocate a symlinked .dotfiles repository.')
        bare = subprocess.check_output(['git', f'--git-dir={old}', 'rev-parse', '--is-bare-repository'], text=True).strip()
        if bare != 'true':
            raise RuntimeError('Expected .dotfiles to be a bare Git repository.')
        updated = subprocess.run(['git', f'--git-dir={old}', 'cat-file', '-e', 'HEAD:.zshenv'], capture_output=True).returncode == 0
        if not self.path('.zshenv').is_file() and not updated:
            raise RuntimeError('Update the dotfiles revision to the XDG layout before relocating .dotfiles; the new .zshenv bootstrap is required.')
        self.move('.dotfiles', '.local/share/dotfiles', conflict='fail')

    def managed_files(self):
        # Keep shell startup operational when old dotfiles have not been updated.
        if not self.path('.zshenv').is_file():
            print('Update the dotfiles checkout to the XDG layout before migrating legacy files.')
            return
        for relative in ('.local/state/zsh', '.local/state/less', '.local/state/vim',
                         '.cache/zsh', '.cache/ansible', '.local/share/ansible'):
            self.directory(relative)
        for old, new in [('.cache/zsh/history', '.local/state/zsh/history'),
                         ('.lesshst', '.local/state/less/history'),
                         ('.viminfo', '.local/state/vim/viminfo')]:
            self.move(old, new)
        for old in sorted(self.directory('.config/zsh').glob('.zcompdump*')):
            if old.is_file() and not old.is_symlink():
                self.move(str(old.relative_to(self.home)), '.cache/zsh/' + old.name.lstrip('.'))
        self.archive('.config/zsh/.zshrc.bak')
        # These are superseded caches, retained privately rather than deleted.
        self.archive('.ansible')
        if (self.path('.config/nvm') / 'nvm.sh').is_file():
            self.move('.config/nvm', '.local/share/nvm', conflict='fail')
        for name, target in [('.zprofile', '.config/shell/profile'), ('.xprofile', '.config/x11/xprofile')]:
            path = self.path(name)
            if path.is_symlink() and os.readlink(path) == target:
                self.archive(name)
        readme = self.path('README.md')
        if (readme.is_file() and not readme.is_symlink()
                and self.path('.config/dotfiles/README.md').is_file()
                and readme.read_bytes().startswith(b'# Debian desktop dotfiles\n')):
            self.archive('README.md')
        old_ignores = ('/.config/zsh/.zcompdump*\n/.config/zsh/*.zwc\n/.config/zsh/*.bak\n'
                       '/.config/x11/*~\n/.local/share/wallpaper.*~\n')
        ignore = self.path('.gitignore')
        if (ignore.is_file() and not ignore.is_symlink()
                and self.path('.config/git/ignore').is_file()
                and ignore.read_bytes() == old_ignores.encode()):
            self.archive('.gitignore')
        upload, wallpaper = self.path('jaguar.jpg'), self.path('.local/share/wallpaper')
        if (upload.is_file() and not upload.is_symlink() and wallpaper.is_file()
                and upload.read_bytes() == wallpaper.read_bytes()):
            self.archive('jaguar.jpg')
        duplicate = self.path('dotfiles')
        canonical = self.path('.local/share/dotfiles')
        if (duplicate / '.git').is_dir() and canonical.is_dir():
            origin = subprocess.check_output(['git', '-C', str(duplicate), 'remote', 'get-url', 'origin'], text=True).strip()
            clean = not subprocess.check_output(['git', '-C', str(duplicate), 'status', '--porcelain'])
            head = subprocess.check_output(['git', '-C', str(duplicate), 'rev-parse', 'HEAD'], text=True).strip()
            known = subprocess.run(['git', f'--git-dir={canonical}', 'merge-base', '--is-ancestor', head, 'HEAD'], capture_output=True).returncode == 0
            if origin.removesuffix('.git') in ('https://github.com/crlxs/dotfiles', 'git@github.com:crlxs/dotfiles') and clean and known:
                self.archive('dotfiles')

    def installer(self):
        legacy = self.path('rice')
        if (legacy / '.git').is_dir():
            origin = subprocess.check_output(['git', '-C', str(legacy), 'remote', 'get-url', 'origin'], text=True).strip()
            if origin.removesuffix('.git') in ('https://github.com/crlxs/rice', 'git@github.com:crlxs/rice'):
                self.move('rice', '.local/src/rice', conflict='fail')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('home')
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument('--repository-only', action='store_true')
    modes.add_argument('--installer-only', action='store_true')
    args = parser.parse_args()
    migration = Migration(args.home)
    if args.installer_only:
        migration.installer()
    else:
        migration.repository()
        if not args.repository_only:
            migration.managed_files()
