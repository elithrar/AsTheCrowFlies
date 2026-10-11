"""Read installed QuestieDB; print aggregate coverage only, never write NPC payload.

Measures the baked base artifact, not runtime corrections, C_Map projection,
eligibility, or observed in-game placement. Uses the actual Lua classifier.
"""
from pathlib import Path
import argparse
import base64
import collections
import hashlib
import json
import re
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.work/pydeps'))
from lupa.lua51 import LuaRuntime


def cbor(data):
    cursor = 0

    def read():
        nonlocal cursor
        initial = data[cursor]
        cursor += 1
        major, number = initial >> 5, initial & 31
        if major == 7:
            if number in (20, 21, 22):
                return {20: False, 21: True, 22: None}[number]
            if number in (25, 26, 27):
                size, fmt = {25: (2, '>e'), 26: (4, '>f'), 27: (8, '>d')}[number]
                value = struct.unpack(fmt, data[cursor:cursor + size])[0]
                cursor += size
                return value
        if number >= 24:
            size = {24: 1, 25: 2, 26: 4, 27: 8}[number]
            number = int.from_bytes(data[cursor:cursor + size], 'big')
            cursor += size
        if major == 0:
            return number
        if major == 1:
            return -number - 1
        if major in (2, 3):
            value = data[cursor:cursor + number]
            cursor += number
            return value.decode('utf-8')
        if major == 4:
            return [read() for _ in range(number)]
        if major == 5:
            return {read(): read() for _ in range(number)}
        raise ValueError('Unsupported CBOR shape')

    value = read()
    assert cursor == len(data), 'Trailing CBOR data'
    return value


def measure(path):
    payload = path.read_bytes()
    metadata = dict(re.findall(r'^## ([^:]+): (.*)$', payload.decode('utf-8').replace('\r', ''), re.M))
    assert metadata.get('X-Flavor') == 'Forever', 'Refusing another client flavor'

    def stored(key):
        value = metadata[key]
        if re.fullmatch(r'~\d+~', value):
            value = ''.join(metadata[key + '-' + str(i)] for i in range(1, int(value[1:-1]) + 1))
        return cbor(base64.b64decode(value, validate=True))

    lua = LuaRuntime(unpack_returned_tuples=True)
    namespace = lua.table(Adapter=lua.table())
    for filename in ('Model.lua', 'Providers.lua'):
        lua.execute((ROOT / 'AsTheCrowFlies' / filename).read_text(encoding='utf-8'), 'AsTheCrowFlies', namespace)
    classify = namespace.Providers.Classify
    categories, friendly_categories, spawn_counts = (collections.Counter() for _ in range(3))
    classes, professions, flags_count, missing_spawns = (collections.Counter() for _ in range(4))
    total = 0
    for key in metadata:
        if not re.fullmatch(r'X-Npc-\d+-S', key):
            continue
        total += 1
        row = stored(key)
        if isinstance(row, list):
            row = dict(enumerate(row, 1))
        flags = row.get(15, 0)
        for name, mask in (('trainer', 16), ('auctioneer', 4096)):
            if flags & mask:
                flags_count[name] += 1
        starts = lua.table(1) if row.get('p', 0) & 512 else None
        ends = lua.table(1) if row.get('p', 0) & 1024 else None
        category, role, player_class, profession = classify(row.get(14), flags, starts, ends)
        if not category:
            continue
        categories[category] += 1
        if row.get(13) in ('A', 'H', 'AH'):
            friendly_categories[category] += 1
        if player_class:
            classes[player_class] += 1
        if profession:
            professions[profession] += 1
        spawn_key = key[:-1] + '7'
        if spawn_key in metadata:
            spawns = stored(spawn_key)
            values = spawns.values() if isinstance(spawns, dict) else spawns
            spawn_counts[category] += sum(len(v) for v in values)
        else:
            missing_spawns[category] += 1
    return {
        'scope': 'Installed Forever baked base artifact; before runtime corrections, map projection, and eligibility checks',
        'providerVersion': metadata.get('Version'),
        'providerCommit': metadata.get('X-BUILD-COMMIT'),
        'tocSHA256': hashlib.sha256(payload).hexdigest(),
        'classifierSHA256': hashlib.sha256((ROOT / 'AsTheCrowFlies/Providers.lua').read_bytes()).hexdigest(),
        'npcScalarRows': total,
        'serviceFlags': flags_count,
        'classifiedNPCs': categories,
        'friendlyClassifiedNPCs': friendly_categories,
        'baseSpawnRecords': spawn_counts,
        'npcIDsWithoutSpawnField': missing_spawns,
        'classNPCs': classes,
        'professionNPCs': professions,
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--toc', type=Path, default=Path(r'C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\QuestieDB\QuestieDB_Forever.toc'))
    args = parser.parse_args()
    print(json.dumps(measure(args.toc), indent=2, sort_keys=True))
