-- Stage: native Channel entry and shared back route; native parameter editing.
local P=PluginPageMikroMK3
local Screen,Wheel,Apply,Show,Switch,Timer=P.updateScreen,P.onWheelEvent,P.navApply,P.onShow,P.onSwitchEvent,P.onControllerTimer
local function Trace(s)
pcall(function()local f=io.open((os.getenv("LOCALAPPDATA").."/MaschineMikroBrowser/channel-route.log"),"a")
if f then if f:seek("end")>262144 then f:close();f=io.open((os.getenv("LOCALAPPDATA").."/MaschineMikroBrowser/channel-route.log"),"w") end
if f then f:write(os.date("%H:%M:%S "),s,"\n");f:close() end end end)
end
local function Modules(v)
NI.DATA.ParameterAccess.setBoolParameterNoUndo(App,App:getWorkspace():getModulesVisibleParameter(),v)
end
local function Level()
local song=NI.DATA.StateHelper.getFocusSong(App)
for i,v in ipairs({NI.DATA.LEVEL_TAB_SONG,NI.DATA.LEVEL_TAB_GROUP,NI.DATA.LEVEL_TAB_SOUND}) do
if song and song:getLevelTab()==v then return i end end
return 3
end
function P:onShow(v)
self.RouteRoot=nil;self.RouteHeld=nil;self.RoutePending=nil;self.RouteArrow=nil
return Show(self,v)
end
function P:updateScreen()
if not self.RouteRoot then
Screen(self)
if self.NavLevel and self.RouteBranch==1 then self.Screen:setTopRowText("Channel properties") end
return
end
self.Screen:showTextInBottomRow():setTopRowIcon(""):setBottomRowIcon("")
:setTopRowText("Control"):setBottomRowText(self.RouteRoot==1 and "Channel properties" or "Plug-ins")
end
function P:onWheelEvent(v)
if not self.RouteRoot then return Wheel(self,v) end
if v~=0 then
self.RouteRoot=math.max(1,math.min(2,self.RouteRoot+(v>0 and 1 or -1)))
self.Controller.ChannelMenu={Stage="root",Index=self.RouteRoot};Modules(self.RouteRoot==2)
self.Controller:updatePageSync(true)
end
end
function P:navApply(a)
if a.Back and self.NavLevel then
NI.DATA.ParameterAccess.setBoolParameterNoUndo(App,NHLController:getContext():mikroMk3():getPluginPageIsEditingParametersParameter(),false)
self.NavLevel=nil;self.RouteRoot=2;self:updateScreen();return
elseif not a.Back and self.NavLevel and self.RouteBranch==1 then
NI.DATA.ParameterAccess.setBoolParameterNoUndo(App,NHLController:getContext():mikroMk3():getPluginPageIsEditingParametersParameter(),false)
self.NavLevel=nil;Modules(false);Trace("enter channel from levels");return
end
return Apply(self,a)
end
function P:onSwitchEvent(id,v)
if id==NI.HW.BUTTON_CONTROL and v then self.RouteRoot=nil;self.RouteBranch=nil;self.RoutePending=nil;self.RouteHeld=nil;self.RouteArrow=nil;Modules(true) end
if self.RouteRoot then
if id==NI.HW.BUTTON_WHEEL and not self.Controller:isErasePressed() then
if v then self.RouteHeld=self.Controller:isShiftPressed()
elseif self.RouteHeld~=nil then self.RoutePending={Back=self.RouteHeld};self.RouteHeld=nil end
return
elseif id==NI.HW.BUTTON_LEFT or id==NI.HW.BUTTON_RIGHT then
if v then self.RouteArrow=id==NI.HW.BUTTON_RIGHT and 1 or -1 end
return
end
end
return Switch(self,id,v)
end
function P:onControllerTimer()
if self.RouteArrow then
local d=self.RouteArrow;self.RouteArrow=nil
if self.NavLayer==NI.DATA.StateHelper.getFocusMixingLayer(App) and self.NavSlot then NI.DATA.ChainAccess.setFocusSlot(App,self.NavSlots,self.NavSlot,false) end
self:onWheelEvent(d)
end
if self.RoutePending then
local a=self.RoutePending;self.RoutePending=nil
if not a.Back then
local branch=self.RouteRoot;self.RouteBranch=branch;self.RouteRoot=nil
if branch==1 then self.Controller.ChannelMenu={Stage="levels",Index=Level()};Modules(false)
else self.NavLevel=Level() end
end
end
if self.RouteRoot then
NI.DATA.ParameterAccess.setBoolParameterNoUndo(App,NHLController:getContext():mikroMk3():getPluginPageIsEditingParametersParameter(),false)
self.NavLayer=NI.DATA.StateHelper.getFocusMixingLayer(App);self.NavSlots=NI.DATA.StateHelper.getFocusChainSlots(App);self.NavSlot=NI.DATA.StateHelper.getFocusSlot(App)
self:updateScreen()
else Timer(self) end
end
local C=MaschineMikroMK3
local Sync,CSwitch,CTimer,Capture=C.updatePageSync,C.onSwitchEvent,C.onControllerTimer,C.captureChainAction
local Sections={"Input","Output","Groove","Macro"}
function C:renderChannelMenu()
local m=self.ChannelMenu
if not m or not self.ActivePage then return end
local names=m.Stage=="root" and {"Channel properties","Plug-ins"} or (m.Stage=="levels" and {"Master","Group","Sound"} or Sections)
self.ActivePage.Screen:showTextInBottomRow():setTopRowIcon(""):setBottomRowIcon("")
:setTopRowText(m.Stage=="root" and "Control" or (m.Stage=="levels" and "Channel properties" or "Sections")):setBottomRowText(names[m.Index])
end
function C:updatePageSync(force)
local stack=NHLController:getPageStack()
if self.ChannelMenu and (stack:getTopPage()==NI.HW.PAGE_MACRO or stack:getTopPage()==NI.HW.PAGE_CONTROL) then stack:pushPage(NI.HW.PAGE_NAVIGATE) end
local top=NHLController:getPageStack():getTopPage()
if self.ChannelMenu and top~=NI.HW.PAGE_NAVIGATE then self.ChannelMenu=nil end
if self.RouteLastPage~=top then
Trace("page "..tostring(self.RouteLastPage).." -> "..tostring(top).." control="..tostring(NI.HW.PAGE_CONTROL).." macro="..tostring(NI.HW.PAGE_MACRO))
self.RouteLastPage=top
end
Sync(self,force)
if self.ChannelMenu then
local page=self.ActivePage
if page and not page.RouteScreenWrapped then
local nativeScreen=page.updateScreen
page.updateScreen=function(p,...)
if self.ChannelMenu and self.ActivePage==p then return self:renderChannelMenu() end
if nativeScreen then return nativeScreen(p,...) end
end
local nativePad=page.onPadEvent
page.onPadEvent=function(p,...)
if self.ChannelMenu then return end
if nativePad then return nativePad(p,...) end
end
page.RouteScreenWrapped=true
end
self:renderChannelMenu()
end
end
function C:onSwitchEvent(id,v)
local top=NHLController:getPageStack():getTopPage()
if self.ChannelMenu and top==NI.HW.PAGE_NAVIGATE then
if id==NI.HW.BUTTON_WHEEL then
if v then self.MenuHeld={Back=self:isShiftPressed()}
elseif self.MenuHeld then self.MenuClick=self.MenuHeld;self.MenuHeld=nil end
elseif v and (id==NI.HW.BUTTON_LEFT or id==NI.HW.BUTTON_RIGHT) then self.MenuDelta=id==NI.HW.BUTTON_RIGHT and 1 or -1
elseif id==NI.HW.BUTTON_CONTROL and v then self.ChannelMenu=nil;Modules(true);NHLController:getPageStack():popToBottomPage()
end
end
if id==NI.HW.BUTTON_WHEEL then
Trace("wheel button page="..tostring(top).." press="..tostring(v).." shift="..tostring(self:isShiftPressed()))
if top==NI.HW.PAGE_MACRO and not self:isErasePressed() then
if v and self:isShiftPressed() then self.RouteBackHeld=true
elseif not v and self.RouteBackHeld then self.RouteBackHeld=nil;self.RouteBack=true end
end
end
return CSwitch(self,id,v)
end
local CWheel=C.onWheelEvent
function C:onWheelEvent(id,v)
if self.ChannelMenu and NHLController:getPageStack():getTopPage()==NI.HW.PAGE_NAVIGATE then
if v~=0 then self.MenuDelta=v>0 and 1 or -1 end
return
end
return CWheel(self,id,v)
end
function C:onControllerTimer()
if self.ChannelMenu then
local ok,e=pcall(function()
local m=self.ChannelMenu
if self.MenuDelta then
m.Index=math.max(1,math.min(m.Stage=="root" and 2 or (m.Stage=="levels" and 3 or 4),m.Index+self.MenuDelta));self.MenuDelta=nil
if m.Stage=="root" then Modules(m.Index==2)
elseif m.Stage=="levels" then
local song=NI.DATA.StateHelper.getFocusSong(App)
if song then NI.DATA.SongAccess.setLevelTab(App,song,({NI.DATA.LEVEL_TAB_SONG,NI.DATA.LEVEL_TAB_GROUP,NI.DATA.LEVEL_TAB_SOUND})[m.Index]) end
else NI.DATA.ParameterAccess.setEnumParameterNoUndo(App,App:getWorkspace():getPageGroupParameter(),m.Index-1) end
Trace("menu "..m.Stage.." index="..tostring(m.Index))
end
if self.MenuClick then
local a=self.MenuClick;self.MenuClick=nil
Trace("menu click "..m.Stage.." back="..tostring(a.Back))
if a.Back then
if m.Stage=="sections" then m.Stage="levels";m.Index=Level()
elseif m.Stage=="levels" then m.Stage="root";m.Index=1
else
self.ChannelMenu=nil;Modules(true);local s=NHLController:getPageStack();s:popToBottomPage()
if s:getTopPage()~=NI.HW.PAGE_CONTROL then s:pushPage(NI.HW.PAGE_CONTROL) end
self:updatePageSync(true);self.ActivePage.RouteRoot=1;self.ActivePage:updateScreen()
end
elseif m.Stage=="root" then
if m.Index==1 then m.Stage="levels";m.Index=Level()
else
self.ChannelMenu=nil;Modules(true);local s=NHLController:getPageStack();s:popToBottomPage()
if s:getTopPage()~=NI.HW.PAGE_CONTROL then s:pushPage(NI.HW.PAGE_CONTROL) end
self:updatePageSync(true);self.ActivePage.NavLevel=Level();self.ActivePage.RouteBranch=2
end
elseif m.Stage=="levels" then m.Stage="sections";m.Index=App:getWorkspace():getPageGroupParameter():getValue()+1
else
self.ChannelMenu=nil;local s=NHLController:getPageStack();s:popPage()
if s:getTopPage()~=NI.HW.PAGE_MACRO then s:pushPage(NI.HW.PAGE_MACRO) end
self:updatePageSync(true)
end
end
end)
if not ok then Trace("MENU ERROR "..tostring(e));self.ChannelMenu=nil end
end
if self.RouteBack then
self.RouteBack=nil
if NHLController:getPageStack():getTopPage()==NI.HW.PAGE_MACRO then
local ok,e=pcall(function()
self.ChannelMenu={Stage="sections",Index=App:getWorkspace():getPageGroupParameter():getValue()+1}
self:updatePageSync(true)
end)
Trace(ok and "back to channel sections" or "ERROR "..tostring(e))
end
end
if NHLController:getPageStack():getTopPage()~=NI.HW.PAGE_MACRO then self.RouteBackHeld=nil end
return CTimer(self)
end
function C:captureChainAction(id,v)
local page=self.ActivePage
if self.ChannelMenu or (page and (page.RouteRoot or page.NavLevel)) then self.ChainAction=nil;return end
return Capture(self,id,v)
end
local NativeLEDs=C.updateLEDs
function C:updateLEDs()
if NativeLEDs then NativeLEDs(self) end
local top=NHLController:getPageStack():getTopPage()
local index,count
if self.ChannelMenu and top==NI.HW.PAGE_NAVIGATE then
local m=self.ChannelMenu
index=m.Index;count=m.Stage=="root" and 2 or (m.Stage=="levels" and 3 or 4)
elseif top==NI.HW.PAGE_CONTROL and self.ActivePage then
local p=self.ActivePage
if p.RouteRoot then index=p.RouteRoot;count=2
elseif p.NavLevel then index=p.NavLevel;count=3 end
end
if index and count then
LEDHelper.setLEDOnOff(NI.HW.LED_LEFT,index>1)
LEDHelper.setLEDOnOff(NI.HW.LED_RIGHT,index<count)
end
end
for _,name in ipairs({"openBusyDialog","openDialogSave","openDialogMessage","openDialogProgress"}) do
local native=C[name]
if native then C[name]=function(self,...)
if self.ChannelMenu and NHLController:getPageStack():getTopPage()==NI.HW.PAGE_NAVIGATE then NHLController:getPageStack():popPage() end
self.ChannelMenu=nil;self.MenuClick=nil;self.MenuHeld=nil;self.MenuDelta=nil;return native(self,...) end end
end
Trace("route hooks loaded")
