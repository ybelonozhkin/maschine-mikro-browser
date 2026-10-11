function MaschineMikroMK3:openDialogSave()
self.DialogTitle="Save project?"
self.DialogActions={{"Cancel",0},{"Discard",2},{"Save",3}}
NHLController:getPageStack():pushPage(NI.HW.PAGE_SAVE_DIALOG)
self:updatePageSync(true);NHLController:updateLEDs(true)
end
local Close=MaschineMikroMK3.closeBusyDialog
function MaschineMikroMK3:closeBusyDialog()
self.DialogActions=nil;self.DialogTitle=nil
if NHLController:getPageStack():getTopPage()==NI.HW.PAGE_SAVE_DIALOG then
NHLController:getPageStack():popPage();self:updatePageSync(true);NHLController:updateLEDs(true);return
end
return Close(self)
end
