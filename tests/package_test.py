from pathlib import Path
import hashlib,json,subprocess,sys,unittest,zipfile
ROOT=Path(__file__).resolve().parents[1]
class Packages(unittest.TestCase):
    def test_reproducible_complete_no_unwanted_payload(self):
        for local in ((False,) if '--source-only' in sys.argv else (False,True)):
            suffix='local' if local else 'source';args=[sys.executable,str(ROOT/'tools/package.py')]+(['--local-data'] if local else [])
            subprocess.run(args,check=True,capture_output=True)
            path=ROOT/'dist'/f'AsTheCrowFlies-0.1.0-dev-{suffix}.zip';first=hashlib.sha256(path.read_bytes()).hexdigest()
            subprocess.run(args,check=True,capture_output=True);self.assertEqual(first,hashlib.sha256(path.read_bytes()).hexdigest())
            with zipfile.ZipFile(path) as z:
                names=z.namelist();self.assertTrue(all(n.startswith('AsTheCrowFlies/') and '..' not in n for n in names))
                self.assertFalse(any(n.endswith(('.bin','.exe','.db2','.py','.cjs')) for n in names))
                for line in z.read('AsTheCrowFlies/AsTheCrowFlies.toc').decode().splitlines():
                    if line and not line.startswith('#'):self.assertIn('AsTheCrowFlies/'+line,names)
                taxi=z.read('AsTheCrowFlies/Data/Taxi.lua')
                self.assertEqual(b'N.Data.LocalTaxi=' in taxi,local)
                self.assertIn('AsTheCrowFlies/docs/COVERAGE.md',names)
                for media in ('eagle','arrow','surface','cog'):self.assertIn(f'AsTheCrowFlies/Media/{media}.tga',names)
if __name__=='__main__':unittest.main(argv=[sys.argv[0]])
