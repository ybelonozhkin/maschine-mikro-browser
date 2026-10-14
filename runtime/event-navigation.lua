local C=MaschineMikroMK3
local Wheel,Timer=C.onWheelEvent,C.onControllerTimer
local function Log(message)
pcall(function()
local base=os.getenv("LOCALAPPDATA")
if not base then return end
local f=io.open(base.."/MaschineMikroBrowser/event-navigation.log","a")
if f then
if f:seek("end")>262144 then f:close();f=io.open(base.."/MaschineMikroBrowser/event-navigation.log","w") end
if f then f:write(os.date("%H:%M:%S "),message,"\n");f:close() end
end
end)
end
local function IsEvents(self)
return self.ActivePage and self.ActivePage.Name=="EventsPageMikroMK3"
end
local function NoteStep(self,direction,extend)
local pattern=NI.DATA.StateHelper.getFocusEventPattern(App)
local sound=NI.DATA.StateHelper.getFocusSound(App)
local group=NI.DATA.StateHelper.getFocusGroup(App)
local song=NI.DATA.StateHelper.getFocusSong(App)
if not pattern or not sound or not group or not song then self.EventNoteRange=nil;Log("NO_NOTE_CONTEXT");return end
if NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(sound) then self.EventNoteRange=nil;Log("REJECT audio loop");return end
local length=pattern:getLengthParameter():getValue()
if length<1 then self.EventNoteRange=nil;Log("EMPTY_PATTERN");return end
local function Events(first,last,note)
return NI.DATA.EventPatternAccess.getSoundNoteEvents(pattern,sound,first,last-first+1,note or -1)
end
local function Has(first,last)
return first<=last and Events(first,last):size()>0
end
local function Candidate(time,first,last,step)
for pitch=first,last,step do
local set=Events(time,time,pitch)
if set:size()==1 then return {Time=time,Pitch=pitch,Set=set}
elseif set:size()>1 then Log("SKIP coincident duplicate notes tick="..time.." pitch="..pitch) end
end
end
local selected=NI.DATA.EventPatternTools.getNumSelectedNoteEventsInPatternRange(App)
local time=NI.DATA.EventPatternTools.getSelectedNoteEventPosition(song,group,false)
local pitch=NI.DATA.EventPatternTools.getSelectedNoteEventsPitch(song,group,false)
local range=self.EventNoteRange
if range and (range.Pattern~=pattern or range.Sound~=sound or range.Count~=selected or
(selected==1 and (range.Cursor.Time~=time or range.Cursor.Pitch~=pitch))) then
Log("RESET range context or external selection changed")
range=nil;self.EventNoteRange=nil
end
local cursor=range and range.Cursor or (selected==1 and time>=0 and pitch>=0 and pitch<128 and {Time=time,Pitch=pitch} or nil)
local target
if cursor then
if direction>0 and cursor.Pitch<127 then target=Candidate(cursor.Time,cursor.Pitch+1,127,1) end
if direction<0 and cursor.Pitch>0 then target=Candidate(cursor.Time,cursor.Pitch-1,0,-1) end
end
if not target then
local origin=cursor and cursor.Time or (direction>0 and -1 or length)
local low=direction>0 and origin+1 or 0
local high=direction>0 and length-1 or origin-1
if Has(low,high) then
while low<high do
local middle=math.floor((low+high)/2)
if direction>0 then
if Has(low,middle) then high=middle else low=middle+1 end
else
if Has(middle+1,high) then low=middle+1 else high=middle end
end
end
target=Candidate(low,direction>0 and 0 or 127,direction>0 and 127 or 0,direction)
end
end
if not target then
Log("BOUNDARY no further unique note")
if extend or not cursor then return end
target=Candidate(cursor.Time,cursor.Pitch,cursor.Pitch,1)
if not target then self.EventNoteRange=nil;return end
end
local anchor=extend and ((range and range.Anchor) or cursor or target) or nil
local set=target.Set
if anchor then
local first,last=anchor,target
if first.Time>last.Time or (first.Time==last.Time and first.Pitch>last.Pitch) then first,last=last,first end
set=NI.DATA.EventSet()
if first.Time==last.Time then
for note=first.Pitch,last.Pitch do STLHelper.insertSet(set,Events(first.Time,first.Time,note)) end
else
for note=first.Pitch,127 do STLHelper.insertSet(set,Events(first.Time,first.Time,note)) end
if first.Time+1<=last.Time-1 then STLHelper.insertSet(set,Events(first.Time+1,last.Time-1)) end
for note=0,last.Pitch do STLHelper.insertSet(set,Events(last.Time,last.Time,note)) end
end
end
-- Build and validate the complete selection before changing the current one.
if set:empty() then Log("EMPTY_SELECTION_REJECT");return end
NI.DATA.SelectionAccess.deselectAllEvents(App,pattern,group)
NI.DATA.SelectionAccess.selectEvents(App,pattern,group,sound,set)
self.EventNoteRange={Pattern=pattern,Sound=sound,Cursor={Time=target.Time,Pitch=target.Pitch},
Anchor=anchor and {Time=anchor.Time,Pitch=anchor.Pitch} or nil,Count=set:size()}
Log("selected cursor="..target.Time..":"..target.Pitch.." count="..set:size()..
" anchor="..(anchor and (anchor.Time..":"..anchor.Pitch) or "none"))
end
function C:onWheelEvent(id,value)
if IsEvents(self) then
if value~=0 then
local ok,e=pcall(NoteStep,self,value>0 and 1 or -1,self:isShiftPressed())
if not ok then self.EventNoteRange=nil;Log("ERROR "..tostring(e)) end
end
return
end
self.EventNoteRange=nil
return Wheel(self,id,value)
end
function C:onControllerTimer()
local result=Timer(self)
if not IsEvents(self) then self.EventNoteRange=nil end
return result
end
