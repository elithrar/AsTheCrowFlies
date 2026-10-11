# Adapted from XPIsland release tooling (BSD-3-Clause).
# Copyright (c) 2026, Matt Silverlock. See XPISLAND-LICENSE.txt.
"""Release metadata and Git safety checks. No credentials or network writes."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

VERSION = r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-(alpha|beta|rc)\.([1-9][0-9]*))?'
ROOT = Path(__file__).resolve().parents[1]


def metadata(tag, toc):
    match = re.fullmatch('v' + VERSION, tag)
    if not match:
        raise ValueError('Use vX.Y.Z, vX.Y.Z-alpha.N, vX.Y.Z-beta.N or vX.Y.Z-rc.N')
    versions = re.findall(r'^## Version: (.+)$', toc, re.M)
    if versions != [tag[1:]]:
        raise ValueError('Tag must exactly match the TOC version')
    if re.findall(r'^## Interface[^:]*: (.+)$', toc, re.M) != ['16001']:
        raise ValueError('This release supports only Forever 1.60.1 (16001)')
    projects = re.findall(r'^## X-Curse-Project-ID: (.+)$', toc, re.M)
    if projects != ['1739133']:
        raise ValueError('Unexpected CurseForge project')
    kind = 'alpha' if match[4] == 'alpha' else 'beta' if match[4] else 'release'
    return dict(tag=tag, version=tag[1:], release_type=kind,
                prerelease=kind != 'release', archive=f'AsTheCrowFlies-{tag[1:]}.zip',
                project_id=1739133, game_version='1.60.1', game_version_type=88568)


def artifact(root=ROOT):
    """Validate shared metadata and the exact named ZIP before either publisher writes."""
    data = json.loads((root / 'dist/release.json').read_text(encoding='utf-8'))
    expected = metadata(data['tag'], (root / 'AsTheCrowFlies/AsTheCrowFlies.toc').read_text(encoding='utf-8'))
    if any(type(data.get(key)) is not type(value) or data[key] != value for key, value in expected.items()):
        raise ValueError('Release metadata does not match the tagged addon')
    if not isinstance(data.get('commit'), str) or not re.fullmatch(r'(?:[0-9a-f]{40}|[0-9a-f]{64})', data['commit']):
        raise ValueError('Release metadata has no valid commit')
    archive = root / 'dist' / expected['archive']
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    checksums = (root / 'dist/SHA256SUMS').read_text(encoding='utf-8').splitlines()
    if checksums != [f'{digest}  {archive.name}']:
        raise ValueError('Release artifact name/hash does not match validation output')
    return data, archive, digest


def git(*args, cwd=ROOT):
    return subprocess.check_output(['git', *args], cwd=cwd, text=True).strip()


def check_tag(tag, cwd=ROOT):
    ref = f'refs/tags/{tag}'
    if git('cat-file', '-t', ref, cwd=cwd) != 'tag':
        raise ValueError('Release tags must be annotated: git tag -a ...')
    commit = git('rev-parse', f'{ref}^{{commit}}', cwd=cwd)
    if git('rev-parse', 'HEAD', cwd=cwd) != commit:
        raise ValueError('Checkout must be the tagged commit')
    if subprocess.run(['git', 'merge-base', '--is-ancestor', commit, 'origin/main'], cwd=cwd).returncode:
        raise ValueError('Tagged commit is not reachable from origin/main')
    return commit


def main():
    tag = os.environ.get('RELEASE_TAG') or (sys.argv[1] if len(sys.argv) > 1 else '')
    data = metadata(tag, (ROOT / 'AsTheCrowFlies/AsTheCrowFlies.toc').read_text(encoding='utf-8'))
    data['commit'] = check_tag(tag)
    notes = ROOT / 'docs/releases' / (data['version'] + '.md')
    if not notes.is_file():
        raise ValueError('Add version-specific release notes before tagging')
    (ROOT / 'dist').mkdir(exist_ok=True)
    (ROOT / 'dist/release.json').write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
    if os.environ.get('GITHUB_OUTPUT'):
        with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
            for key in ('tag', 'version', 'archive', 'release_type', 'commit'):
                output.write(f'{key}={data[key]}\n')
    print(f"Validated {tag}: {data['release_type']}, Forever 1.60.1, commit {data['commit']}")


if __name__ == '__main__':
    main()
