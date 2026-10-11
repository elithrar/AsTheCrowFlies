"""Package integrity tests, including clean-checkout release builds without private data."""
from contextlib import contextmanager
from pathlib import Path
import hashlib
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE_ONLY = '--source-only' in sys.argv
VERSION = re.search(r'^## Version: (.+)$',
                    (ROOT / 'AsTheCrowFlies/AsTheCrowFlies.toc').read_text(encoding='utf-8'),
                    re.M).group(1)
TAXI_SHA256 = 'e74250e6ed1ea8cf69e3869e161135bb1bbba195ba794f5e0ccd78fc30320db7'
TOC_FILES = ['Model.lua', 'Settings.lua', 'Data/Registry.lua', 'Data/Taxi.lua',
             'Routes.lua', 'Navigation.lua', 'Adapter.lua', 'Providers.lua',
             'UI.lua', 'Overlay.lua', 'Options.lua', 'Core.lua', 'Bindings.xml']
RUNTIME_FILES = {'AsTheCrowFlies.toc', *TOC_FILES,
                 'Media/eagle.tga', 'Media/arrow.tga', 'Media/surface.tga', 'Media/cog.tga'}
DEV_DOCS = {'README.md', 'NOTICES.md', 'plan.md', 'docs/BEHAVIOR.md',
            'docs/COVERAGE.md', 'docs/VALIDATION.md', 'docs/REVIEW.md',
            'docs/data-provenance.json', 'docs/npc-coverage.json',
            'docs/transport-audit.json', 'docs/performance.json'}
RELEASE_FILES = RUNTIME_FILES | {'README.md', 'NOTICES.md', 'CHANGELOG.md',
                                 'DATA-PROVENANCE.json'}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def normalized(data):
    return data.replace(b'\r\n', b'\n')


@contextmanager
def fixture():
    # Copy only build inputs; never copy private caches, archives or credentials.
    scratch = (ROOT / '.work').resolve()
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='package-test-', dir=scratch) as temporary:
        root = Path(temporary).resolve()
        if not root.is_relative_to(scratch):
            raise AssertionError('Temporary package fixture escaped the workspace')
        shutil.copytree(ROOT / 'AsTheCrowFlies', root / 'AsTheCrowFlies')
        shutil.copytree(ROOT / 'docs', root / 'docs')
        for name in ('README.md', 'NOTICES.md', 'plan.md'):
            shutil.copyfile(ROOT / name, root / name)
        yield root


class Packages(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        sys.path.insert(0, str(ROOT / 'tools'))
        spec = importlib.util.spec_from_file_location('addon_package', ROOT / 'tools/package.py')
        cls.builder = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.builder)

    def check_archive(self, path, report, expected):
        self.assertEqual(report['sha256'], digest(path.read_bytes()))
        self.assertEqual(report['bytes'], path.stat().st_size)
        with zipfile.ZipFile(path) as archive:
            names = archive.namelist()
            self.assertEqual(set(names), {'AsTheCrowFlies/' + name for name in expected})
            self.assertEqual(len(names), len(expected))
            self.assertEqual(names, sorted(names))
            self.assertIsNone(archive.testzip())
            self.assertEqual(len({info.date_time for info in archive.infolist()}), 1)
            self.assertEqual(report['files'], {name: digest(archive.read(name)) for name in names})
            for name in names:
                self.assertFalse(name.endswith(('.bin', '.exe', '.db2', '.py', '.cjs')))
                if Path(name).suffix in ('.lua', '.toc', '.xml', '.md', '.json'):
                    self.assertNotIn(b'\r', archive.read(name), name)
            toc = archive.read('AsTheCrowFlies/AsTheCrowFlies.toc').decode('utf-8').splitlines()
            self.assertIn('## Interface: 16001', toc)
            self.assertIn('## Version: ' + VERSION, toc)
            self.assertIn('## X-Curse-Project-ID: 1739133', toc)
            self.assertEqual([line for line in toc if line and not line.startswith('#')], TOC_FILES)
            taxi = archive.read('AsTheCrowFlies/Data/Taxi.lua')
            self.assertEqual(digest(taxi), TAXI_SHA256)
            self.assertEqual(len(taxi), 349728)
            self.assertIn(b'N.Data.LocalTaxi=', taxi)
            self.assertEqual(taxi.count(b'["category"]="flight"'), 98)
            self.assertEqual(taxi.count(b'["mode"]="flight"'), 294)

    def test_reproducible_full_data_development_packages(self):
        for local in ((False,) if SOURCE_ONLY else (False, True)):
            with self.subTest(local=local):
                suffix = 'local' if local else 'source'
                report = self.builder.build(root=ROOT, local_data=local)
                path = ROOT / 'dist' / f'AsTheCrowFlies-{VERSION}-dev-{suffix}.zip'
                first = path.read_bytes()
                second = self.builder.build(root=ROOT, local_data=local)
                self.assertEqual(first, path.read_bytes())
                self.assertEqual(report, second)
                expected = RUNTIME_FILES | DEV_DOCS
                if local:
                    expected |= {'DATA-PROVENANCE.json'}
                self.check_archive(path, report, expected)
                manifest = json.loads((ROOT / 'dist' / f'{VERSION}-dev-{suffix}-manifest.json').read_text())
                self.assertEqual(manifest, report)

    def test_release_is_reproducible_stable_complete_and_minimal(self):
        report = self.builder.build(root=ROOT, release=True)
        path = ROOT / 'dist' / f'AsTheCrowFlies-{VERSION}.zip'
        first = path.read_bytes()
        self.assertEqual(report, self.builder.build(root=ROOT, release=True))
        self.assertEqual(first, path.read_bytes())
        self.assertEqual(len(RELEASE_FILES), 22)
        self.check_archive(path, report, RELEASE_FILES)
        with zipfile.ZipFile(path) as archive:
            self.assertEqual(archive.read('AsTheCrowFlies/CHANGELOG.md'),
                             normalized((ROOT / f'docs/releases/{VERSION}.md').read_bytes()))
            provenance = json.loads(archive.read('AsTheCrowFlies/DATA-PROVENANCE.json'))
            self.assertEqual(provenance['payloadSHA256'], TAXI_SHA256)
            self.assertEqual(provenance['build'], '1.60.1.70338')
            self.assertEqual((provenance['candidateNodes'], provenance['candidateEdges']), (98, 294))
        release = json.loads((ROOT / 'dist/release.json').read_text())
        for key, value in {'version': VERSION, 'release_type': 'release', 'prerelease': False,
                           'project_id': 1739133, 'game_version': '1.60.1',
                           'sha256': digest(first), 'files': report['files']}.items():
            self.assertEqual(release[key], value, key)
        commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
        self.assertEqual(release['commit'], commit)
        self.assertEqual((ROOT / 'dist/SHA256SUMS').read_bytes(),
                         (digest(first) + '  ' + path.name + '\n').encode())

    def test_input_line_endings_and_timestamps_do_not_change_release_bytes(self):
        with fixture() as root:
            self.builder.build(root=root, release=True)
            path = root / 'dist' / f'AsTheCrowFlies-{VERSION}.zip'
            first = path.read_bytes()
            for name in ('README.md', 'AsTheCrowFlies/Core.lua', 'AsTheCrowFlies/AsTheCrowFlies.toc'):
                source = root / name
                source.write_bytes(normalized(source.read_bytes()).replace(b'\n', b'\r\n'))
                os.utime(source, (946684800, 946684800))
            self.builder.build(root=root, release=True)
            self.assertEqual(first, path.read_bytes())

    def test_source_stub_or_corrupted_flight_data_cannot_be_packaged(self):
        with fixture() as root:
            self.builder.build(root=root)
            path = root / 'AsTheCrowFlies/Data/Taxi.lua'
            full = path.read_bytes()
            for data in (b'-- Development data stub\n', full.replace(b'1.60.1.70338', b'1.60.1.70339')):
                path.write_bytes(data)
                for release in (False, True):
                    with self.subTest(stub=len(data) < 100, release=release):
                        with self.assertRaisesRegex((ValueError, RuntimeError), '(?i)(taxi|payload|sha|hash|checksum|graph|data)'):
                            self.builder.build(root=root, release=release)

    def test_unexpected_addon_file_is_rejected_instead_of_leaking_into_zip(self):
        with fixture() as root:
            self.builder.build(root=root)
            (root / 'AsTheCrowFlies/unexpected-debug.txt').write_text('Not an addon asset.\n')
            for release in (False, True):
                with self.subTest(release=release):
                    with self.assertRaisesRegex((ValueError, RuntimeError), '(?i)(unexpected|allowlist|unlisted|runtime)'):
                        self.builder.build(root=root, release=release)

    @unittest.skipIf(SOURCE_ONLY, 'Private local override is intentionally unavailable in source-only CI')
    def test_local_override_must_match_the_verified_payload(self):
        with fixture() as root:
            (root / '.work').mkdir()
            path = root / '.work/LocalTaxi.lua'
            shutil.copyfile(ROOT / '.work/LocalTaxi.lua', path)
            self.builder.build(root=root, local_data=True)
            path.write_bytes(b'local _,N=...\nN.Data.LocalTaxi={nodes={},edges={}}\n')
            with self.assertRaisesRegex((ValueError, RuntimeError), '(?i)(taxi|payload|sha|hash|checksum|graph|data)'):
                self.builder.build(root=root, local_data=True)


if __name__ == '__main__':
    unittest.main(argv=[sys.argv[0]])
