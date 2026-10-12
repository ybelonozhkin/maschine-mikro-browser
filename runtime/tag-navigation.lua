local C=MaschineMikroMK3
local Sync,Switch,Wheel,Timer,LEDs,Capture=C.updatePageSync,C.onSwitchEvent,C.onWheelEvent,C.onControllerTimer,C.updateLEDs,C.captureChainAction
local function Trace(s)
pcall(function()local f=io.open((os.getenv("LOCALAPPDATA").."/MaschineMikroBrowser/tag-navigation.log"),"a")
if f then if f:seek("end")>262144 then f:close();f=io.open((os.getenv("LOCALAPPDATA").."/MaschineMikroBrowser/tag-navigation.log"),"w") end
if f then f:write(os.date("%H:%M:%S "),s,"\n");f:close() end end end)
end
local function Attributes() return App:getDatabaseFrontend():getBrowserModel():getAttributesModel() end
local function Count(attr) return Attributes():getActiveAttributeCount(attr) end
local function Name(attr,index) return index<0 and "All" or Attributes():getActiveAttributeName(attr,index) end
local function Index(attr)
local i=Attributes():getActiveIndexOfFocusAttribute(attr)
return i>=0 and i<Count(attr) and i or -1
end
local function Title(attr)
if attr==0 then return "Types" elseif attr==1 then return "Sub-Types" end
return BrowseHelper.supportsModes(BrowseHelper.getFileType()) and "Characters" or "Sub-Types 2"
end
local function Sections()
local list={0}
if Count(1)>0 and Index(0)>=0 then table.insert(list,1) end
if Count(2)>0 then table.insert(list,2) end
return list
end
local function ReleaseWheel(self)
if self.TagJogPrevious~=nil then
if NHLController:getJogWheelMode()==NI.HW.JOGWHEEL_MODE_CUSTOM then NHLController:setJogWheelMode(self.TagJogPrevious) end
self.TagJogPrevious=nil
end
end
function C:renderTags()
local t=self.TagState
if not t or not self.ActivePage then return end
local text=t.Pending and t.Pending.Name or Name(t.Attr,t.Cursor)
self.ActivePage.Screen:showTextInBottomRow():setTopRowIcon(""):setBottomRowIcon("")
:setTopRowText(Title(t.Attr)):setBottomRowText(text or "")
end
function C:closeTags()
ReleaseWheel(self)
self.TagState=nil;self.TagHeld=nil;self.TagClick=nil;self.TagDelta=nil;self.TagSectionDelta=nil
local s=NHLController:getPageStack();s:popToBottomPage()
if s:getTopPage()~=NI.HW.PAGE_BROWSE then s:pushPage(NI.HW.PAGE_BROWSE) end
self:updatePageSync(true);Trace("results")
end
function C:openTags()
self.ChannelMenu=nil;self.MenuClick=nil;self.MenuHeld=nil;self.MenuDelta=nil
BrowseHelper.forceCacheRefresh()
local attr=Count(2)>0 and 2 or (Count(1)>0 and 1 or 0)
local cursor=Index(attr)
self.TagState={Attr=attr,Cursor=cursor,EntryName=cursor>=0 and Name(attr,cursor) or nil,Type=BrowseHelper.getFileType()}
local s=NHLController:getPageStack();s:popToBottomPage();s:pushPage(NI.HW.PAGE_NAVIGATE)
self.TagJogPrevious=NHLController:getJogWheelMode()
NHLController:setJogWheelMode(NI.HW.JOGWHEEL_MODE_CUSTOM)
self:updatePageSync(true);Trace("open "..Title(attr))
end
function C:updatePageSync(force)
local top=NHLController:getPageStack():getTopPage()
if self.TagState and top~=NI.HW.PAGE_NAVIGATE then ReleaseWheel(self);self.TagState=nil;self.TagHeld=nil;self.TagClick=nil;self.TagDelta=nil;self.TagSectionDelta=nil end
Sync(self,force)
if self.TagState then
local p=self.ActivePage
if p and not p.TagScreenWrapped then
local native=p.updateScreen
p.updateScreen=function(page,...)
if self.TagState and self.ActivePage==page then return self:renderTags() end
if native then return native(page,...) end
end
local pad=p.onPadEvent
p.onPadEvent=function(page,...)
if self.TagState then return end
if pad then return pad(page,...) end
end
p.TagScreenWrapped=true
end
self:renderTags()
end
end
local function IsBrowseArrow(id)
return id==NI.HW.BUTTON_LEFT or id==NI.HW.BUTTON_RIGHT
or (NI.HW.BUTTON_ARROW_LEFT~=nil and id==NI.HW.BUTTON_ARROW_LEFT)
or (NI.HW.BUTTON_ARROW_RIGHT~=nil and id==NI.HW.BUTTON_ARROW_RIGHT)
end
function C:onSwitchEvent(id,v)
if self.TagState and IsBrowseArrow(id) then
if v then
self:closeTags()
Trace("resource arrow id="..tostring(id))
end
return Switch(self,id,v)
end
if self.TagState then
if id==NI.HW.BUTTON_WHEEL then
if v then self.TagHeld={Back=self:isShiftPressed()}
elseif self.TagHeld then self.TagClick=self.TagHeld;self.TagHeld=nil end
end
end
return Switch(self,id,v)
end
function C:onWheelEvent(id,v)
if self.TagState then
if v~=0 then self.TagDelta=v>0 and 1 or -1 end
return
end
return Wheel(self,id,v)
end
function C:tickTags()
local t=self.TagState
BrowseHelper.updateCacheTimer();BrowseHelper.forceCacheRefresh()
if BrowseHelper.getFileType()~=t.Type then Trace("file type changed");self:closeTags();return end
if t.Pending then
t.Pending.Ticks=t.Pending.Ticks+1
if t.Pending.Ticks>=2 and not BrowseHelper.isBusy() and Name(t.Attr,Index(t.Attr))==t.Pending.Name then
local advance=t.Pending.Advance
t.Cursor=Index(t.Attr)
if advance then
local nextAttr=t.Attr+1
if nextAttr==1 and (t.Cursor<0 or Count(1)==0) then nextAttr=2 end
if nextAttr==2 and Count(2)==0 then nextAttr=3 end
t.Pending=nil
if nextAttr>2 then self:closeTags();return end
t.Attr=nextAttr;t.Cursor=Index(nextAttr);t.EntryName=t.Cursor>=0 and Name(nextAttr,t.Cursor) or nil
Trace("enter "..Title(nextAttr))
else t.Pending=nil end
elseif t.Pending.Ticks>300 then Trace("selection acknowledgement timeout");self:closeTags();return end
end
if self.TagDelta and not t.Pending then
local d=self.TagDelta;self.TagDelta=nil
local index=math.max(-1,math.min(Count(t.Attr)-1,t.Cursor+d))
if index~=t.Cursor then
local name=Name(t.Attr,index)
BrowseHelper.setAttributeIndex(t.Attr,index);t.Cursor=index
t.Pending={Cursor=index,Name=name,Advance=false,Ticks=0}
Trace("preview "..Title(t.Attr).." index="..index.." name="..name)
end
end
if self.TagClick and not t.Pending then
local a=self.TagClick;self.TagClick=nil
if not t.Pending then
if a.Back then
local prev=t.Attr==2 and (Count(1)>0 and Index(0)>=0 and 1 or 0) or 0
t.Attr=prev;t.Cursor=Index(prev);t.EntryName=t.Cursor>=0 and Name(prev,t.Cursor) or nil
Trace("back "..Title(prev))
else
local count=Count(t.Attr)
if t.Cursor>=-1 and t.Cursor<count then
if t.Attr==2 and BrowseHelper.supportsModes(BrowseHelper.getFileType()) and t.Cursor>=0 and Name(t.Attr,t.Cursor)==t.EntryName then t.Cursor=-1 end
local name=Name(t.Attr,t.Cursor)
BrowseHelper.setAttributeIndex(t.Attr,t.Cursor)
t.Pending={Cursor=t.Cursor,Name=name,Advance=true,Ticks=0}
Trace("select attr="..t.Attr.." index="..t.Cursor)
end
end
end
end
self:renderTags()
end
function C:onControllerTimer()
if self.TagOpen then self.TagOpen=nil
local ok,e=pcall(self.openTags,self)
if not ok then Trace("OPEN ERROR "..tostring(e));pcall(self.closeTags,self) end
end
if self.TagState then
local ok,e=pcall(self.tickTags,self)
if not ok then Trace("ERROR "..tostring(e));pcall(self.closeTags,self) end
end
return Timer(self)
end
function C:updateLEDs()
LEDs(self)
local t=self.TagState
if t then
-- Same resource/product availability as the normal results page.
BrowserPageMikroMK3.onControllerTimer(self.ActivePage)
end
end
function C:captureChainAction(id,v)
if self.TagState then self.ChainAction=nil;return end
return Capture(self,id,v)
end
for _,name in ipairs({"openBusyDialog","openDialogSave","openDialogMessage","openDialogProgress"}) do
local native=C[name]
if native then C[name]=function(self,...)
ReleaseWheel(self)
if self.TagState and NHLController:getPageStack():getTopPage()==NI.HW.PAGE_NAVIGATE then NHLController:getPageStack():popPage() end
self.TagState=nil;self.TagHeld=nil;self.TagClick=nil;self.TagDelta=nil;self.TagSectionDelta=nil;return native(self,...) end end
end
Trace("tag hooks loaded")
