"""Check the packaged runtime, Lua syntax and bootstrap path resolution."""
from pathlib import Path
import hashlib,json
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
config=json.loads((root/'patches/compatibility.json').read_text())
assert config['version']=='0.3.0'
for name,expected in config['runtime_files'].items():
    assert hashlib.sha256((root/'runtime'/name).read_bytes()).hexdigest()==expected,name
lua=LuaRuntime(unpack_returned_tuples=True)
parse=lua.eval('function(s) local f,e=loadstring(s);return f~=nil,e end')
for folder in ['patches','runtime']:
    for path in (root/folder).glob('*.lua'):
        ok,error=parse(path.read_text(encoding='utf-8-sig'));assert ok,(path.name,error)
loader=(root/'runtime/runtime.lua').read_text()
for directory in ['C:/ProgramData/MaschineMikroBrowser/0.3.0','D:\\Data with spaces\\MaschineMikroBrowser\\0.3.0']:
    lua.execute('seen={};dofile=function(path)table.insert(seen,path)end')
    lua.globals().source_name='@'+directory+'/runtime.lua'
    lua.execute('debug.getinfo=function()return {source=source_name}end')
    lua.execute(loader)
    assert lua.globals().MaschineMikroBrowserRuntimePath==directory
    seen=lua.globals().seen
    assert len(seen)==5
    assert seen[1]==directory+'/plugin-navigation.lua'
    assert seen[5]==directory+'/bridge-loader.lua'
print('PASS runtime hashes, Lua 5.1 syntax and relocated loader paths')
