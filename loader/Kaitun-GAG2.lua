-- File: loader/Kaitun-loader.lua

-- 1. Otomatis muat konfigurasi dari Default-config-gag2.lua terlebih dahulu
local SuccessConfig, ErrConfig = pcall(function()
    local configURL = "https://raw.githubusercontent.com/donyfiebryprayoga/Donn/refs/heads/main/loader/Default-config-gag2.lua"
    loadstring(game:HttpGet(configURL))()
end)

if not SuccessConfig then
    warn("[Kaitun Loader] Gagal memuat file konfigurasi: " .. tostring(ErrConfig))
else
    print("[Kaitun Loader] Konfigurasi GAGConfig berhasil dimuat otomatis!")
end

-- 2. Otomatis jalankan skrip utama Kaitun Grow a Garden 2
local SuccessScript, ErrScript = pcall(function()
    local mainScriptURL = "https://raw.githubusercontent.com/donyfiebryprayoga/Donn/refs/heads/main/loader/Kaitun-GAG2.lua"
    loadstring(game:HttpGet(mainScriptURL))()
end)

if not SuccessScript then
    warn("[Kaitun Loader] Gagal menjalankan skrip utama Kaitun: " .. tostring(ErrScript))
else
    print("[Kaitun Loader] Script Kaitun Grow a Garden 2 berhasil dimuat!")
end
