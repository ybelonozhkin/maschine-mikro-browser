function PluginPageMikroMK3:onWheelEvent(Value)
    if isParameterEditMode() or Value == 0 then return end
    local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
    if not Slots or Slots:size() == 0 then return end
    local Index = NI.DATA.StateHelper.getFocusSlotIndex(App)
    if Index < 0 or Index >= Slots:size() then
        Index = Value > 0 and 0 or Slots:size()-1
    else
        Index = math.max(0,math.min(Slots:size()-1,Index+(Value > 0 and 1 or -1)))
    end
    local Slot = Slots:at(Index)
    if Slot and Slot ~= NI.DATA.StateHelper.getFocusSlot(App) then
        NI.DATA.ChainAccess.setFocusSlot(App,Slots,Slot,false)
        self:updateScreen()
    end
end
