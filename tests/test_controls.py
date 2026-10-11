"""Developer tests for custom Lua; installation does not require Python/lupa."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
for path in (root/'patches').glob('*.lua'):
 ok,error=lua.eval('function(s) local f,e=loadstring(s);return f~=nil,e end')(path.read_text(encoding='utf8'))
 assert ok,(path.name,error)
lua.execute('''
NI={HW={BUTTON_WHEEL=3,PAGE_CONTROL=4,PAGE_BROWSE=5,PAGE_SAVE_DIALOG=6,PAD_MODE_NONE=0},
DATA={StateHelper={},ChainAccess={},ParameterAccess={}}}
MaschineMikroMK3={};shift=false;erase=false;removed=0;pageID=4
layer={};slot={};slots={}
NI.DATA.StateHelper.getFocusMixingLayer=function() return layer end
NI.DATA.StateHelper.getFocusSlot=function() return slot end
NI.DATA.StateHelper.getFocusChainSlots=function() return slots end
NI.DATA.ChainAccess.removeSlot=function(app,s,v) assert(s==slots and v==slot);removed=removed+1 end
NI.DATA.ParameterAccess.setBoolParameterNoUndo=function(app,p,v) p.value=v end
mode={value=true};stack={getTopPage=function() return pageID end,pushPage=function(self,p) pageID=p end,popPage=function() pageID=4 end}
NHLController={getPageStack=function() return stack end,updateLEDs=function() end,setPadMode=function() end,
getContext=function() return {mikroMk3=function() return {getPluginPageIsEditingParametersParameter=function() return mode end} end} end}
results={};App={getHardwareInputManager=function() return {onButton=function(self,r) table.insert(results,r) end} end,
getGenericBusyMessage=function() return "Busy","Wait" end}
BrowseHelper={getResultListFocusItem=function() return 0 end}
MaschineMikroMK3.isShiftPressed=function() return shift end
MaschineMikroMK3.isErasePressed=function() return erase end
MaschineMikroMK3.closeBusyDialog=function() end
MaschineMikroMK3.updatePageSync=function() end
''')
lua.execute((root/'patches/chain-actions.lua').read_text(encoding='utf8'))
lua.execute('''
ctrl=setmetatable({}, {__index=MaschineMikroMK3})
for _,combo in ipairs({{false,false},{true,false},{false,true},{true,true}}) do
 shift=combo[1];erase=combo[2]
 ctrl:captureChainAction(3,true);ctrl:captureChainAction(3,false);ctrl:runChainAction()
 assert(removed==(shift and erase and 1 or 0))
end
assert(mode.value==false)
ctrl:runChainAction();assert(removed==1)
screen={}
for _,name in ipairs({"setTopRowText","setBottomRowText","setTopRowTextAttribute","setBottomRowTextAttribute"}) do screen[name]=function(self) return self end end
PageMikroMK3={__init=function(self,name,c) self.Controller=c;self.Screen=screen end,onShow=function(self,show) if show then self:updateScreen() end end}
require=function(name) if string.find(name,"classy") then return function() return {} end end end
''')
lua.execute((root/'patches/save-dialog.lua').read_text(encoding='utf8'))
lua.execute((root/'patches/dialog-page.lua').read_text(encoding='utf8'))
lua.execute('''
dialog=setmetatable({}, {__index=BusyPageMikroMK3});dialog:__init(ctrl)
for i,result in ipairs({0,2,3}) do
 ctrl:openDialogSave();dialog:onShow(true)
 for j=2,i do dialog:onWheelEvent(1) end
 dialog:onSwitchEvent(3,false);assert(#results==i-1)
 dialog:onSwitchEvent(3,true);assert(#results==i-1)
 dialog:onSwitchEvent(3,false);assert(results[i]==result)
 dialog:onSwitchEvent(3,true);dialog:onSwitchEvent(3,false);assert(#results==i)
 ctrl:closeBusyDialog()
end
dialog:onShow(true);dialog:onWheelEvent(1);dialog:onSwitchEvent(3,true);dialog:onSwitchEvent(3,false);assert(#results==3)
''')
print('Lua syntax, required Shift+Erase combination, single removal, Save result mapping and confirmation guards passed.')
