# Adapted from XPIsland release tooling (BSD-3-Clause).
# Copyright (c) 2026, Matt Silverlock. See XPISLAND-LICENSE.txt.
"""Upload the same ZIP to CurseForge, with exact flavor/version and retry guards.

Uses the documented Upload API, and Forever type 88568 verified in BigWigs
packager 2.6.1. No version fallback, repackaging, shell token arguments or POST retries.
"""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import urllib.error
import urllib.request
import uuid

from release import artifact

ROOT = Path(__file__).resolve().parents[1]
BASE = 'https://wow.curseforge.com'


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise ValueError('Unexpected CurseForge redirect; upload was not retried')


def request(path, token, body=None, content_type=None):
    headers = {'X-Api-Token': token, 'Accept': 'application/json', 'User-Agent': 'AsTheCrowFlies-release/1'}
    if content_type:
        headers['Content-Type'] = content_type
    req = urllib.request.Request(BASE + path, data=body, headers=headers)
    try:
        with urllib.request.build_opener(NoRedirect()).open(req, timeout=90) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        # Never echo response bodies/headers, which could include credentials.
        raise RuntimeError(f'CurseForge HTTP {error.code}; inspect the author dashboard before retrying') from None
    except (urllib.error.URLError, TimeoutError):
        raise RuntimeError('CurseForge request failed; inspect the author dashboard before retrying') from None


def exact_version(versions, data):
    matches = [v for v in versions if v['name'] == data['game_version']
               and v['gameVersionTypeID'] == data['game_version_type']]
    if len(matches) != 1:
        raise ValueError('Expected exactly one Forever 1.60.1 version; refusing a fallback version/flavor')
    version_id = matches[0]['id']
    if type(version_id) is not int or version_id <= 0:
        raise ValueError('Forever game version has no valid numeric ID')
    return version_id


def multipart(metadata, archive):
    boundary = 'AsTheCrowFlies-' + uuid.uuid4().hex
    body = (f'--{boundary}\r\nContent-Disposition: form-data; name="metadata"\r\n'
            'Content-Type: application/json\r\n\r\n').encode() + json.dumps(metadata).encode()
    body += (f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{archive.name}"\r\n'
             'Content-Type: application/zip\r\n\r\n').encode() + archive.read_bytes()
    return body + f'\r\n--{boundary}--\r\n'.encode(), f'multipart/form-data; boundary={boundary}'


def gh(*args):
    return subprocess.check_output(['gh', *args], text=True).strip()


def validate_receipt(receipt, data, digest):
    expected = dict(project_id=data['project_id'], tag=data['tag'], sha256=digest,
                    release_type=data['release_type'], game_version=data['game_version'],
                    flavor='Forever', commit=data['commit'])
    if any(type(receipt.get(key)) is not type(value) or receipt[key] != value for key, value in expected.items()):
        raise ValueError('CurseForge receipt does not match this release; reconcile it before retrying')
    for key in ('file_id', 'game_version_id'):
        if type(receipt.get(key)) is not int or receipt[key] <= 0:
            raise ValueError('CurseForge receipt has no valid file/version ID')


def main():
    token = os.environ.get('CF_API_TOKEN')
    if not token:
        raise ValueError('CF_API_TOKEN is missing; no CurseForge upload attempted')
    data, archive, digest = artifact(ROOT)
    tag = data['tag']
    names = json.loads(gh('release', 'view', tag, '--json', 'assets', '--jq', '[.assets[].name]'))
    if 'curseforge-receipt.json' in names:
        with tempfile.TemporaryDirectory() as directory:
            gh('release', 'download', tag, '--pattern', 'curseforge-receipt.json', '--dir', directory)
            validate_receipt(json.loads((Path(directory) / 'curseforge-receipt.json').read_text(encoding='utf-8')), data, digest)
        print('CurseForge upload already has a receipt; no duplicate upload attempted')
        return
    if 'curseforge-upload-pending.json' in names:
        raise ValueError('An earlier upload may have reached CurseForge. Inspect its status and reconcile the pending marker before retrying')
    version_id = exact_version(request('/api/game/wow/versions', token), data)
    metadata = dict(displayName=f"AsTheCrowFlies {tag}", gameVersions=[version_id],
                    releaseType=data['release_type'], changelogType='markdown',
                    changelog=(ROOT / 'docs/releases' / (data['version'] + '.md')).read_text(encoding='utf-8'),
                    isMarkedForManualRelease=False)
    body, content_type = multipart(metadata, archive)
    # Persist intent before POST. A timeout cannot safely be treated as a failed
    # upload; this guard prevents a workflow rerun creating a second copy.
    pending = ROOT / 'dist/curseforge-upload-pending.json'
    pending.write_text(json.dumps(dict(tag=tag, project_id=data['project_id'], sha256=digest, commit=data['commit'])) + '\n', encoding='utf-8')
    gh('release', 'upload', tag, str(pending))
    response = request(f"/api/projects/{data['project_id']}/upload-file", token, body, content_type)
    file_id = response.get('id')
    if type(file_id) is not int or file_id <= 0:
        raise ValueError('Upload response has no valid file ID; check CurseForge before retrying')
    receipt = dict(file_id=file_id, project_id=data['project_id'], tag=tag, sha256=digest,
                   release_type=data['release_type'], game_version_id=version_id,
                   game_version=data['game_version'], flavor='Forever', commit=data['commit'],
                   status='uploaded; approval/publication not verified')
    receipt_path = ROOT / 'dist/curseforge-receipt.json'
    receipt_path.write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    gh('release', 'upload', tag, str(receipt_path))
    gh('release', 'delete-asset', tag, pending.name, '--yes')
    print(f"CurseForge accepted file {file_id} as {data['release_type']}; moderation/public visibility remains unverified")
    if os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as summary:
            summary.write(f"CurseForge accepted file {file_id} as {data['release_type']} for Forever 1.60.1. Approval/publication is not confirmed by the upload API.\n")


if __name__ == '__main__':
    main()
