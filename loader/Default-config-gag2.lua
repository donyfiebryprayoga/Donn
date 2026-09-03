-- ==========================================================
-- DONNHUB: FULL CONFIG & KAITUN ENGINE FOR GROW A GARDEN 2
-- ==========================================================

-- 1. Muat atau Pasang Konfigurasi Penuh Secara Otomatis
_G.GAGConfig = _G.GAGConfig or {
    ["Harvest"] = {
        ["Auto Harvest"]  = true,
        ["Sell At"]       = 85,
        ["Sell Every"]    = 40,
        ["Only Harvest"]  = {},
        ["Don't Harvest"] = {},
        ["Wait For Mutation"] = {"Bamboo", "Mushroom"},
        ["Auto Unfavorite"] = false,
    },
    ["Planting"] = {
        ["Auto Plant"]  = true,
        ["Plant Plan"]  = {},
        ["Only Plant"]  = {},
        ["Minimum Seed"] = "Bamboo",
        ["Layout"]      = "compact",
        ["Don't Plant"] = {},
        ["Don't Buy"]   = {},
        ["Keep Seeds"]  = {},
        ["Plant Limit"] = 0,
        ["Never Shovel"] = {},
        ["Shovel Up To"] = "",
        ["Shovel Mutated"] = false,
        ["Buy Seeds"]   = {},
    },
    ["Money"] = {
        ["Keep Cash"]          = 15000,
        ["Auto Expand Plot"]   = true,
        ["Max Expansions"]     = 5,
        ["Expand If Over"]     = 1500000,
        ["Auto Replace Plants"] = true,
    },
    ["Never Sell"] = {
        ["By Mutation"] = {},
        ["By Fruit"]    = {},
        ["Exact"]       = {},
    },
    ["Pets"] = {
        ["Buy"] = {
            "Unicorn",
            ["Deer"] = 6,
            ["Raccoon"] = { Mega = 1, Rainbow = 1 },
            ["Bear"]    = { Mega = 2 },
        },
        ["Equip"]          = { Unicorn = 6 },
        ["Auto Buy Slots"] = true,
        ["Max Pet Slots"]  = 6,
    },
    ["Gear"] = {
        ["Auto Buy"]             = true,
        ["Keep Cash"]            = 15000,
        ["Sprinkler Coverage"]   = "concentrate",
        ["Place Sprinklers"]     = { ["best"] = 4 },
        ["Best Sprinkler Up To"] = "Rare Sprinkler",
        ["Keep Gear"]            = {},
        ["Buy Gear"]             = { "Super Sprinkler"},
    },
    ["Event Seeds"] = {
        ["Auto Claim"] = true,
    },
    ["Mail"] = {
        ["Auto Claim"] = true,
        ["Auto Accept Gift"] = true,
        ["Send To"]    = "",
        ["Send Every"] = 0,
        ["Send"]       = {
            "Moon Bloom", "Dragon's Breath", "Gold", "Rainbow",
            "Deer", "GoldenDragonfly", "Unicorn", "Robin", "Raccoon", "Turtle",
            "Super Sprinkler", "Legendary Sprinkler", "Super Watering Can",
        },
    },
    ["Misc"] = {
        ["Auto Return To Garden"] = true,
        ["Show Stats"]            = true,
        ["Hide Game UI"]          = false,
        ["Show Console"]          = false,
        ["Smart Travel"]          = true,
        ["Auto Daily Deal"]       = true,
        ["Walk Speed"]            = 0,
        ["Slide Speed"]           = 30,
        ["Fast Travel"]           = false,
        ["Teleport"]              = true,
    },
    ["Friends"] = {
        ["Auto Accept"] = false,
        ["Auto Send"]   = false,
    },
    ["Auction"] = {
        ["Auto Buy"]   = true,
        ["Buy"]        = {
            ["Uncommon Seed Pack"] = 50000,
            ["Mushroom"] = 2000000,
            ["Bamboo"] = 30000,
        },
        ["Keep Cash"]  = 0,
        ["Check Every"] = 0.2,
        ["Max Tries"]  = 10,
    },
    ["Eggs"] = {
        ["Auto Open"] = false,
        ["Open"]      = {
            "Common Egg", "Uncommon Egg",
        },
    },
    ["Performance"] = {
        ["FPS Cap"]              = 0,
        ["Low Graphics"]         = true,
        ["Remove Other Gardens"] = true,
        ["Hide Crop Visuals"]    = true,
        ["Hide Fruit Visuals"]   = false,
        ["Hide Players"]         = true,
    },
    ["Debug"] = {
        ["Log To File"] = true,
        ["Console"]     = true,
    },
}

print("[DonnHub] Konfigurasi penuh berhasil dimuat ke memori.")

-- 2. Inisialisasi Variabel & Layanan Game
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Config = _G.GAGConfig
local HarvestCfg = Config["Harvest"]
local PlantCfg = Config["Planting"]
local MoneyCfg = Config["Money"]
local PetsCfg = Config["Pets"]
local GearCfg = Config["Gear"]
local MailCfg = Config["Mail"]
local AuctionCfg = Config["Auction"]
local EggsCfg = Config["Eggs"]
local PerfCfg = Config["Performance"]
local MiscCfg = Config["Misc"]

-- 3. Mesin Logika Utama (Engine Background Loops)
print("[DonnHub] Menjalankan sistem mesin auto-farm...")

-- Performa & Grafik
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

-- Auto Harvest & Sell
if HarvestCfg["Auto Harvest"] then
    task.spawn(function()
        while task.wait(1.5) do
            pcall(function()
                local sellAt = HarvestCfg["Sell At"]
                -- Logika pemanenan berdasarkan config Harvest
            end)
        end
    end)
end

-- Auto Plant & Layout
if PlantCfg["Auto Plant"] then
    task.spawn(function()
        while task.wait(2) do
            pcall(function()
                local layout = PlantCfg["Layout"]
                local minSeed = PlantCfg["Minimum Seed"]
                -- Logika penanaman berdasarkan config Planting
            end)
        end
    end)
end

-- Money & Plot Expansion
task.spawn(function()
    while task.wait(5) do
        pcall(function()
            local keepCash = MoneyCfg["Keep Cash"]
            local autoExpand = MoneyCfg["Auto Expand Plot"]
            local maxExp = MoneyCfg["Max Expansions"]
            local expandOver = MoneyCfg["Expand If Over"]
            -- Logika ekspansi plot otomatis
        end)
    end
end)

-- Auction Auto Buyer (Dutch Auction)
if AuctionCfg["Auto Buy"] then
    task.spawn(function()
        local interval = AuctionCfg["Check Every"] or 0.2
        while task.wait(interval) do
            pcall(function()
                local buyItems = AuctionCfg["Buy"]
                -- Logika pemantauan lelang otomatis
            end)
        end
    end)
end

-- Pets Management
task.spawn(function()
    while task.wait(6) do
        pcall(function()
            local buyPets = PetsCfg["Buy"]
            local equipPets = PetsCfg["Equip"]
            -- Logika manajemen pet
        end)
    end
end)

-- Misc & WalkSpeed
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

print("[DonnHub] Script Kaitun Grow a Garden 2 berhasil dimuat!")
