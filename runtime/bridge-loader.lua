local Path=MaschineMikroBrowserRuntimePath.."/maschine-browser-bridge.dll"
local function Load(name)
local f,e=package.loadlib(Path,name)
if not f then error(tostring(e)) end
return f
end
local init=Load("BridgeInitialize")
local types=Load("BridgeRequestTypes")
local characters=Load("BridgeRequestCharacters")
local enable=Load("BridgeEnableExpansion")
init()
enable()
local C=MaschineMikroMK3
local Open,Tick=C.openTags,C.tickTags
function C:openTags()
local result=Open(self)
init()
local t=self.TagState
if t then
self.BridgeLastAttribute=t.Attr
if t.Attr==2 and BrowseHelper.supportsModes(BrowseHelper.getFileType()) then characters() else types() end
end
return result
end
function C:tickTags()
local result=Tick(self)
local t=self.TagState
if t and t.Attr~=self.BridgeLastAttribute then
self.BridgeLastAttribute=t.Attr
if t.Attr==2 and BrowseHelper.supportsModes(BrowseHelper.getFileType()) then characters() else types() end
end
return result
end
