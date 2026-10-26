"""Build deterministic, complete addon ZIPs. Never install or publish anything."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import zipfile

from release import metadata

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ('eagle', 'arrow', 'surface', 'cog')
DEV_DOCS = ('README.md', 'NOTICES.md', 'docs/BEHAVIOR.md',
            'docs/COVERAGE.md', 'docs/VALIDATION.md', 'docs/REVIEW.md',
            'docs/data-provenance.json', 'docs/npc-coverage.json',
            'docs/transport-audit.json', 'docs/performance.json')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read(path):
    data = path.read_bytes()
    return data if path.suffix == '.tga' else data.replace(b'\r\n', b'\n')


def build(root=ROOT, local_data=False, release=False):
    root = Path(root)
    addon = root / 'AsTheCrowFlies'
    toc = read(addon / 'AsTheCrowFlies.toc').decode('utf-8')
    match = re.search(r'^## Version: (.+)$', toc, re.M)
    if not match:
        raise ValueError('TOC version is missing')
    version = match[1]
    data = metadata('v' + version, toc)
    members = [line.strip() for line in toc.splitlines()
               if line.strip() and not line.startswith('#')]
    if len(set(members)) != len(members):
        raise ValueError('Duplicate TOC file')
    # The client loads the conventional Bindings.xml separately. Listing it
    # in the TOC sends Binding elements to the ordinary UI XML parser.
    if 'Bindings.xml' in members:
        raise ValueError('Bindings.xml is loaded automatically and must not be listed in the TOC')
    expected = {'Libs/SomethingNeedDoing/LICENSE', 'Libs/SomethingNeedDoing/UPSTREAM.json', 'AsTheCrowFlies.toc', 'Bindings.xml', *members, *(f'Media/{name}.tga' for name in MEDIA)}
    upstream = addon / "Libs/SomethingNeedDoing"
    pin = json.loads((upstream / "UPSTREAM.json").read_text())
    assert pin["version"] == "0.2.0" and pin["commit"] == "de2f518abad622f94aca7ad25599277544379fcd"
    assert set(pin["sha256"]) == {"Core.lua", "Diagnostics.lua", "Scope.lua", "State.lua", "Settings.lua", "UI.lua", "Options.lua", "LICENSE"}
    for name, checksum in pin["sha256"].items():
        assert hashlib.sha256((upstream / name).read_bytes()).hexdigest() == checksum, name
    for name in expected:
        if Path(name).is_absolute() or '\\' in name or '..' in Path(name).parts:
            raise ValueError('Unsafe addon path')
    files = [path for path in addon.rglob('*') if path.is_file()]
    if any(path.is_symlink() or not path.resolve().is_relative_to(addon.resolve()) for path in files):
        raise ValueError('Linked addon files are not allowed')
    # Older developer checkouts keep this ignored, pre-TOC override here.
    # It is never a package member; all other unexpected files remain errors.
    actual = {path.relative_to(addon).as_posix() for path in files} - {'Data/LocalTaxi.lua'}
    if actual != expected:
        raise ValueError('Addon files do not match TOC and media allowlist: ' + str(sorted(actual ^ expected)))
    payload = {'AsTheCrowFlies/' + name: read(addon / name) for name in sorted(expected)}
    provenance_bytes = read(root / 'docs/data-provenance.json')
    provenance = json.loads(provenance_bytes)
    taxi = (root / '.work/LocalTaxi.lua').read_bytes() if local_data else payload['AsTheCrowFlies/Data/Taxi.lua']
    if provenance['build'] != '1.60.1.70338' or sha(taxi) != provenance['payloadSHA256'] or b'N.Data.LocalTaxi=' not in taxi:
        raise ValueError('Full verified Forever flight data is required; refusing a stub or changed payload')
    payload['AsTheCrowFlies/Data/Taxi.lua'] = taxi
    if release:
        notes = root / 'docs/releases' / (version + '.md')
        if not notes.is_file():
            raise ValueError('Version-specific release notes are required')
        for name in ('README.md', 'NOTICES.md'):
            payload['AsTheCrowFlies/' + name] = read(root / name)
        payload['AsTheCrowFlies/CHANGELOG.md'] = read(notes)
        payload['AsTheCrowFlies/DATA-PROVENANCE.json'] = provenance_bytes
    else:
        for name in DEV_DOCS:
            path = root / name
            if path.is_file():
                payload['AsTheCrowFlies/' + name] = read(path)
        if local_data:
            payload['AsTheCrowFlies/DATA-PROVENANCE.json'] = provenance_bytes
    label = version if release else version + ('-dev-local' if local_data else '-dev-source')
    out = root / 'dist'
    out.mkdir(exist_ok=True)
    archive = out / f'AsTheCrowFlies-{label}.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for name, content in sorted(payload.items()):
            info = zipfile.ZipInfo(name, date_time=(2026, 10, 11, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o644 << 16
            z.writestr(info, content, compresslevel=9)
    revision = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=root, capture_output=True, text=True, check=True).stdout.strip()
    report = dict(file=archive.name, bytes=archive.stat().st_size, sha256=sha(archive.read_bytes()),
                  sourceCommit=revision, files={name: sha(content) for name, content in sorted(payload.items())})
    (out / (label + '-manifest.json')).write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8', newline='\n')
    if release:
        report = dict(data, **report, commit=revision)
        (out / 'release.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8', newline='\n')
        (out / 'SHA256SUMS').write_text(report['sha256'] + '  ' + archive.name + '\n', encoding='utf-8', newline='\n')
    return report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--local-data', action='store_true', help='Verify and use .work/LocalTaxi.lua instead of the tracked data')
    parser.add_argument('--release', action='store_true', help='Build the stable/tag-classified runtime ZIP and release sidecars')
    args = parser.parse_args()
    report = build(local_data=args.local_data, release=args.release)
    print(json.dumps({key: value for key, value in report.items() if key != 'files'}, indent=2))


if __name__ == '__main__':
    main()
