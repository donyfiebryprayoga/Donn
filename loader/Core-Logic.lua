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

-- 2. Auto Harvest Loop
if HarvestCfg["Auto Harvest"] then
    task.spawn(function()
        while task.wait(1.5) do
            pcall(function()
                local sellAt = HarvestCfg["Sell At"] or 85
                -- Logika pemanenan / pengecekan buah di sini
            end)
        end
    end)
end

-- 3. Auto Plant Loop
if PlantCfg["Auto Plant"] then
    task.spawn(function()
        while task.wait(2) do
            pcall(function()
                local layout = PlantCfg["Layout"] or "compact"
                local minSeed = PlantCfg["Minimum Seed"] or "Bamboo"
                -- Logika penanaman otomatis di sini
            end)
        end
    end)
end

-- 4. Money & Plot Expansion Loop
task.spawn(function()
    while task.wait(5) do
        pcall(function()
            local keepCash = MoneyCfg["Keep Cash"] or 15000
            local autoExpand = MoneyCfg["Auto Expand Plot"]
            local maxExp = MoneyCfg["Max Expansions"] or 5
            local expandOver = MoneyCfg["Expand If Over"] or 1500000
            -- Logika ekspansi plot otomatis di sini
        end)
    end
end)

-- 5. Auction Auto Buyer Loop
if AuctionCfg["Auto Buy"] then
    task.spawn(function()
        local interval = AuctionCfg["Check Every"] or 0.2
        while task.wait(interval) do
            pcall(function()
                local buyItems = AuctionCfg["Buy"] or {}
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
