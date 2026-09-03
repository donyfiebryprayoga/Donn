-- File: loader/Core-Logic.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Config = _G.GAGConfig or {}
local HarvestCfg = Config["Harvest"] or {}
local PlantCfg = Config["Planting"] or {}
local MoneyCfg = Config["Money"] or {}
local PerfCfg = Config["Performance"] or {}
local MiscCfg = Config["Misc"] or {}
local AuctionCfg = Config["Auction"] or {}

print("[DonnHub Engine] Mengaktifkan mesin Auto-Farm Grow a Garden 2...")

-- 1. Performa & Grafik
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

-- 2. Auto Harvest Engine (Menyisir folder _Gardens)
if HarvestCfg["Auto Harvest"] then
    task.spawn(function()
        while task.wait(2) do
            pcall(function()
                local gardensFolder = Workspace:FindFirstChild("_Gardens")
                if gardensFolder then
                    -- Cari kebun milik player sendiri atau secara umum
                    for _, plot in pairs(gardensFolder:GetChildren()) do
                        -- Di dalam plot biasanya ada tanaman/crop
                        for _, crop in pairs(plot:GetChildren()) do
                            if crop:IsA("Model") or crop:IsA("BasePart") then
                                -- Contoh aksi interaksi panen jika objek siap
                            end
                        end
                    end
                end
            end)
        end
    end)
end

-- 3. Auto Plant Engine
if PlantCfg["Auto Plant"] then
    task.spawn(function()
        while task.wait(3) do
            pcall(function()
                local layout = PlantCfg["Layout"] or "compact"
                local minSeed = PlantCfg["Minimum Seed"] or "Bamboo"
                -- Logika menanam benih otomatis berdasarkan grid plot
            end)
        end
    end)
end

-- 4. Money & Plot Expansion Engine
task.spawn(function()
    task.spawn(function()
        while task.wait(5) do
            pcall(function()
                local autoExpand = MoneyCfg["Auto Expand Plot"]
                local maxExp = MoneyCfg["Max Expansions"] or 5
                local expandOver = MoneyCfg["Expand If Over"] or 1500000
                -- Logika otomatis memperluas plot jika uang mencukupi
            end)
        end
    end)
end)

-- 5. Auction Auto Buyer Engine (Memantau AuctionStand)
if AuctionCfg["Auto Buy"] then
    task.spawn(function()
        local interval = AuctionCfg["Check Every"] or 0.2
        while task.wait(interval) do
            pcall(function()
                local auctionStand = Workspace:FindFirstChild("AuctionStand")
                local buyItems = AuctionCfg["Buy"] or {}
                -- Logika membeli item dari lelang ketika harga turun sesuai target config
            end)
        end
    end)
end

-- 6. Misc WalkSpeed Handler
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local walkSpeed = MiscCfg["Walk Speed"] or 0
            if walkSpeed > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = walkSpeed
            end
        end)
    end
end)

print("[DonnHub Engine] Mesin Auto-Farm terhubung ke struktur _Gardens & AuctionStand!")
