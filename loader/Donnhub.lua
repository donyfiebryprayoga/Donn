local CurrentPlaceId = game.PlaceId

local Success, Games = pcall(function()
    local response = game:HttpGet("https://raw.githubusercontent.com/donyfiebryprayoga/Donn/refs/heads/main/List%20Game/List-Game.lua")
    return loadstring(response)()
end)

if not Success or type(Games) ~= "table" then 
    warn("[DonnHub] Gagal memuat list game!")
    return 
end

local URL = Games[CurrentPlaceId]
if not URL then 
    warn("[DonnHub] Game ini tidak didukung.")
    return 
end

local SuccessLoad, Result = pcall(function()
    return loadstring(game:HttpGet(URL))()
end)

if not SuccessLoad then
    warn("[DonnHub] Gagal menjalankan skrip untuk game ini: " .. tostring(Result))
end
