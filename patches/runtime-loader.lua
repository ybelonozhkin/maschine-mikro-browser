local ok,e=pcall(dofile,os.getenv("PROGRAMDATA").."/MaschineMikroBrowser/0.4.0/runtime.lua")
if not ok then pcall(function()
local f=io.open(os.getenv("LOCALAPPDATA").."/MaschineMikroBrowser/runtime-error.log","w")
if f then f:write(tostring(e));f:close() end
end) end
