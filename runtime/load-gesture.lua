local C=MaschineMikroMK3
local Capture,Switch,Timer=C.captureChainAction,C.onSwitchEvent,C.onControllerTimer
local function Snapshot()
local ok,v=pcall(function()return NI.DATA.ParameterSnapshotsAccess.isSnapshotActiveHW(App)end)
if ok then return v end
end
local function Trace(s)
pcall(function()local f=io.open((os.getenv("LOCALAPPDATA").."/MaschineMikroBrowser/load-gesture.log"),"a")
if f then if f:seek("end")>262144 then f:close();f=io.open((os.getenv("LOCALAPPDATA").."/MaschineMikroBrowser/load-gesture.log"),"w")end
if f then f:write(os.date("%H:%M:%S "),s,"\n");f:close()end end end)
end
local function Check(self)
local ctx=self.LoadLockContext
if not ctx then return end
local now=Snapshot()
if ctx.Before==nil or now==nil or now~=ctx.Before or NHLController:getPageStack():getTopPage()~=NI.HW.PAGE_BROWSE then
if not self.LoadLockBlocked then Trace("BLOCK native LOCK side effect or unavailable state") end
self.LoadLockBlocked=true;self.ChainAction=nil
end
end
function C:onSwitchEvent(id,v)
if id==NI.HW.BUTTON_LOCK and v and self:isShiftPressed() and NHLController:getPageStack():getTopPage()==NI.HW.PAGE_BROWSE then
local before=self.LoadSnapshotPrevious
if before==nil then before=Snapshot() end
self.LoadLockContext={Before=before};self.LoadLockBlocked=nil
Trace("LOCK press snapshot="..tostring(Snapshot()).." previous="..tostring(before))
end
local result=Switch(self,id,v)
Check(self)
if id==NI.HW.BUTTON_LOCK and not v then
Trace("LOCK release snapshot="..tostring(Snapshot()))
self.LoadLockContext=nil
end
return result
end
function C:captureChainAction(id,v)
if id~=NI.HW.BUTTON_WHEEL then return Capture(self,id,v) end
if not v and self.LoadBackHeld then
self.LoadBackHeld=nil
if NHLController:getPageStack():getTopPage()==NI.HW.PAGE_BROWSE then self.TagOpen=true;Trace("back to Characters") end
self.ChainAction=nil;return
end
if NHLController:getPageStack():getTopPage()==NI.HW.PAGE_BROWSE then
if v then
self.LoadBackHeld=nil
if self:isShiftPressed() then
if self:isButtonPressed(NI.HW.BUTTON_LOCK) then
Check(self)
if self.LoadLockBlocked then self.ChainAction=nil;return end
Trace("capture Shift+LOCK load")
return Capture(self,id,v)
elseif not self:isErasePressed() then
self.ChainAction=nil;self.LoadBackHeld=true;return
end
end
self.ChainAction=nil;return
elseif self.ChainAction then
Check(self)
if not self.LoadLockBlocked then return Capture(self,id,v) end
end
return
end
return Capture(self,id,v)
end
function C:onControllerTimer()
Check(self)
local result=Timer(self)
self.LoadSnapshotPrevious=Snapshot()
if NHLController:getPageStack():getTopPage()~=NI.HW.PAGE_BROWSE then self.LoadBackHeld=nil end
return result
end
Trace("Shift+LOCK load / Shift-click back hooks loaded")
