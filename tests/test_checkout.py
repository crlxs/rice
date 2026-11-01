import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('checkout', Path(__file__).parents[1] / 'files/checkout_dotfiles.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CheckoutTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        source = root / 'source'
        source.mkdir()
        self.home = root / 'home'
        self.home.mkdir()
        self.run_git('init', str(source))
        (source / '.config').mkdir()
        (source / '.config/example').write_text('upstream')
        (source / '.zprofile').symlink_to('.config/example')
        self.run_git('-C', str(source), 'add', '.')
        self.run_git('-C', str(source), '-c', 'user.name=Test', '-c', 'user.email=test@example.org', 'commit', '-m', 'fixture')
        (self.home / '.local/share').mkdir(parents=True)
        self.run_git('clone', '--bare', str(source), str(self.home / '.local/share/dotfiles'))

    def run_git(self, *args):
        subprocess.run(['git', *args], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def test_backup_checkout_and_preserve_edits_on_rerun(self):
        (self.home / '.config').mkdir()
        target = self.home / '.config/example'
        target.write_text('existing settings')
        (self.home / '.zprofile').symlink_to('old-profile')
        module.checkout(self.home)
        backups = list((self.home / '.local/state/rice/backups').iterdir())
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / '.config/example').read_text(), 'existing settings')
        self.assertEqual((backups[0] / '.zprofile').readlink(), Path('old-profile'))
        self.assertEqual(target.read_text(), 'upstream')
        target.write_text('my edits')
        module.checkout(self.home)
        self.assertEqual(target.read_text(), 'my edits')
        self.assertEqual(len(list((self.home / '.local/state/rice/backups').iterdir())), 1)

    def test_refuse_symlink_parent_without_touching_destination(self):
        outside = Path(self.temp.name) / 'outside'
        outside.mkdir()
        (outside / 'example').write_text('keep')
        (self.home / '.config').symlink_to(outside)
        with self.assertRaisesRegex(RuntimeError, 'real directory'):
            module.checkout(self.home)
        self.assertEqual((outside / 'example').read_text(), 'keep')
