-- Salin dan tempel kode ini ke dalam file D.lua di GitHub kamu

local MyGameScript = {}

function MyGameScript.Init()
    -- Masukkan semua logic game, setup service, UI, atau fungsi kamu di sini
    print("Logic game dan service berhasil dimuat dari GitHub!")
    
    -- Contoh penggunaan service standar Roblox:
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    print("Berjalan sebagai player: " .. tostring(localPlayer and localPlayer.Name))
end

return MyGameScript
