import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('migration', Path(__file__).parents[1] / 'files/migrate_home.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class MigrationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / 'home'
        self.home.mkdir()
        self.migration = module.Migration(self.home)

    def write(self, path, content):
        target = self.home / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)
        return target

    def test_repository_moves_with_uncommitted_index_preserved(self):
        self.write('.zshenv', '# new bootstrap')
        repo = self.home / '.dotfiles'
        subprocess.run(['git', 'init', '--bare', str(repo)], check=True, capture_output=True)
        (repo / 'index').write_bytes(b'fixture index')
        self.migration.repository()
        self.assertFalse(repo.exists())
        self.assertEqual((self.home / '.local/share/dotfiles/index').read_bytes(), b'fixture index')
        self.migration.repository()

    def test_repository_conflict_keeps_both_copies(self):
        self.write('.zshenv', '# new bootstrap')
        repo = self.home / '.dotfiles'
        subprocess.run(['git', 'init', '--bare', str(repo)], check=True, capture_output=True)
        destination = self.home / '.local/share/dotfiles'
        destination.mkdir(parents=True)
        with self.assertRaisesRegex(RuntimeError, 'Both'):
            self.migration.repository()
        self.assertTrue(repo.exists())
        self.assertTrue(destination.exists())

    def test_old_repository_is_kept_until_dotfiles_are_updated(self):
        repo = self.home / '.dotfiles'
        subprocess.run(['git', 'init', '--bare', str(repo)], check=True, capture_output=True)
        with self.assertRaisesRegex(RuntimeError, 'Update the dotfiles revision'):
            self.migration.repository()
        self.assertTrue(repo.exists())

    def test_history_moves_and_conflict_is_backed_up(self):
        self.write('.zshenv', '# bootstrap')
        self.write('.cache/zsh/history', 'old history')
        self.write('.lesshst', 'less history')
        self.write('.local/state/less/history', 'new less history')
        self.migration.managed_files()
        self.assertEqual((self.home / '.local/state/zsh/history').read_text(), 'old history')
        self.assertEqual((self.home / '.local/state/less/history').read_text(), 'new less history')
        self.assertEqual((self.migration.backup / '.lesshst').read_text(), 'less history')
        self.assertFalse((self.home / '.lesshst').exists())
        backup = self.migration.backup
        self.migration.managed_files()
        self.assertEqual(self.migration.backup, backup)

    def test_keeps_legacy_startup_until_bootstrap_is_installed(self):
        (self.home / '.zprofile').symlink_to('.config/shell/profile')
        self.migration.managed_files()
        self.assertTrue((self.home / '.zprofile').is_symlink())

    def test_preserves_custom_startup_and_unmanaged_files(self):
        self.write('.zshenv', '# bootstrap')
        self.write('.zprofile', 'custom profile')
        self.write('README.md', 'personal notes')
        self.write('.bashrc', 'fallback shell')
        self.write('.Xauthority', 'active session')
        self.migration.managed_files()
        self.assertEqual((self.home / '.zprofile').read_text(), 'custom profile')
        self.assertEqual((self.home / 'README.md').read_text(), 'personal notes')
        self.assertTrue((self.home / '.bashrc').exists())
        self.assertTrue((self.home / '.Xauthority').exists())

    def test_archives_only_known_startup_links(self):
        self.write('.zshenv', '# bootstrap')
        (self.home / '.zprofile').symlink_to('.config/shell/profile')
        (self.home / '.xprofile').symlink_to('custom-profile')
        self.migration.managed_files()
        self.assertFalse((self.home / '.zprofile').is_symlink())
        self.assertEqual((self.migration.backup / '.zprofile').readlink(), Path('.config/shell/profile'))
        self.assertTrue((self.home / '.xprofile').is_symlink())

    def test_refuses_destination_parent_symlink(self):
        outside = Path(self.temp.name) / 'outside'
        outside.mkdir()
        (self.home / '.local').symlink_to(outside)
        self.write('.lesshst', 'keep')
        with self.assertRaisesRegex(RuntimeError, 'real directory'):
            self.migration.move('.lesshst', '.local/state/less/history')
        self.assertEqual((self.home / '.lesshst').read_text(), 'keep')
        self.assertEqual(list(outside.iterdir()), [])

    def test_installer_move_preserves_local_files(self):
        repo = self.home / 'rice'
        subprocess.run(['git', 'init', str(repo)], check=True, capture_output=True)
        subprocess.run(['git', '-C', str(repo), 'remote', 'add', 'origin', 'https://github.com/crlxs/rice.git'], check=True)
        self.write('rice/uncommitted', 'work in progress')
        self.migration.installer()
        self.assertEqual((self.home / '.local/src/rice/uncommitted').read_text(), 'work in progress')
        self.migration.installer()
