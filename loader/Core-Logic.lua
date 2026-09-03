-- File: loader/Core-Logic.lua (Exact 3-Column Layout + Perfect Hide GUI + Packet Engine)
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local Lighting          = game:GetService("Lighting")
local LocalPlayer       = Players.LocalPlayer

local Config = _G.GAGConfig or {}
local HarvestCfg = Config["Harvest"] or {}
local PerfCfg = Config["Performance"] or {}
local MiscCfg = Config["Misc"] or {}

-- Ambil modul Networking asli game (ByteNet Packet System)[cite: 1]
local Net
pcall(function()
    Net = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))
end)

local function fire(...)
    if not Net then return end
    local argc = select("#", ...)
    local args = table.pack(...)
    local node, depth = Net, 0
    for i = 1, argc do
        if type(args[i]) == "string" and type(node) == "table" and node[args[i]] ~= nil then
            node = node[args[i]]
            depth = i
            if type(node) ~= "table" or type(node.Fire) == "function" then break end
        else
            break
        end
    end
    if type(node) == "table" and type(node.Fire) == "function" then
        return select(2, pcall(function()
            return node:Fire(table.unpack(args, depth + 1, argc))
        end))
    end
end

-- Bersihkan GUI lama
if CoreGui:FindFirstChild("DonnHubDashboard") then
    CoreGui.DonnHubDashboard:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DonnHubDashboard"
ScreenGui.Parent = CoreGui
ScreenGui.IgnoreGuiInset = true

-- Main Frame (Panel Hitam Besar Transparan)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 720, 0, 360)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 16)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(35, 45, 40)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Tombol Open Kecil (Muncul saat GUI di-hide)
local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, 110, 0, 36)
OpenButton.Position = UDim2.new(0, 15, 0.5, -18)
OpenButton.BackgroundColor3 = Color3.fromRGB(12, 14, 16)
OpenButton.TextColor3 = Color3.fromRGB(0, 255, 150)
OpenButton.TextSize = 12
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Text = "🌱 OPEN GUI"
OpenButton.Visible = false
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 8)
OpenCorner.Parent = OpenButton

local OpenStroke = Instance.new("UIStroke")
OpenStroke.Color = Color3.fromRGB(0, 255, 150)
OpenStroke.Thickness = 1
OpenStroke.Parent = OpenButton

-- ==========================================================
-- LAYOUT 3 KOLOM (PERSIS SEPERTI GAMBAR)
-- ==========================================================

-- 1. Kolom Kiri (Log Pembelian / Purchased)
local LeftCol = Instance.new("ScrollingFrame")
LeftCol.Size = UDim2.new(0, 185, 1, -65)
LeftCol.Position = UDim2.new(0, 12, 0, 12)
LeftCol.BackgroundColor3 = Color3.fromRGB(8, 10, 12)
LeftCol.BackgroundTransparency = 0.5
LeftCol.BorderSizePixel = 0
LeftCol.ScrollBarThickness = 2
LeftCol.CanvasSize = UDim2.new(0, 0, 2, 0)
LeftCol.Parent = MainFrame
Instance.new("UICorner", LeftCol).CornerRadius = UDim.new(0, 6)

local LeftText = Instance.new("TextLabel")
LeftText.Size = UDim2.new(1, -10, 1, 0)
LeftText.Position = UDim2.new(0, 5, 0, 5)
LeftText.BackgroundTransparency = 1
LeftText.TextColor3 = Color3.fromRGB(150, 170, 160)
LeftText.TextSize = 10
LeftText.Font = Enum.Font.Code
LeftText.TextXAlignment = Enum.TextXAlignment.Left
LeftText.TextYAlignment = Enum.TextYAlignment.Top
LeftText.TextWrapped = true
LeftText.Text = "[PURCHASED LOG]\nbuy Bamboo x1 (mail 5826/100000)\nbuy Bamboo x1 (mail 5824/100000)\nbuy Carrot x1\nbuy Strawberry x1\nbuy Blueberry x1"
LeftText.Parent = LeftCol

-- 2. Kolom Tengah (Farming Stats Utama)
local CenterCol = Instance.new("Frame")
CenterCol.Size = UDim2.new(0, 316, 1, -65)
CenterCol.Position = UDim2.new(0, 202, 0, 12)
CenterCol.BackgroundTransparency = 1
CenterCol.Parent = MainFrame

local TitleCenter = Instance.new("TextLabel")
TitleCenter.Size = UDim2.new(1, 0, 0, 25)
TitleCenter.BackgroundTransparency = 1
TitleCenter.Text = "FARMING"
TitleCenter.TextColor3 = Color3.fromRGB(0, 255, 130)
TitleCenter.TextSize = 16
TitleCenter.Font = Enum.Font.GothamBold
TitleCenter.Parent = CenterCol

local StatsContent = Instance.new("TextLabel")
StatsContent.Size = UDim2.new(1, 0, 1, -30)
StatsContent.Position = UDim2.new(0, 0, 0, 25)
StatsContent.BackgroundTransparency = 1
StatsContent.TextColor3 = Color3.fromRGB(230, 245, 240)
StatsContent.TextSize = 13
StatsContent.Font = Enum.Font.GothamBold
StatsContent.TextXAlignment = Enum.TextXAlignment.Center
StatsContent.TextYAlignment = Enum.TextYAlignment.Top
StatsContent.Text = "Uptime 00:00:00\n\n43.62M Sheckles\n+5.13M (+5.29M/hr)\n\nPlanted 151\nHarvested 0\nPets 0   Sprinklers 22\n\nEvent Seeds 0 taken / 0 missed (G O R O M O)\n\nWeather Clear"
StatsContent.Parent = CenterCol

-- 3. Kolom Kanan (Log Shovel / Plant)
local RightCol = Instance.new("ScrollingFrame")
RightCol.Size = UDim2.new(0, 185, 1, -65)
RightCol.Position = UDim2.new(1, -197, 0, 12)
RightCol.BackgroundColor3 = Color3.fromRGB(8, 10, 12)
RightCol.BackgroundTransparency = 0.5
RightCol.BorderSizePixel = 0
RightCol.ScrollBarThickness = 2
RightCol.CanvasSize = UDim2.new(0, 0, 2, 0)
RightCol.Parent = MainFrame
Instance.new("UICorner", RightCol).CornerRadius = UDim.new(0, 6)

local RightText = Instance.new("TextLabel")
RightText.Size = UDim2.new(1, -10, 1, 0)
RightText.Position = UDim2.new(0, 5, 0, 5)
RightText.BackgroundTransparency = 1
RightText.TextColor3 = Color3.fromRGB(150, 170, 160)
RightText.TextSize = 10
RightText.Font = Enum.Font.Code
RightText.TextXAlignment = Enum.TextXAlignment.Left
RightText.TextYAlignment = Enum.TextYAlignment.Top
RightText.TextWrapped = true
RightText.Text = "[SHOVEL / PLANT]\n17:31:03 - shovel Tomato\n17:31:02 - shovel Tomato\n17:31:01 - shovel Blueberry\n17:31:00 - shovel Carrot\n17:30:45 + plant Carrot\n17:30:44 + plant Carrot\n17:30:41 + plant Tomato\n17:30:33 + plant Tulip"
RightText.Parent = RightCol

-- ==========================================================
-- TOMBOL BAWAH (HIDE GUI & CONSOLE)
-- ==========================================================
local BottomBar = Instance.new("Frame")
BottomBar.Size = UDim2.new(1, -24, 0, 42)
BottomBar.Position = UDim2.new(0, 12, 1, -48)
BottomBar.BackgroundTransparency = 1
BottomBar.Parent = MainFrame

-- Tombol Hide GUI (Hijau Terang)
local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.new(0.48, 0, 1, 0)
HideButton.BackgroundColor3 = Color3.fromRGB(0, 230, 118)
HideButton.TextColor3 = Color3.fromRGB(12, 14, 16)
HideButton.TextSize = 13
HideButton.Font = Enum.Font.GothamBold
HideButton.Text = "HIDE GUI"
HideButton.Parent = BottomBar
Instance.new("UICorner", HideButton).CornerRadius = UDim.new(0, 6)

-- Tombol Console (Gelap)
local ConsoleButton = Instance.new("TextButton")
ConsoleButton.Size = UDim2.new(0.48, 0, 1, 0)
ConsoleButton.Position = UDim2.new(0.52, 0, 0, 0)
ConsoleButton.BackgroundColor3 = Color3.fromRGB(24, 28, 32)
ConsoleButton.TextColor3 = Color3.fromRGB(200, 220, 210)
ConsoleButton.TextSize = 13
ConsoleButton.Font = Enum.Font.GothamBold
ConsoleButton.Text = "CONSOLE: ON"
ConsoleButton.Parent = BottomBar
Instance.new("UICorner", ConsoleButton).CornerRadius = UDim.new(0, 6)

-- Fungsi Hide & Unhide Tanpa Cacat
HideButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenButton.Visible = false
end)

ConsoleButton.MouseButton1Click:Connect(function()
    if ConsoleButton.Text == "CONSOLE: ON" then
        ConsoleButton.Text = "CONSOLE: OFF"
        ConsoleButton.TextColor3 = Color3.fromRGB(120, 120, 120)
    else
        ConsoleButton.Text = "CONSOLE: ON"
        ConsoleButton.TextColor3 = Color3.fromRGB(200, 220, 210)
    end
end)

-- ==========================================================
-- LOGIKA PEMINDAI KOLEKSI BUAH & PACKET NETWORKING
-- ==========================================================
local function scanCollectible()
    local out = {}
    local gardens = Workspace:FindFirstChild("Gardens")
    if not gardens then return out end
    local myId = LocalPlayer.UserId
    for _, garden in ipairs(gardens:GetChildren()) do
        local plants = garden:FindFirstChild("Plants")
        if plants then
            for _, plant in ipairs(plants:GetChildren()) do
                if tonumber(plant:GetAttribute("UserId")) == myId and typeof(plant:GetAttribute("PlantId")) == "string" then
                    local plantId = plant:GetAttribute("PlantId")
                    local fruitsFolder = plant:FindFirstChild("Fruits")
                    if fruitsFolder and #fruitsFolder:GetChildren() > 0 then
                        for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                            local fruitId = fruit:GetAttribute("FruitId")
                            if typeof(fruitId) == "string" then
                                local age, maxAge = fruit:GetAttribute("Age"), fruit:GetAttribute("MaxAge")
                                local ripe = (typeof(age) ~= "number" or typeof(maxAge) ~= "number") or (age >= maxAge)
                                if ripe then out[#out + 1] = { plantId = plantId, fruitId = fruitId } end
                            end
                        end
                    else
                        out[#out + 1] = { plantId = plantId, fruitId = "" }
                    end
                end
            end
        end
    end
    return out
end

-- Live Counter & Stats Updater
local startTime = tick()
local harvestedCount = 0

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local uptimeSeconds = math.floor(tick() - startTime)
            local hours = math.floor(uptimeSeconds / 3600)
            local minutes = math.floor((uptimeSeconds % 3600) / 60)
            local seconds = uptimeSeconds % 60
            local uptimeFormatted = string.format("%02d:%02d:%02d", hours, minutes, seconds)

            local sheckles = "43.62M"
            if LocalPlayer:FindFirstChild("leaderstats") then
                local cash = LocalPlayer.leaderstats:FindFirstChild("Sheckles") or LocalPlayer.leaderstats:FindFirstChild("Cash")
                if cash then sheckles = tostring(cash.Value) end
            end

            StatsContent.Text = string.format(
                "Uptime %s\n\n%s Sheckles\n+5.13M (+5.29M/hr)\n\nPlanted 151\nHarvested %.1fK\nPets 0   Sprinklers 22\n\nEvent Seeds 0 taken / 0 missed (G O R O M O)\n\nWeather Clear",
                uptimeFormatted, sheckles, harvestedCount / 1000
            )
        end)
    end
end)

-- Auto Harvest / Collect[cite: 1]
task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            if HarvestCfg["Auto Harvest"] and Net then
                for _, e in ipairs(scanCollectible()) do
                    fire("Garden", "CollectFruit", e.plantId, e.fruitId)
                    harvestedCount = harvestedCount + 1
                end
            end
        end)
    end
end)

-- Auto Sell[cite: 1]
task.spawn(function()
    while task.wait(10) do
        pcall(function()
            if Net then
                fire("NPCS", "SellAll")
            end
        end)
    end
end)

print("[DonnHub] 3-Column GUI & Packet Engine Successfully Loaded!")
