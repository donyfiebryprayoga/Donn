-- 1. Otomatis muat konfigurasi dari GitHub terlebih dahulu
local SuccessConfig, ErrConfig = pcall(function()
    local settingURL = "https://raw.githubusercontent.com/donyfiebryprayoga/Donn/refs/heads/main/loader/Default-config-gag2.lua"
    loadstring(game:HttpGet(settingURL))()
end)

if not SuccessConfig then
    warn("[Kaitun Loader] Gagal memuat file setting, menggunakan setelan bawaan game: " .. tostring(ErrConfig))
end

-- 2. Otomatis jalankan skrip utama Kaitun setelah setting siap
local SuccessScript, ErrScript = pcall(function()
    -- Ganti link di bawah ini dengan link raw skrip utama Kaitun Anda yang sebenarnya
    local kaitunScriptURL = "LINK_RAW_SKRIP_UTAMA_KAITUN_ANDA"
    loadstring(game:HttpGet(kaitunScriptURL))()
end)

if not SuccessScript then
    warn("[Kaitun Loader] Gagal menjalankan skrip utama Kaitun: " .. tostring(ErrScript))
else
    print("[Kaitun Loader] Skrip Kaitun berhasil berjalan otomatis!")
end
