"""Read-only audit of installed Forever provider records and private exact-build maps.

Requires ATCF_CLIENT_FIXTURES pointing to the existing extraction .work directory.
This checks source consistency and the real indexing code, not live NPC placement.
No provider payload is written or bundled. Without local fixtures these tests skip.
"""
from pathlib import Path
import base64
import hashlib
import json
import math
import os
import re
import unittest

from measure_provider import ROOT, LuaRuntime, cbor

GAME = Path(r'C:\Program Files (x86)\World of Warcraft')
PROVIDER = GAME / '_classic_beta_/Interface/AddOns/QuestieDB'
FIXTURES = Path(os.environ.get('ATCF_CLIENT_FIXTURES', ROOT / '.work'))


class TransmogrifierDataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        toc = PROVIDER / 'QuestieDB_Forever.toc'
        if not toc.exists() or not (FIXTURES / 'tables/UiMap.json').exists():
            raise unittest.SkipTest('Matching installed Forever provider and private map fixtures required')
        cls.provenance = json.loads((ROOT / 'docs/data-provenance.json').read_text(encoding='utf-8'))
        cls.evidence = cls.provenance['npcServices']
        cls.metadata = dict(re.findall(r'^## ([^:]+): (.*)$', toc.read_text(encoding='utf-8').replace('\r', ''), re.M))
        cls.toc_hash = hashlib.sha256(toc.read_bytes()).hexdigest()
        cls.lua = LuaRuntime(unpack_returned_tuples=True)
        cls.namespace = cls.lua.table(Adapter=cls.lua.table())
        for filename in ('Model.lua', 'Data/Registry.lua', 'Providers.lua'):
            cls.lua.execute((ROOT / 'AsTheCrowFlies' / filename).read_text(encoding='utf-8'), 'AsTheCrowFlies', cls.namespace)

    def stored(self, key):
        value = self.metadata[key]
        if re.fullmatch(r'~\d+~', value):
            value = ''.join(self.metadata[key + '-' + str(i)] for i in range(1, int(value[1:-1]) + 1))
        return cbor(base64.b64decode(value, validate=True))

    def scalar(self, npc_id):
        row = self.stored(f'X-Npc-{npc_id}-S')
        return dict(enumerate(row, 1)) if isinstance(row, list) else row

    def test_evidence_is_bound_to_the_installed_product_and_provider(self):
        self.assertEqual(self.metadata['X-Flavor'], 'Forever')
        self.assertEqual(self.metadata['X-BUILD-COMMIT'], self.evidence['providerCommit'])
        self.assertEqual(self.toc_hash, self.evidence['providerTocSHA256'])
        lines = (GAME / '.build.info').read_text().splitlines()
        keys = [key.split('!')[0] for key in lines[0].split('|')]
        installed = next(dict(zip(keys, line.split('|'))) for line in lines[1:] if line.split('|')[-1] == 'wow_classic_beta')
        self.assertEqual(installed['Version'], self.provenance['build'])
        self.assertEqual(installed['Build Key'], self.provenance['buildKey'])
        self.assertFalse(self.evidence['exactBuildSpawnsVerified'])

    def test_provider_maps_agree_with_exact_build_assignments(self):
        tables = {}
        for name in ('UiMap', 'UiMapAssignment'):
            table = json.loads((FIXTURES / 'tables' / (name + '.json')).read_text(encoding='utf-8'))
            source = self.provenance['tables'][name]
            self.assertEqual(table['sourceSha256'], source['sha256'])
            self.assertEqual(hashlib.sha256((FIXTURES / 'raw' / (str(source['fileDataID']) + '.bin')).read_bytes()).hexdigest(), source['sha256'])
            self.assertEqual(table['layoutHash'], self.provenance['decoded'][name]['layoutHash'])
            tables[name] = table['rows']
        base = (PROVIDER / 'support/Zones/areaIdToUiMapId.lua').read_text(encoding='utf-8')
        override = (PROVIDER / 'support/Forever/Zones/areaIdToUiMapId.lua').read_text(encoding='utf-8')
        serialized = {}
        for source in (base, override):
            serialized.update(dict(re.findall(r'ZoneDB\.private\.(areaIdToUiMapId(?:Override)?)\s*=\s*\[\[(return\s*\{.*?\})\]\]', source, re.S)))
        registry = {}
        for key in ('areaIdToUiMapId', 'areaIdToUiMapIdOverride'):
            registry.update(dict(self.namespace.Providers.MapRegistry(serialized[key]).items()))
        for entry in self.evidence['entries']:
            self.assertEqual(registry[entry['areaID']], entry['uiMapID'])
            self.assertTrue(any(row['ID'] == entry['uiMapID'] and row['Name_lang'] == entry['zone'] for row in tables['UiMap']))
            self.assertTrue(any(row['AreaID'] == entry['areaID'] and row['UiMapID'] == entry['uiMapID'] and row['MapID'] == entry['worldMapID'] for row in tables['UiMapAssignment']))

    def test_real_provider_rows_become_faction_filtered_searchable_destinations(self):
        records, ids, zones = {}, [], {}
        flags = {'Alliance': 'A', 'Horde': 'H', 'Neutral': 'AH'}
        for entry in self.evidence['entries']:
            npc_id = entry['npcID']
            row = self.scalar(npc_id)
            self.assertEqual(row[1], entry['name'])
            self.assertEqual(row[13], flags[entry['faction']])
            self.assertFalse(row.get(14))
            self.assertFalse(row.get(15))
            spawns = self.stored(f'X-Npc-{npc_id}-7')
            self.assertEqual(set(spawns), {entry['areaID']})
            self.assertEqual(sum(len(positions) for positions in spawns.values()), entry['providerSpawnRecords'])
            for positions in spawns.values():
                for point in positions:
                    self.assertTrue(all(isinstance(v, (int, float)) and math.isfinite(v) and 0 <= v <= 100 for v in point[:2]))
            records[npc_id] = dict(name=row[1], friendlyToFaction=row[13], spawns=spawns)
            ids.append(npc_id)
            zones[entry['areaID']] = entry['uiMapID']
        self.lua.globals().records = self.lua.table_from(records, recursive=True)
        self.lua.globals().ids = self.lua.table_from(ids)
        self.lua.globals().zones = self.lua.table_from(zones)
        self.lua.execute('''
            local N=...
            N.Adapter.Call=function(fn,...) if type(fn)=='function' then return fn(...) end end
            -- Synthetic world axes only exercise indexing and normalized map coordinates.
            N.Adapter.FromMap=function(map,x,y) return {map=0,uiMapID=map,x=x*1000,y=y*1000,mx=x,my=y} end
            LibQuestieDB={flavor={name='Forever'},RequireContract=function(v) return v==3 end,
                Support={Get=function() return {private={areaIdToUiMapId=zones}} end},
                Npc={GetAllIds=function() return ids end,Get=function(id,key) return records[id][key] end,GetRaw=function() end}}
            local state=assert(N.Providers.Connect())
            while not N.Providers.Step(state,1) do end
            assert(#state.items==6 and state.counts.unmapped==0)
            assert(#N.Model.Search(state.items,'transmog',{},{faction='Alliance'})==5)
            assert(#N.Model.Search(state.items,'transmogrifier',{},{faction='Horde'})==1)
            for _,id in ipairs(ids) do
                local row=records[id]
                local faction=row.friendlyToFaction=='H' and 'Horde' or 'Alliance'
                local matches=N.Model.Search(state.items,row.name,{categories={transmog=true}},{faction=faction})
                assert(#matches>0 and matches[1].npcID==id)
            end
        ''', self.namespace)
        for npc_id in (1745, 10181, 14182):
            row = self.scalar(npc_id)
            self.assertTrue(row[15] & 268435456)
            self.assertNotEqual(self.namespace.Providers.Classify(row.get(14), row[15], None, None, npc_id)[0], 'transmog')
        self.assertNotIn(273057, dict(self.namespace.Data.npcServices.items()))
        self.assertNotIn('X-Npc-273057-7', self.metadata)


if __name__ == '__main__':
    unittest.main()
