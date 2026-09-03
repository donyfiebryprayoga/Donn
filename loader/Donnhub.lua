local HttpGet = game.HttpGet
local CurrentPlaceId = game.PlaceId

local Success, Games = pcall(function()
    return loadstring(HttpGet(game, "https://raw.githubusercontent.com/donyfiebryprayoga/DonnHUB/refs/heads/main/List%20Game/List-Game.lua"))()
end)

if not Success or type(Games) ~= "table" then 
    warn("Gagal memuat list game normal!")
    return 
end

local URL = Games[CurrentPlaceId]
if not URL then 
    warn("Game tidak didukung di DonnHub Normal.")
    return 
end

loadstring(HttpGet(game, URL))()