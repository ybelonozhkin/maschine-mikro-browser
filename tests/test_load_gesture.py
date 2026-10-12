from pathlib import Path
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
NI={HW={BUTTON_WHEEL=1,BUTTON_LOCK=2,PAGE_BROWSE=3,PAGE_CONTROL=4},DB3={FILE_TYPE_EFFECT=5,FILE_TYPE_INSTRUMENT=6,FILE_TYPE_ONESHOT_SAMPLE=7,FILE_TYPE_LOOP_SAMPLE=8},DATA={LEVEL_TAB_SOUND=9,StateHelper={},ParameterSnapshotsAccess={}}}
page=3;shift=true;lock=false;erase=false;snapshot=false;filetype=5;layer={};slot={};song={getLevelTab=function()return 9 end}
NHLController={getPageStack=function()return {getTopPage=function()return page end}end}
App={getDatabaseFrontend=function()return {getBrowserModel=function()return {getSelectedFileType=function()return filetype end}end}end}
BrowseHelper={isBusy=function()return false end,getResultListSize=function()return 2 end,getResultListFocusItem=function()return 0 end}
NI.DATA.StateHelper.getFocusSong=function()return song end
NI.DATA.StateHelper.getFocusMixingLayer=function()return layer end
NI.DATA.StateHelper.getFocusSlot=function()return slot end
NI.DATA.ParameterSnapshotsAccess.isSnapshotActiveHW=function()return snapshot end
MaschineMikroMK3={isShiftPressed=function()return shift end,isErasePressed=function()return erase end,isButtonPressed=function(self,id)return id==2 and lock end,
onSwitchEvent=function(self,id,v)if id==2 then lock=v else self:captureChainAction(id,v)end end,
onControllerTimer=function(self)if self.ChainAction and self.ChainAction.Ready then self.completed=self.ChainAction.Kind;self.ChainAction=nil end end}
io.open=function()return nil end
''')
lua.execute((root/'patches'/'chain-actions.lua').read_text(encoding='utf8'))
lua.execute((root/'runtime/load-gesture.lua').read_text(encoding='utf8'))
lua.execute('''
c=setmetatable({}, {__index=MaschineMikroMK3})
c:onControllerTimer();assert(c.LoadSnapshotPrevious==false)
c:onSwitchEvent(2,true);c:onSwitchEvent(1,true)
assert(c.ChainAction.Kind=='ADD FX' and not c.LoadLockBlocked)
lock=false;c:onSwitchEvent(1,false);c:onControllerTimer();assert(c.completed=='ADD FX')
c:onSwitchEvent(2,false);c.completed=nil
filetype=7;c:onSwitchEvent(2,true);c:onSwitchEvent(1,true);c:onSwitchEvent(1,false);c:onControllerTimer();assert(c.completed=='KEEP FX')
c:onSwitchEvent(2,false);c.completed=nil;c:onSwitchEvent(1,true);c:onSwitchEvent(1,false)
assert(c.TagOpen and c.ChainAction==nil)
c.TagOpen=nil
-- Simulate a native Lock change before the Lua callback.
c:onControllerTimer();snapshot=true;c:onSwitchEvent(2,true);c:onSwitchEvent(1,true)
assert(c.LoadLockBlocked and c.ChainAction==nil)
c:onSwitchEvent(2,false)
page=4;erase=true;c:onSwitchEvent(1,true);assert(c.ChainAction.Kind=='REMOVE')
''')
print('PASS Shift+LOCK FX/source capture, release confirmation, plain Shift-click back, false snapshot state, native Lock side-effect rejection, removal unchanged')
