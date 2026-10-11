# Adapted from XPIsland release tooling (BSD-3-Clause).
# Copyright (c) 2026, Matt Silverlock. See XPISLAND-LICENSE.txt.
"""Publish the exact validated ZIP with GitHub's job-scoped token."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from release import artifact

ROOT = Path(__file__).resolve().parents[1]


def gh(*args, **kwargs):
    return subprocess.check_output(['gh', *args], text=True, **kwargs).strip()


def main():
    data, archive, _ = artifact(ROOT)
    tag = data['tag']
    if gh('api', f'repos/{{owner}}/{{repo}}/commits/{tag}', '--jq', '.sha') != data['commit']:
        raise ValueError('Remote tag no longer points to the validated commit')
    # A read/list failure aborts; it is never interpreted as "no release".
    releases = json.loads(gh('api', '--paginate', '--slurp', 'repos/{owner}/{repo}/releases'))
    existing = next((r for page in releases for r in page if r['tag_name'] == tag), None)
    if existing:
        # Validate every existing asset before making writes. Reruns may finish
        # a partial release but must never combine mismatched ZIP/metadata bytes.
        names = {a['name'] for a in existing['assets']}
        assets = (archive, ROOT / 'dist/SHA256SUMS', ROOT / 'dist/release.json')
        with tempfile.TemporaryDirectory() as directory:
            for path in assets:
                if path.name in names:
                    gh('release', 'download', tag, '--pattern', path.name, '--dir', directory)
                    if hashlib.sha256((Path(directory) / path.name).read_bytes()).digest() != hashlib.sha256(path.read_bytes()).digest():
                        raise ValueError(f'Existing release has different {path.name} bytes; publish a new version')
        for path in assets:
            if path.name not in names:
                gh('release', 'upload', tag, str(path))
    else:
        args = ['release', 'create', tag, str(archive), str(ROOT / 'dist/SHA256SUMS'),
                str(ROOT / 'dist/release.json'), '--verify-tag', '--draft', '--title', f'AsTheCrowFlies {tag}',
                '--notes-file', str(ROOT / 'docs/releases' / (data['version'] + '.md'))]
        if data['prerelease']:
            args.append('--prerelease')
        gh(*args)
    gh('release', 'edit', tag, '--draft=false', '--prerelease=' + str(data['prerelease']).lower())
    print(gh('release', 'view', tag, '--json', 'url', '--jq', '.url'))


if __name__ == '__main__':
    main()
