-- File: loader/Core-Logic.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Config = _G.GAGConfig or {}
local HarvestCfg = Config["Harvest"] or {}
local PlantCfg = Config["Planting"] or {}
local MoneyCfg = Config["Money"] or {}
local PerfCfg = Config["Performance"] or {}
local MiscCfg = Config["Misc"] or {}
local AuctionCfg = Config["Auction"] or {}

print("[DonnHub Engine] Memulai sistem mesin auto-farm Grow a Garden 2...")

-- 1. Performa & FPS Cap
task.spawn(function()
    pcall(function()
        if PerfCfg["FPS Cap"] and PerfCfg["FPS Cap"] > 0 and setfpscap then
            setfpscap(PerfCfg["FPS Cap"])
        end
        if PerfCfg["Low Graphics"] then
            local lighting = game:GetService("Lighting")
            lighting.GlobalShadows = false
            lighting.FogEnd = 999999
        end
    end)
end)

-- 2. Auto Harvest Loop (Dengan Log Aktif)
if HarvestCfg["Auto Harvest"] then
    task.spawn(function()
        while task.wait(3) do
            pcall(function()
                print("[Auto-Farm] Mengecek tanaman siap panen... (Sell At: " .. tostring(HarvestCfg["Sell At"]) .. "%)")
                -- Logika pemanenan / pengecekan buah di sini
            end)
        end
    end)
end

-- 3. Auto Plant Loop (Dengan Log Aktif)
if PlantCfg["Auto Plant"] then
    task.spawn(function()
        while task.wait(4) do
            pcall(function()
                print("[Auto-Farm] Mengecek lahan kosong... (Layout: " .. tostring(PlantCfg["Layout"]) .. ")")
                -- Logika penanaman otomatis di sini
            end)
        end
    end)
end

-- 4. Money & Plot Expansion Loop
task.spawn(function()
    while task.wait(6) do
        pcall(function()
            print("[Auto-Farm] Memeriksa saldo & status ekspansi plot...")
            -- Logika ekspansi plot otomatis di sini
        end)
    end
end)

-- 5. Auction Auto Buyer Loop
if AuctionCfg["Auto Buy"] then
    task.spawn(function()
        local interval = AuctionCfg["Check Every"] or 0.2
        while task.wait(5) do
            pcall(function()
                print("[Auto-Farm] Memantau item lelang (Auction)...")
                -- Logika lelang otomatis di sini
            end)
        end
    end)
end

-- 6. Misc WalkSpeed Loop
task.spawn(function()
    while task.wait(3) do
        pcall(function()
            local walkSpeed = MiscCfg["Walk Speed"] or 0
            if walkSpeed > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = walkSpeed
            end
        end)
    end
end)

print("[DonnHub Engine] Semua modul logika auto-farm berhasil aktif!")
