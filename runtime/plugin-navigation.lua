local OldShow=PluginPageMikroMK3.onShow
local OldScreen=PluginPageMikroMK3.updateScreen
local OldSwitch=PluginPageMikroMK3.onSwitchEvent
local OldWheel=PluginPageMikroMK3.onWheelEvent
local OldTimer=PluginPageMikroMK3.onControllerTimer
local Levels={NI.DATA.LEVEL_TAB_SONG,NI.DATA.LEVEL_TAB_GROUP,NI.DATA.LEVEL_TAB_SOUND}
local Names={"Master","Group","Sound"}
local function Mode() return NHLController:getContext():mikroMk3():getPluginPageIsEditingParametersParameter() end
local function Edit(v) NI.DATA.ParameterAccess.setBoolParameterNoUndo(App,Mode(),v) end
local function Log(s)
pcall(function()
local f=io.open((os.getenv("LOCALAPPDATA").."/MaschineMikroBrowser/navigation-step1.log"),"a")
if f then if f:seek("end")>262144 then f:close();f=io.open((os.getenv("LOCALAPPDATA").."/MaschineMikroBrowser/navigation-step1.log"),"w") end
if f then f:write(os.date("%H:%M:%S "),s,"\n");f:close() end end
end)
end
local function Safe(self,fn,...)
local ok,e=pcall(fn,self,...)
if not ok then self.NavLevel=nil;self.NavHeld=nil;self.NavPending=nil;Log("ERROR "..tostring(e)) end
return ok
end
function PluginPageMikroMK3:onShow(v)
self.NavLevel=nil;self.NavHeld=nil;self.NavPending=nil;self.NavArrow=nil
self.NavEditing=Mode():getValue()
Log("show "..tostring(v));return OldShow(self,v)
end
function PluginPageMikroMK3:updateScreen()
if not self.NavLevel then return OldScreen(self) end
self.Screen:showTextInBottomRow():setTopRowIcon(""):setBottomRowIcon("")
:setTopRowText("Plug-ins"):setBottomRowText(Names[self.NavLevel])
end
function PluginPageMikroMK3:onSwitchEvent(id,v)
if self.NavLevel and (id==NI.HW.BUTTON_LEFT or id==NI.HW.BUTTON_RIGHT) then
self.NavArrow=v and (id==NI.HW.BUTTON_RIGHT and 1 or -1) or self.NavArrow
return
end
if id==NI.HW.BUTTON_CONTROL and v then self.NavLevel=nil;self.NavHeld=nil;self.NavPending=nil;self.NavArrow=nil end
if id==NI.HW.BUTTON_WHEEL and not self.Controller:isErasePressed() then
if v and (self.Controller:isShiftPressed() or self.NavLevel) then
self.NavHeld={Back=self.Controller:isShiftPressed(),Editing=self.NavEditing}
Log("back="..tostring(self.NavHeld.Back).." e="..tostring(self.NavEditing))
elseif not v and self.NavHeld then self.NavPending=self.NavHeld;self.NavHeld=nil;Log("release") end
end
return OldSwitch(self,id,v)
end
function PluginPageMikroMK3:onWheelEvent(v)
if not self.NavLevel then return OldWheel(self,v) end
if v~=0 then self.NavLevel=math.max(1,math.min(3,self.NavLevel+(v>0 and 1 or -1)))
Safe(self,function()
local song=NI.DATA.StateHelper.getFocusSong(App)
if song then NI.DATA.SongAccess.setLevelTab(App,song,Levels[self.NavLevel]) end
self:updateScreen()
end);Log("choose "..Names[self.NavLevel or 3]) end
end
function PluginPageMikroMK3:navApply(a)
Edit(false)
if a.Back then
if not self.NavLevel and not a.Editing then
local song=NI.DATA.StateHelper.getFocusSong(App)
self.NavLevel=3
for i,v in ipairs(Levels) do if song and song:getLevelTab()==v then self.NavLevel=i end end
end
elseif self.NavLevel then
self.NavLevel=nil
end
Log("level="..tostring(self.NavLevel));self:updateScreen()
end
function PluginPageMikroMK3:onControllerTimer()
if self.NavPending then local a=self.NavPending;self.NavPending=nil;Safe(self,self.navApply,a) end
if self.NavLevel then Safe(self,function()
Edit(false)
if self.NavArrow then
local d=self.NavArrow;self.NavArrow=nil
if self.NavLayer==NI.DATA.StateHelper.getFocusMixingLayer(App) and self.NavSlot then
NI.DATA.ChainAccess.setFocusSlot(App,self.NavSlots,self.NavSlot,false)
end
self:onWheelEvent(d)
end
local song=NI.DATA.StateHelper.getFocusSong(App)
for i,v in ipairs(Levels) do if song and song:getLevelTab()==v then self.NavLevel=i end end
self.NavLayer=NI.DATA.StateHelper.getFocusMixingLayer(App)
self.NavSlots=NI.DATA.StateHelper.getFocusChainSlots(App)
self.NavSlot=NI.DATA.StateHelper.getFocusSlot(App)
self:updateScreen()
end) else OldTimer(self) end
self.NavEditing=Mode():getValue()
end
