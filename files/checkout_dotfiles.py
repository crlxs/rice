#!/usr/bin/env python3
"""Back up untracked checkout conflicts; preserve already tracked local changes."""
import datetime
import os
from pathlib import Path
import subprocess
import sys


def checkout(home):
    home = Path(home).resolve()
    repo = home / '.dotfiles'
    prefix = ['git', f'--git-dir={repo}', f'--work-tree={home}']

    def git(*args):
        return subprocess.check_output(prefix + list(args))

    paths = git('ls-tree', '-rz', '--name-only', 'HEAD').split(b'\0')
    indexed = set(git('ls-files', '-z').split(b'\0'))
    conflicts = []
    for raw in filter(None, paths):
        relative = Path(os.fsdecode(raw))
        if relative.is_absolute() or '..' in relative.parts or relative.parts[0] == '.dotfiles':
            raise RuntimeError(f'Unsafe dotfile path: {relative}')
        destination = home / relative
        # Do not follow directory symlinks out of the home tree during checkout.
        for parent in destination.parents:
            if parent == home:
                break
            if parent.is_symlink() or (parent.exists() and not parent.is_dir()):
                raise RuntimeError(f'Checkout parent must be a real directory: {parent}')
        if raw not in indexed and os.path.lexists(destination):
            conflicts.append(relative)
    if conflicts:
        stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
        backup = home / '.local/state/rice/backups' / stamp
        backup.mkdir(parents=True, mode=0o700)
        for relative in conflicts:
            target = backup / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            (home / relative).rename(target)
        print(f'CHANGED: Backed up {len(conflicts)} conflicting paths to {backup}')
    before = git('ls-files', '-z')
    missing = any(not os.path.lexists(home / os.fsdecode(p)) for p in paths if p)
    subprocess.run(prefix + ['checkout'], check=True)
    if before != git('ls-files', '-z') or missing:
        print('CHANGED: Checked out dotfiles')


if __name__ == '__main__':
    checkout(sys.argv[1])
