"""Run real Lua 5.1 via Lupa, not a translated implementation."""
from pathlib import Path
import sys,time,json
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.work/pydeps'))
from lupa.lua51 import LuaRuntime
start=time.perf_counter()
for filename in ['model_test.lua','runtime_test.lua']:
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.globals().ROOT=str(ROOT).replace('\\','/')
    lua.execute((ROOT/'tests'/filename).read_text(encoding='utf-8'))
print(f'Lua 5.1 suites passed in {time.perf_counter()-start:.3f}s')
