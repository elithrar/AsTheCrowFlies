from pathlib import Path
import copy,importlib.util,json,unittest
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('build_data',ROOT/'tools/build_data.py');build=importlib.util.module_from_spec(spec);spec.loader.exec_module(build)
class DataTests(unittest.TestCase):
    def tables(self):
        return {n:json.loads((ROOT/'.work/tables'/f'{n}.json').read_text(encoding='utf-8')) for n in ['TaxiNodes','TaxiPath','TaxiPathNode']}
    def test_exact_tables_determinism_and_references(self):
        a,excluded=build.build(self.tables());b,_=build.build(self.tables());self.assertEqual(build.lua(a),build.lua(b));self.assertEqual(len(a['nodes']),98);self.assertEqual(len(a['edges']),302)
        for e in a['edges']:
            self.assertIn(e['from'],a['nodes']);self.assertIn(e['to'],a['nodes']);self.assertGreaterEqual(e['distance'],0);self.assertGreater(len(e['points']),1)
        self.assertEqual(len(excluded),26)
    def test_unknown_schema_and_duplicate_rejected(self):
        t=self.tables();t['TaxiNodes']['layoutHash']='UNKNOWN'
        with self.assertRaises(ValueError):build.build(t)
        t=self.tables();t['TaxiNodes']['rows'].append(t['TaxiNodes']['rows'][0]);t['TaxiNodes']['sourceRowCount']+=1
        with self.assertRaises(ValueError):build.build(t)
    def test_bad_geometry_never_becomes_connectivity(self):
        t=self.tables();path=t['TaxiPath']['rows'][0];target=path['ID'];t['TaxiPathNode']['rows']=[p for p in t['TaxiPathNode']['rows'] if not(p['PathID']==target and p['NodeIndex']==1)];t['TaxiPathNode']['sourceRowCount']=len(t['TaxiPathNode']['rows'])
        data,excluded=build.build(t);self.assertNotIn(target,[e['id'] for e in data['edges']]);self.assertIn({'id':target,'reason':'incomplete spline'},excluded)
    def test_raw_files_match_provenance(self):
        import hashlib
        manifest=json.loads((ROOT/'.work/extraction.json').read_text())
        self.assertEqual(manifest['build'],'1.60.1.70338');self.assertFalse(manifest['tables']['AreaTable']['readable'])
        for row in manifest['tables'].values():
            if row['readable']:self.assertEqual(hashlib.sha256((ROOT/'.work/raw'/f"{row['fileDataID']}.bin").read_bytes()).hexdigest(),row['sha256'])
if __name__=='__main__':unittest.main()
