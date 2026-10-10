function BrowserPageMikroMK3:onSwitchEvent(Id,Pressed)
if not Pressed or BrowseHelper.isBusy() then return end
local Right
if Id==NI.HW.BUTTON_RIGHT or Id==NI.HW.BUTTON_ARROW_RIGHT then Right=true
elseif Id==NI.HW.BUTTON_LEFT or Id==NI.HW.BUTTON_ARROW_LEFT then Right=false
else return end
if self.Controller:isShiftPressed() then
BrowseHelper.offsetBankChain(0,Right and 1 or -1)
else
local Prev,Next=BrowseHelper.hasPrevNextFileType()
if (Right and Next) or (not Right and Prev) then
BrowseHelper.selectPrevOrNextVisibleFileType(Right)
end
end
end
function BrowserPageMikroMK3:onControllerTimer()
BrowseHelper.updateCacheTimer()
local Prev,Next=BrowseHelper.hasPrevNextFileType()
if self.Controller:isShiftPressed() then
local Count=BrowseHelper.getProductCount()
local Index=BrowseHelper.getFocusProductIndex()
if Index<0 or Index>=Count then Index=-1 end
Prev=Count>0 and Index>=0
Next=Count>0 and Index<Count-1
end
LEDHelper.setLEDOnOff(NI.HW.LED_LEFT,Prev)
LEDHelper.setLEDOnOff(NI.HW.LED_RIGHT,Next)
end
