from pathlib import Path
import runpy
root=Path(__file__).resolve().parents[1]
lua=runpy.run_path(str(root/'tests/navigation_fixture.py'))['lua']
lua.execute('''
NI.HW.PAGE_CONTROL=10;NI.HW.PAGE_MACRO=20;NI.HW.PAGE_NAVIGATE=30
NI.HW.LED_LEFT=1;NI.HW.LED_RIGHT=2
leds={};nativeLEDs=0
LEDHelper={setLEDOnOff=function(id,v) leds[id]=v end}
modules={value=true};group={value=0,getValue=function(self)return self.value end}
workspace={getModulesVisibleParameter=function()return modules end,getPageGroupParameter=function()return group end}
NI.DATA.ParameterAccess.setEnumParameterNoUndo=function(app,p,v)p.value=v end
App.getWorkspace=function()return workspace end
stack={top=10,getTopPage=function(self)return self.top end,popToBottomPage=function(self)self.top=10 end,pushPage=function(self,v)self.top=v end,popPage=function(self)self.top=20 end}
NHLController.getPageStack=function()return stack end
macro={Name="MacroPageMikroMK3",onShow=function()end,onControllerTimer=function()end}
navigate={Name="NavigatePageMikroMK3",Screen=screen,onShow=function()end,onControllerTimer=function()end,updateScreen=function()end}
MaschineMikroMK3={
updateLEDs=function(self)nativeLEDs=nativeLEDs+1;leds[1]='native';leds[2]='native' end,
openDialogSave=function(self)stack.top=71;self.nativeSave=true end,
captureChainAction=function()end,
onWheelEvent=function()end,
onSwitchEvent=function(self,id,v)if self.ActivePage.onSwitchEvent then self.ActivePage:onSwitchEvent(id,v)end end,
onControllerTimer=function(self) self:updatePageSync(false);self.ActivePage:onControllerTimer()end,
updatePageSync=function(self,force)
local target=stack.top==10 and plugin or (stack.top==30 and navigate or macro)
if self.ActivePage~=target or force then
if self.ActivePage then self.ActivePage:onShow(false)end
self.ActivePage=target;target:onShow(true)
end
end}
local setter=NI.DATA.ParameterAccess.setBoolParameterNoUndo
NI.DATA.ParameterAccess.setBoolParameterNoUndo=function(app,p,v)
setter(app,p,v)
-- Critical native side effect omitted by the old tests.
if p==modules then stack.top=v and 10 or 20 end
end
''')
lua.execute((root/'runtime/channel-navigation.lua').read_text())
