from pathlib import Path
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
NI={HW={BUTTON_CONTROL=1,BUTTON_WHEEL=2,BUTTON_WHEEL_TOUCH=3,BUTTON_LEFT=4,BUTTON_RIGHT=5},DATA={LEVEL_TAB_SONG=0,LEVEL_TAB_GROUP=1,LEVEL_TAB_SOUND=2,StateHelper={},SongAccess={},ParameterAccess={},ChainAccess={}}}
PageMikroMK3={onShow=function() end};App={}
require=function(name) if name:find('classy') then return function(name,base) return setmetatable({}, {__index=base}) end end end
mode={value=false,getValue=function(self) return self.value end}
NHLController={getContext=function() return {mikroMk3=function() return {getPluginPageIsEditingParametersParameter=function() return mode end} end} end}
NI.DATA.ParameterAccess.setBoolParameterNoUndo=function(app,p,v) p.value=v end
song={level=2,getLevelTab=function(self) return self.level end}
NI.DATA.StateHelper.getFocusSong=function() return song end
layer={};slots={};slot={};focus=slot
NI.DATA.StateHelper.getFocusSlot=function() return focus end
NI.DATA.StateHelper.getFocusMixingLayer=function() return layer end
NI.DATA.StateHelper.getFocusChainSlots=function() return slots end
restores=0
NI.DATA.ChainAccess.setFocusSlot=function(app,s,v,b) assert(s==slots and v==slot);focus=v;restores=restores+1 end
NI.DATA.SongAccess.setLevelTab=function(app,s,v) s.level=v end
controller={shift=false,erase=false,isShiftPressed=function(self) return self.shift end,isErasePressed=function(self) return self.erase end}
screen=setmetatable({}, {__index=function() return function(self) return self end end})
io.open=function() return nil end
''')
lua.execute("""
PluginPageMikroMK3={onShow=function()end,updateScreen=function()end,onSwitchEvent=function()end,onWheelEvent=function()end,onControllerTimer=function()end}
""")
lua.execute((root/'runtime/plugin-navigation.lua').read_text())
