local source=debug.getinfo(1,"S").source
assert(source:sub(1,1)=="@","Runtime must be loaded from a file")
MaschineMikroBrowserRuntimePath=source:sub(2):match("^(.*)[/\\][^/\\]+$")
assert(MaschineMikroBrowserRuntimePath,"Runtime directory unavailable")
for _,name in ipairs({"plugin-navigation.lua","channel-navigation.lua","tag-navigation.lua","load-gesture.lua","bridge-loader.lua"}) do
dofile(MaschineMikroBrowserRuntimePath.."/"..name)
end
