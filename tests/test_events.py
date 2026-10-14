from pathlib import Path
from lupa.lua51 import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
notes={{time=0,pitch=60},{time=10,pitch=60},{time=10,pitch=64},{time=20,pitch=60}}
selection={};fallback=0;shift=false
pattern={getLengthParameter=function()return {getValue=function()return 40 end}end};sound={};group={};song={}
NI={DATA={StateHelper={},SoundAlgorithms={hasAudioModuleInLoopMode=function()return false end},EventPatternAccess={},EventPatternTools={},SelectionAccess={}}}
local H=NI.DATA.StateHelper
H.getFocusEventPattern=function()return pattern end;H.getFocusSound=function()return sound end;H.getFocusGroup=function()return group end;H.getFocusSong=function()return song end
NI.DATA.EventPatternAccess.getSoundNoteEvents=function(p,s,t,length,pitch)
local found={}
for _,note in ipairs(notes)do if note.time>=t and note.time<t+length and (pitch==-1 or pitch==note.pitch)then table.insert(found,note)end end
found.size=function(self)return #self end;found.empty=function(self)return #self==0 end;return found
end
NI.DATA.EventPatternTools.getNumSelectedNoteEventsInPatternRange=function()return #selection end
NI.DATA.EventPatternTools.getSelectedNoteEventPosition=function()return #selection==1 and selection[1].time or -1 end
NI.DATA.EventPatternTools.getSelectedNoteEventsPitch=function()return #selection==1 and selection[1].pitch or -1 end
NI.DATA.SelectionAccess.deselectAllEvents=function()selection={}end
NI.DATA.SelectionAccess.selectEvents=function(a,p,g,s,set)selection=set end
NI.DATA.EventSet=function()return {size=function(self)return #self end,empty=function(self)return #self==0 end}end
STLHelper={insertSet=function(to,from)for _,note in ipairs(from)do local exists=false;for _,n in ipairs(to)do if n==note then exists=true end end;if not exists then table.insert(to,note)end end end}
NHLController={getPageStack=function()return {getTopPage=function()return 17 end}end}
MaschineMikroMK3={isShiftPressed=function()return shift end,onControllerTimer=function()end,onWheelEvent=function()fallback=fallback+1 end}
io.open=function()return nil end
App={}
''')
lua.execute((Path(__file__).resolve().parents[1] / 'runtime/event-navigation.lua').read_text())
lua.execute('''
c=setmetatable({ActivePage={Name="EventsPageMikroMK3"}},{__index=MaschineMikroMK3})
function step(d)c:onWheelEvent(0,d)end
step(1);assert(#selection==1 and selection[1].time==0)
step(1);assert(selection[1].time==10 and selection[1].pitch==60)
step(1);assert(selection[1].time==10 and selection[1].pitch==64)
step(1);assert(selection[1].time==20)
step(1);assert(selection[1].time==20)
step(-1);assert(selection[1].time==10 and selection[1].pitch==64)
step(-1);assert(selection[1].time==10 and selection[1].pitch==60)
step(-1);assert(selection[1].time==0)
step(-1);assert(selection[1].time==0)
c.ActivePage.Name="PluginPageMikroMK3";step(1);assert(fallback==1)
assert(notes[1].time==0 and notes[2].time==10 and notes[3].pitch==64 and notes[4].time==20)
''')
lua.execute("""
c.ActivePage.Name="EventsPageMikroMK3";selection={};c.EventNoteRange=nil
shift=false;step(1);assert(#selection==1 and selection[1].time==0)
shift=true;step(1);assert(#selection==2 and c.EventNoteRange.Cursor.Time==10 and c.EventNoteRange.Cursor.Pitch==60)
step(1);assert(#selection==3 and c.EventNoteRange.Cursor.Pitch==64)
step(-1);assert(#selection==2 and c.EventNoteRange.Cursor.Pitch==60)
step(-1);assert(#selection==1 and selection[1].time==0)
step(-1);assert(#selection==1)
step(1);step(1);step(1);assert(#selection==4)
shift=false;step(1);assert(#selection==1 and selection[1].time==20 and not c.EventNoteRange.Anchor)
shift=true;step(-1);assert(#selection==2 and selection[1].pitch==64 and selection[1].time==10)
selection={notes[1]};step(1);assert(#selection==2 and c.EventNoteRange.Anchor.Time==0)
shift=false;step(-1);assert(#selection==1 and selection[1].time==0)
assert(notes[1].time==0 and notes[2].time==10 and notes[3].pitch==64 and notes[4].time==20)
""")
print('PASS range expansion/contraction, chord endpoints, boundary collapse and external-selection reset')
print('PASS note order, chord order, reverse, boundaries, page delegation and unchanged event data')
