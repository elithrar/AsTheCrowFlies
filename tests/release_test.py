# Adapted from XPIsland release tooling (BSD-3-Clause).
# Copyright (c) 2026, Matt Silverlock. See tools/XPISLAND-LICENSE.txt.
"""Real Git guards, artifact integrity, and offline publisher retry contracts."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import release
import publish_curseforge as cf
import publish_github as github


def fixture(test):
    temp = tempfile.TemporaryDirectory()
    test.addCleanup(temp.cleanup)
    root = Path(temp.name)
    (root/'dist').mkdir();(root/'docs/releases').mkdir(parents=True);(root/'AsTheCrowFlies').mkdir()
    toc = ReleaseTests().toc()
    (root/'AsTheCrowFlies/AsTheCrowFlies.toc').write_text(toc, encoding='utf-8')
    data = release.metadata('v0.1.0',toc);data['commit']='a'*40
    (root/'dist/release.json').write_text(json.dumps(data), encoding='utf-8')
    archive = root/'dist'/data['archive']
    with zipfile.ZipFile(archive,'w') as bundle:
        bundle.writestr('AsTheCrowFlies/AsTheCrowFlies.toc',toc)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    (root/'dist/SHA256SUMS').write_text(f'{digest}  {archive.name}\n', encoding='utf-8')
    (root/'docs/releases/0.1.0.md').write_text('Release notes', encoding='utf-8')
    return root,data,digest


class ReleaseTests(unittest.TestCase):
    def toc(self, version='0.1.0'):
        return f'## Interface: 16001\n## Version: {version}\n## X-Curse-Project-ID: 1739133\n'

    def test_classification(self):
        for version, kind in [('0.1.0','release'),('0.1.0-alpha.1','alpha'),('0.1.0-beta.2','beta'),('0.1.0-rc.1','beta')]:
            with self.subTest(version=version):
                data=release.metadata('v'+version,self.toc(version))
                self.assertEqual(data['release_type'],kind)
                self.assertEqual(data['prerelease'],kind!='release')
                self.assertEqual(data['archive'],f'AsTheCrowFlies-{version}.zip')
        for invalid in ['0.1.0','v01.2.3','v0.1.0-dev','v0.1.0;echo x','v0.1.0-alpha.0']:
            with self.assertRaises(ValueError): release.metadata(invalid,self.toc())

    def test_metadata_must_match(self):
        for toc in [self.toc('0.3.0'),self.toc().replace('16001','120001'),self.toc()+'## Interface-Classic: 11507\n',self.toc().replace('1739133','99'),self.toc()+'## Version: 0.1.0\n',self.toc()+'## X-Curse-Project-ID: 1739133\n']:
            with self.assertRaises(ValueError): release.metadata('v0.1.0',toc)

    def test_exact_forever_only(self):
        data=release.metadata('v0.1.0',self.toc())
        versions=[{'id':1,'name':'1.60.1','gameVersionTypeID':517},{'id':2,'name':'1.60.0','gameVersionTypeID':88568}]
        with self.assertRaises(ValueError): cf.exact_version(versions,data)
        versions.append({'id':3,'name':'1.60.1','gameVersionTypeID':88568})
        self.assertEqual(cf.exact_version(versions,data),3)
        with self.assertRaises(ValueError): cf.exact_version(versions+[versions[-1]],data)
        for invalid in [True,0,-1,'3']:
            with self.assertRaises(ValueError): cf.exact_version([dict(versions[-1],id=invalid)],data)

    def test_artifact_rejects_wrong_hash_filename_metadata_and_commit(self):
        root,data,digest = fixture(self)
        self.assertEqual(release.artifact(root)[2],digest)
        checksums=root/'dist/SHA256SUMS';original=checksums.read_text()
        for changed in [f'{digest}  other.zip\n',f'{"0"*64}  {data["archive"]}\n',original+original]:
            checksums.write_text(changed)
            with self.assertRaises(ValueError): release.artifact(root)
        checksums.write_text(original)
        for key,value in [('archive','../other.zip'),('project_id',1727059),('prerelease',True),('commit','not-a-commit')]:
            (root/'dist/release.json').write_text(json.dumps(dict(data,**{key:value})))
            with self.assertRaises(ValueError): release.artifact(root)

    def test_tag_ancestry_and_annotation(self):
        with tempfile.TemporaryDirectory(prefix='asthecrowflies-release-test-') as folder:
            path=Path(folder)
            def git(*args):
                return subprocess.check_output(['git',*args],cwd=path,text=True,stderr=subprocess.DEVNULL).strip()
            git('init','-b','main');git('config','commit.gpgsign','false');git('config','tag.gpgsign','false');git('config','user.name','Release test');git('config','user.email','test@example.invalid')
            (path/'file').write_text('one');git('add','file');git('commit','-m','base')
            git('update-ref','refs/remotes/origin/main','HEAD')
            git('tag','-a','v0.1.0','-m','Release 0.1.0')
            self.assertEqual(release.check_tag('v0.1.0',path),git('rev-parse','HEAD'))
            git('tag','v0.1.1')
            with self.assertRaises(ValueError): release.check_tag('v0.1.1',path)
            git('checkout','-b','unmerged');(path/'file').write_text('two');git('commit','-am','off-main');git('tag','-a','v0.1.2','-m','Off-main')
            with self.assertRaises(ValueError): release.check_tag('v0.1.2',path)
            with self.assertRaises(ValueError): release.check_tag('v0.1.0',path)
            git('checkout','main');git('merge','--ff-only','unmerged');git('update-ref','refs/remotes/origin/main','HEAD')
            self.assertEqual(release.check_tag('v0.1.2',path),git('rev-parse','HEAD'))

    def test_multipart_preserves_exact_zip(self):
        root,_,_ = fixture(self);archive=root/'dist/AsTheCrowFlies-0.1.0.zip'
        data={'gameVersions':[123], 'releaseType':'release'}
        body,content_type=cf.multipart(data,archive)
        self.assertIn(json.dumps(data).encode(),body);self.assertIn(archive.read_bytes(),body)
        self.assertIn(b'name="file"; filename="AsTheCrowFlies-0.1.0.zip"',body)
        self.assertTrue(content_type.startswith('multipart/form-data; boundary=AsTheCrowFlies-'))


class UploadTests(unittest.TestCase):
    def setUp(self):
        self.root,self.data,self.digest = fixture(self)
        self.receipt=dict(file_id=12345,project_id=1739133,tag='v0.1.0',sha256=self.digest,
                          release_type='release',game_version_id=33,game_version='1.60.1',flavor='Forever',commit=self.data['commit'])
        self.assets=[];self.calls=[]
        def gh(*args):
            self.calls.append(('gh',args))
            if args[:2]==('release','view'): return json.dumps(self.assets)
            if args[:2]==('release','download'):
                (Path(args[-1])/'curseforge-receipt.json').write_text(json.dumps(self.receipt))
            return ''
        def request(path,token,body=None,content_type=None):
            self.calls.append(('request',path))
            if body is None: return [{'id':33,'name':'1.60.1','gameVersionTypeID':88568}]
            return {'id':12345}
        for context in [patch.object(cf,'ROOT',self.root), patch.object(cf,'gh',side_effect=gh),
                        patch.object(cf,'request',side_effect=request), patch.dict(cf.os.environ,{'CF_API_TOKEN':'unit-test-only','GITHUB_STEP_SUMMARY':''})]:
            context.start();self.addCleanup(context.stop)

    def test_success_records_receipt_after_pending_marker(self):
        cf.main()
        receipt=json.loads((self.root/'dist/curseforge-receipt.json').read_text())
        self.assertEqual(receipt['file_id'],12345);self.assertEqual(receipt['release_type'],'release')
        self.assertEqual(receipt['game_version_id'],33)
        self.assertEqual(receipt['commit'],self.data['commit'])
        post=next(i for i,c in enumerate(self.calls) if c[0]=='request' and c[1].endswith('upload-file'))
        pending=next(i for i,c in enumerate(self.calls) if c[0]=='gh' and 'curseforge-upload-pending.json' in c[1][-1])
        self.assertLess(pending,post)
        self.assertEqual(self.calls[-1][1][:2],('release','delete-asset'))

    def test_receipt_prevents_duplicate_upload(self):
        self.assets=['curseforge-receipt.json'];cf.main()
        self.assertFalse(any(c[0]=='request' for c in self.calls))

    def test_mismatched_receipt_blocks_without_upload(self):
        self.assets=['curseforge-receipt.json']
        for key,value in [('project_id',1727059),('tag','v0.1.1'),('sha256','0'*64),('commit','b'*40),('file_id',True),('game_version_id',0)]:
            original=self.receipt[key];self.receipt[key]=value
            with self.assertRaises(ValueError): cf.main()
            self.receipt[key]=original
        self.assertFalse(any(c[0]=='request' for c in self.calls))

    def test_pending_marker_blocks_uncertain_retry(self):
        self.assets=['curseforge-upload-pending.json']
        with self.assertRaises(ValueError): cf.main()
        self.assertFalse(any(c[0]=='request' for c in self.calls))

    def test_post_timeout_is_not_retried(self):
        original=cf.request.side_effect
        def timeout(path,*args):
            if path.endswith('upload-file'): raise TimeoutError('simulated network delay')
            return original(path,*args)
        cf.request.side_effect=timeout
        with self.assertRaises(TimeoutError): cf.main()
        self.assertEqual(cf.request.call_count,2) # one GET, one POST
        self.assertTrue((self.root/'dist/curseforge-upload-pending.json').exists())
        self.assertFalse((self.root/'dist/curseforge-receipt.json').exists())

    def test_receipt_save_failure_blocks_a_second_post(self):
        original=cf.gh.side_effect
        def fail_receipt(*args):
            if args[:2]==('release','upload') and args[-1].endswith('curseforge-receipt.json'):
                raise subprocess.CalledProcessError(1,['gh','release','upload'])
            return original(*args)
        cf.gh.side_effect=fail_receipt
        with self.assertRaises(subprocess.CalledProcessError): cf.main()
        self.assertFalse(any(c[0]=='gh' and c[1][:2]==('release','delete-asset') for c in self.calls))
        self.assets=['curseforge-upload-pending.json'];cf.gh.side_effect=original
        with self.assertRaises(ValueError): cf.main()
        self.assertEqual(cf.request.call_count,2) # Still only the first version GET and upload POST.

    def test_invalid_upload_id_keeps_pending_marker(self):
        original=cf.request.side_effect
        cf.request.side_effect=lambda path,*args: {'id':True} if path.endswith('upload-file') else original(path,*args)
        with self.assertRaises(ValueError): cf.main()
        self.assertTrue((self.root/'dist/curseforge-upload-pending.json').exists())
        self.assertFalse((self.root/'dist/curseforge-receipt.json').exists())

    def test_missing_token_and_bad_hash_prevent_requests(self):
        with patch.dict(cf.os.environ,{'CF_API_TOKEN':''}):
            with self.assertRaises(ValueError): cf.main()
        (self.root/'dist/SHA256SUMS').write_text('bad')
        with self.assertRaises(ValueError): cf.main()
        self.assertEqual(cf.request.call_count,0)


class GitHubTests(unittest.TestCase):
    def setUp(self):
        self.root,self.data,self.digest=fixture(self)
        self.assets={};self.calls=[];self.exists=False;self.remote_commit=self.data['commit']
        def gh(*args,**kwargs):
            self.calls.append(args)
            if args[0]=='api':
                if '/commits/' in args[1]: return self.remote_commit
                releases=[dict(tag_name=self.data['tag'],assets=[{'name':name} for name in self.assets])] if self.exists else []
                return json.dumps([releases])
            if args[:2]==('release','download'):
                name=args[args.index('--pattern')+1]
                (Path(args[args.index('--dir')+1])/name).write_bytes(self.assets[name])
            elif args[:2]==('release','create'):
                self.exists=True
                for name in args[3:args.index('--verify-tag')]:
                    path=Path(name);self.assets[path.name]=path.read_bytes()
            elif args[:2]==('release','upload'):
                path=Path(args[3]);self.assets[path.name]=path.read_bytes()
            elif args[:2]==('release','view'):
                return 'https://github.com/example/AsTheCrowFlies/releases/tag/v0.1.0'
            return ''
        for context in [patch.object(github,'ROOT',self.root),patch.object(github,'gh',side_effect=gh)]:
            context.start();self.addCleanup(context.stop)

    def writes(self):
        return [args for args in self.calls if args[:2] in [('release','create'),('release','upload'),('release','edit')]]

    def test_stable_creation_and_identical_rerun(self):
        github.main()
        create=next(args for args in self.calls if args[:2]==('release','create'))
        self.assertIn('--verify-tag',create);self.assertIn('--draft',create);self.assertNotIn('--prerelease',create)
        self.assertEqual(set(self.assets),{self.data['archive'],'SHA256SUMS','release.json'})
        self.assertIn('--prerelease=false',self.calls[-2])
        self.calls.clear();github.main()
        self.assertEqual([args[:2] for args in self.writes()],[('release','edit')])

    def test_partial_release_uploads_only_missing_assets(self):
        self.exists=True;self.assets[self.data['archive']]=(self.root/'dist'/self.data['archive']).read_bytes()
        github.main()
        uploaded=[Path(args[3]).name for args in self.writes() if args[:2]==('release','upload')]
        self.assertEqual(uploaded,['SHA256SUMS','release.json'])

    def test_existing_zip_or_sidecar_mismatch_prevents_all_writes(self):
        self.exists=True
        for name in [self.data['archive'],'SHA256SUMS','release.json']:
            self.assets={name:b'wrong bytes'};self.calls.clear()
            with self.assertRaises(ValueError): github.main()
            self.assertEqual(self.writes(),[])

    def test_moved_tag_prevents_writes(self):
        self.remote_commit='b'*40
        with self.assertRaises(ValueError): github.main()
        self.assertEqual(self.writes(),[])

    def test_release_list_failure_is_not_treated_as_absence(self):
        original=github.gh.side_effect
        def fail_list(*args,**kwargs):
            if args[:2]==('api','--paginate'): raise subprocess.CalledProcessError(1,['gh','api'])
            return original(*args,**kwargs)
        github.gh.side_effect=fail_list
        with self.assertRaises(subprocess.CalledProcessError): github.main()
        self.assertEqual(self.writes(),[])


if __name__ == '__main__':
    unittest.main()
