from pathlib import Path
root=Path(__file__).resolve().parents[1]
fixture=(root/'tests/channel_fixture.py').read_text()
exec(compile(fixture,'route-fixture','exec'),globals())
lua.execute('''
NI.HW.PAGE_BROWSE=40;NI.HW.BUTTON_LOCK=7
NI.HW.BUTTON_ARROW_LEFT=104;NI.HW.BUTTON_ARROW_RIGHT=105
BrowserPageMikroMK3={onControllerTimer=function()end}
NI.HW.JOGWHEEL_MODE_CUSTOM=100
jogmode=0
NHLController.getJogWheelMode=function()return jogmode end
NHLController.setJogWheelMode=function(self,v)jogmode=v end
NI.DATA.ParameterSnapshotsAccess={isSnapshotActiveHW=function()return false end}
''')
lua.execute((root/'runtime/tag-navigation.lua').read_text())
lua.execute((root/'runtime/load-gesture.lua').read_text())
lua.execute('''
PluginPageMikroMK3.updateScreenFocusModule=function()end
plugin=setmetatable({Name="PluginPageMikroMK3",Screen=screen},{__index=PluginPageMikroMK3})
c=setmetatable({ActivePage=plugin,isShiftPressed=function()return controller.shift end,isErasePressed=function()return controller.erase end,isButtonPressed=function()return false end},{__index=MaschineMikroMK3})
plugin.Controller=c;controller.erase=false;mode.value=false;macro.Screen=screen
names={[0]={'Amp','Synth'},[1]={'Cabinet','Drive'},[2]={'Clean','Warm'}}
counts={[0]=2,[1]=2,[2]=2};selected={[0]=0,[1]=-1,[2]=-1}
pending=nil;busy=false
attrs={getActiveAttributeCount=function(self,a)return counts[a]end,
getActiveIndexOfFocusAttribute=function(self,a)return selected[a]end,
getActiveAttributeName=function(self,a,i)assert(i>=0 and i<counts[a]);return names[a][i+1]end}
App.getDatabaseFrontend=function()return {getBrowserModel=function()return {getAttributesModel=function()return attrs end}end}end
BrowseHelper={getFileType=function()return 9 end,supportsModes=function()return true end,isBusy=function()return busy end,
setAttributeIndex=function(a,i)pending={attr=a,index=i,ticks=0};busy=true end,
forceCacheRefresh=function()end,
updateCacheTimer=function()
if pending then pending.ticks=pending.ticks+1
if pending.ticks>=2 then selected[pending.attr]=pending.index
if pending.attr==0 then counts[1]=pending.index==0 and 2 or 0 end
pending=nil;busy=false end end end}
stack.top=40;controller.shift=true
c:captureChainAction(2,true);c:captureChainAction(2,false);c:onControllerTimer()
assert(c.TagState.Attr==2 and c.TagState.Cursor==-1)
assert(jogmode==100)
function settle()c:onControllerTimer();c:onControllerTimer()end
function clicktag(back)
controller.shift=back;c:onSwitchEvent(2,true);c:onSwitchEvent(2,false);c:onControllerTimer();settle()
end
c:onWheelEvent(0,1);c:onControllerTimer();settle()
assert(selected[2]==0 and c.TagState.Cursor==0)
clicktag(false);assert(c.TagState==nil and stack.top==40 and selected[2]==0)
-- Clicking the selected entry toggles it off and returns to results.
c:openTags();assert(c.TagState.EntryName=='Clean')
clicktag(false);assert(selected[2]==-1 and c.TagState==nil)
-- Back climbs Characters -> Subtypes -> Types.
c:openTags();clicktag(true);assert(c.TagState.Attr==1)
clicktag(true);assert(c.TagState.Attr==0)
c:onWheelEvent(0,1);c:onControllerTimer();settle()
assert(selected[0]==1 and c.TagState.Cursor==1)
clicktag(false);assert(c.TagState.Attr==2)
clicktag(false);assert(c.TagState==nil and stack.top==40)
-- Type with children enters Subtypes, then Characters.
c:openTags();clicktag(true);assert(c.TagState.Attr==0)
c:onWheelEvent(0,-1);c:onControllerTimer();settle()
assert(selected[0]==0)
clicktag(false);assert(c.TagState.Attr==1)
clicktag(false);assert(c.TagState.Attr==2)
clicktag(false);assert(c.TagState==nil)
c:openTags();clicktag(true);clicktag(true);assert(c.TagState.Attr==0)
clicktag(false);assert(selected[0]==0 and c.TagState.Attr==1)
clicktag(false);clicktag(false);assert(c.TagState==nil)
c:openTags();c:openDialogSave();assert(c.TagState==nil and stack.top==71 and jogmode==0)

''')
lua.execute((root/'patches'/'browser-navigation.lua').read_text())
lua.execute('''
resourceSteps=0;productSteps=0
BrowseHelper.hasPrevNextFileType=function()return true,true end
BrowseHelper.selectPrevOrNextVisibleFileType=function(right)resourceSteps=resourceSteps+(right and 1 or -1)end
BrowseHelper.offsetBankChain=function(bank,delta)productSteps=productSteps+delta end
macro.onSwitchEvent=function(self,id,v)
assert(stack.top==40)
BrowserPageMikroMK3.onSwitchEvent({Controller=c},id,v)
end
stack.top=40;controller.shift=false
for _,id in ipairs({4,5,104,105}) do
c:openTags();c.TagDelta=1;c.TagClick={Back=false}
c:onSwitchEvent(id,true)
assert(c.TagState==nil and c.TagDelta==nil and c.TagClick==nil and stack.top==40 and jogmode==0)
c:onSwitchEvent(id,false)
end
assert(resourceSteps==0 and productSteps==0)
c:openTags();c:onSwitchEvent(105,true);c:onSwitchEvent(105,false)
assert(resourceSteps==1)
c:openTags();controller.shift=true;c:onSwitchEvent(104,true);c:onSwitchEvent(104,false)
assert(productSteps==-1 and resourceSteps==1)
controller.shift=false
c:onSwitchEvent(5,true);c:onSwitchEvent(5,false);assert(resourceSteps==2)
-- LEDs match the ordinary browser's resource/product boundaries while in tags.
navigate.Controller=c
BrowseHelper.hasPrevNextFileType=function()return false,true end
c:openTags();c:updateLEDs();assert(leds[1]==false and leds[2]==true)
BrowseHelper.getProductCount=function()return 3 end
BrowseHelper.getFocusProductIndex=function()return 2 end
controller.shift=true;c:updateLEDs();assert(leds[1]==true and leds[2]==false)
controller.shift=false

''')
print('PASS tag-arrow resource routing, aliases, release, Shift products, and results handoff')

print('PASS assembled loader, Characters-first Shift back, live native selection/name access, toggle-off, subtype parent/child routes, All and Save handoff')
