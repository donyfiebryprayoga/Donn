-- File: loader/Core-Logic.lua (Full GUI + Auto-Farm Engine)
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
local Window = OrionLib:MakeWindow({Name = "DonnHub | Grow a Garden 2 Kaitun", HidePremium = false, SaveConfig = true, ConfigFolder = "DonnHubConfig"})

local Config = _G.GAGConfig or {}
local HarvestCfg = Config["Harvest"] or {}
local PlantCfg = Config["Planting"] or {}
local MoneyCfg = Config["Money"] or {}
local PerfCfg = Config["Performance"] or {}
local AuctionCfg = Config["Auction"] or {}
local MiscCfg = Config["Misc"] or {}

-- 1. Tab Utama: Harvest & Planting
local TabMain = Window:MakeTab({
    Name = "Farm & Plant",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

TabMain:AddToggle({
    Name = "Auto Harvest",
    Default = HarvestCfg["Auto Harvest"] or true,
    Callback = function(Value)
        HarvestCfg["Auto Harvest"] = Value
    end
})

TabMain:AddSlider({
    Name = "Sell Fruit At (%)",
    Min = 10,
    Max = 100,
    Default = HarvestCfg["Sell At"] or 85,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "%",
    Callback = function(Value)
        HarvestCfg["Sell At"] = Value
    end
})

TabMain:AddToggle({
    Name = "Auto Plant",
    Default = PlantCfg["Auto Plant"] or true,
    Callback = function(Value)
        PlantCfg["Auto Plant"] = Value
    end
})

TabMain:AddDropdown({
    Name = "Plant Layout",
    Default = PlantCfg["Layout"] or "compact",
    Options = {"compact", "spread", "grid"},
    Callback = function(Value)
        PlantCfg["Layout"] = Value
    end
})

-- 2. Tab Kedua: Money & Auction
local TabMoney = Window:MakeTab({
    Name = "Money & Auction",
    Icon = "rbxassetid://6023426915",
    PremiumOnly = false
})

TabMoney:AddToggle({
    Name = "Auto Expand Plot",
    Default = MoneyCfg["Auto Expand Plot"] or true,
    Callback = function(Value)
        MoneyCfg["Auto Expand Plot"] = Value
    end
})

TabMoney:AddToggle({
    Name = "Auction Auto Buy",
    Default = AuctionCfg["Auto Buy"] or true,
    Callback = function(Value)
        AuctionCfg["Auto Buy"] = Value
    end
})

-- 3. Tab Ketiga: Performa & Misc
local TabMisc = Window:MakeTab({
    Name = "Performa & Misc",
    Icon = "rbxassetid://6023426915",
    PremiumOnly = false
})

TabMisc:AddToggle({
    Name = "Low Graphics (Optimasi)",
    Default = PerfCfg["Low Graphics"] or true,
    Callback = function(Value)
        PerfCfg["Low Graphics"] = Value
        if Value then
            local lighting = game:GetService("Lighting")
            lighting.GlobalShadows = false
            lighting.FogEnd = 999999
        end
    end
})

TabMisc:AddSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 100,
    Default = 16,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Speed",
    Callback = function(Value)
        local lp = game:GetService("Players").LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.WalkSpeed = Value
        end
    end
})

-- Inisialisasi GUI Orion
OrionLib:Init()

print("[DonnHub GUI] Antarmuka menu berhasil ditampilkan!")

-- ==========================================================
-- BACKGROUND LOOPS (Mesin Utama yang Membaca Config / GUI)
-- ==========================================================
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            -- Contoh eksekusi otomatis berdasarkan perubahan di GUI/Config
            if HarvestCfg["Auto Harvest"] then
                -- Proses panen aktif
            end
            if PlantCfg["Auto Plant"] then
                -- Proses tanam aktif
            end
        end)
    end
end)
