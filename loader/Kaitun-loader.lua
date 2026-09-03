-- File: loader/Kaitun-loader.lua

-- Langkah 1: Muat Config terlebih dahulu
local successConfig, errConfig = pcall(function()
    local configURL = "https://raw.githubusercontent.com/donyfiebryprayoga/Donn/refs/heads/main/loader/Default-config-gag2.lua"
    loadstring(game:HttpGet(configURL))()
end)

if not successConfig then
    warn("[Kaitun Loader] Gagal memuat file konfigurasi: " .. tostring(errConfig))
    return
end
print("[Kaitun Loader] Config berhasil dimuat!")

-- Langkah 2: Muat Logika Utama Auto-Farm
local successCore, errCore = pcall(function()
    local coreURL = "https://raw.githubusercontent.com/donyfiebryprayoga/Donn/refs/heads/main/loader/Core-Logic.lua"
    loadstring(game:HttpGet(coreURL))()
end)

if not successCore then
    warn("[Kaitun Loader] Gagal menjalankan Core Logic: " .. tostring(errCore))
else
    print("[Kaitun Loader] Script Kaitun Grow a Garden 2 berhasil dimuat sepenuhnya!")
end
