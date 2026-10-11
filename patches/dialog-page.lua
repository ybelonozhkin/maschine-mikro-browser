require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
local class=require 'Scripts/Shared/Helpers/classy'
BusyPageMikroMK3=class('BusyPageMikroMK3',PageMikroMK3)
function BusyPageMikroMK3:__init(Controller)
PageMikroMK3.__init(self,"BusyPageMikroMK3",Controller)
end
function BusyPageMikroMK3:onShow(Show)
self.Selected=1;self.Pending=nil;self.Submitted=false
if Show then NHLController:setPadMode(NI.HW.PAD_MODE_NONE) end
PageMikroMK3.onShow(self,Show)
end
function BusyPageMikroMK3:updateScreen()
local Actions=self.Controller.DialogActions
local Top,Bottom=App:getGenericBusyMessage()
if Actions then
Top=self.Controller.DialogTitle
Bottom=Actions[self.Selected or 1][1]
end
self.Screen:setTopRowText(Top):setTopRowTextAttribute("boldCenter")
:setBottomRowText(Bottom):setBottomRowTextAttribute("boldCenter")
end
function BusyPageMikroMK3:onWheelEvent(Value)
local Actions=self.Controller.DialogActions
if not Actions or self.Submitted or Value==0 then return end
self.Selected=math.max(1,math.min(#Actions,(self.Selected or 1)+(Value>0 and 1 or -1)))
self:updateScreen()
end
function BusyPageMikroMK3:onSwitchEvent(Id,Pressed)
local Actions=self.Controller.DialogActions
if Id~=NI.HW.BUTTON_WHEEL or not Actions or self.Submitted then return end
if Pressed then self.Pending=Actions[self.Selected or 1][2]
elseif self.Pending~=nil then
local Result=self.Pending
self.Pending=nil;self.Submitted=true
self.Controller.DialogActions=nil
App:getHardwareInputManager():onButton(Result)
end
end
function BusyPageMikroMK3:onPadEvent() end
