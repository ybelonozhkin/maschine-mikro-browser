-- Commands are captured on wheel press and executed after release.
function MaschineMikroMK3:captureChainAction(Id,Pressed)
if Id~=NI.HW.BUTTON_WHEEL then return end
if not Pressed then
if self.ChainAction then self.ChainAction.Ready=true end
return
end
self.ChainAction=nil
local Page=NHLController:getPageStack():getTopPage()
local Kind
local Type
if Page==NI.HW.PAGE_BROWSE and self:isShiftPressed() then
if BrowseHelper.isBusy() or BrowseHelper.getResultListSize()==0 then return end
Type=App:getDatabaseFrontend():getBrowserModel():getSelectedFileType()
if Type==NI.DB3.FILE_TYPE_EFFECT then Kind="ADD FX"
elseif Type==NI.DB3.FILE_TYPE_INSTRUMENT or Type==NI.DB3.FILE_TYPE_ONESHOT_SAMPLE or Type==NI.DB3.FILE_TYPE_LOOP_SAMPLE then
local Song=NI.DATA.StateHelper.getFocusSong(App)
if not Song or Song:getLevelTab()~=NI.DATA.LEVEL_TAB_SOUND then return end
Kind="KEEP FX"
else return end
elseif Page==NI.HW.PAGE_CONTROL and self:isShiftPressed() and self:isErasePressed() then Kind="REMOVE"
else return end
local Layer=NI.DATA.StateHelper.getFocusMixingLayer(App)
if not Layer then return end
self.ChainAction={Kind=Kind,Page=Page,Layer=Layer,Slot=NI.DATA.StateHelper.getFocusSlot(App),
Type=Type,Result=BrowseHelper.getResultListFocusItem()}
end

function MaschineMikroMK3:runChainAction()
local Action=self.ChainAction
if not Action or not Action.Ready then return end
self.ChainAction=nil
if NHLController:getPageStack():getTopPage()~=Action.Page or
NI.DATA.StateHelper.getFocusMixingLayer(App)~=Action.Layer then return end
local Slots=NI.DATA.StateHelper.getFocusChainSlots(App)
if not Slots then return end
if Action.Kind=="REMOVE" then
if not Action.Slot or NI.DATA.StateHelper.getFocusSlot(App)~=Action.Slot then return end
NI.DATA.ChainAccess.removeSlot(App,Slots,Action.Slot)
local Mode=NHLController:getContext():mikroMk3():getPluginPageIsEditingParametersParameter()
if Mode then NI.DATA.ParameterAccess.setBoolParameterNoUndo(App,Mode,false) end
else
if BrowseHelper.isBusy() or BrowseHelper.getResultListSize()==0 or
BrowseHelper.getResultListFocusItem()~=Action.Result or
App:getDatabaseFrontend():getBrowserModel():getSelectedFileType()~=Action.Type then return end
if Action.Kind=="ADD FX" then
self:insertChainPreset(Action.Layer,Slots:size())
else
local First=Slots:size()>0 and Slots:at(0) or nil
if Action.Type==NI.DB3.FILE_TYPE_ONESHOT_SAMPLE then
self:loadOneShotKeepFX(Action.Layer,Slots,First,Action.Result)
elseif Action.Type==NI.DB3.FILE_TYPE_LOOP_SAMPLE then
self:loadOneShotKeepFX(Action.Layer,Slots,First,Action.Result)
self:insertChainPreset(Action.Layer,0)
elseif First and ModuleHelper.isSlotFX(First) then
self:insertChainPreset(Action.Layer,0)
else
NI.DATA.ChainAccess.setFocusSlot(App,Slots,First,false)
BrowseHelper.loadFocusItem()
end
end
end
self.ChainNotice=Action.Kind
self.ChainNoticeTicks=25
end

function MaschineMikroMK3:loadOneShotKeepFX(Layer,Slots,First,Result)
local Results=App:getDatabaseFrontend():getBrowserModel():getResultListModel()
local Path=Results:getItemPath(Result)
if not Path or Path=="" then error("No sample path") end
local Insert=First and ModuleHelper.isSlotFX(First) or false
local Effects={}
for I=0,Slots:size()-1 do
local Slot=Slots:at(I)
if ModuleHelper.isSlotFX(Slot) then Effects[#Effects+1]=Slot end
end
NI.DATA.ChainAccess.createModuleOrLoadDefault(App,NI.DATA.ModuleInfo.ID_SAMPLER,Layer:getChain(),First,Insert)
NI.DATA.ChainAccess.setFocusSlot(App,Slots,Slots:at(0),false)
local Sampler=NI.DATA.StateHelper.getFocusSampler(App,nil)
if not Sampler then error("Sampler was not created") end
local Zones=Sampler:getZones()
for I=Zones:size()-1,0,-1 do NI.DATA.SamplerAccess.removeZone(App,Sampler,Zones:at(I)) end
for I,Slot in ipairs(Effects) do
if Slots:at(I)~=Slot then error("FX chain changed unexpectedly") end
end
NI.DATA.SamplerAccess.loadIntoNewZone(App,Path)
end

function MaschineMikroMK3:insertChainPreset(Layer,Index)
local Previous=BrowseHelper.getInsertMode()
BrowseHelper.setInsertMode(NI.DATA.INSERT_MODE_BROWSING)
local OK,Error=pcall(NI.DATA.FileAccess.loadSlotInsertMode,App,Layer,Index)
BrowseHelper.setInsertMode(Previous)
if not OK then error(Error) end
end

function MaschineMikroMK3:updateChainNotice()
if not self.ChainNoticeTicks then return end
self.ChainNoticeTicks=self.ChainNoticeTicks-1
if self.ActivePage and self.ActivePage.Screen then
if self.ChainNoticeTicks>0 then
self.ActivePage.Screen:setTopRowText(self.ChainNotice)
else
self.ChainNoticeTicks=nil
self.ActivePage:updateScreen()
end
end
end
