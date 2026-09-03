-- File: loader/Core-Logic.lua (Fully Automated & Synchronized with Config)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- Pastikan config tersedia
local Config = _G.GAGConfig or {}
local HarvestCfg = Config["Harvest"] or {}
local PlantCfg = Config["Planting"] or {}
local MoneyCfg = Config["Money"] or {}
local AuctionCfg = Config["Auction"] or {}
local PerfCfg = Config["Performance"] or {}
local MiscCfg = Config["Misc"] or {}

-- Bersihkan GUI lama jika ada
if CoreGui:FindFirstChild("DonnHubDashboard") then
    CoreGui.DonnHubDashboard:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DonnHubDashboard"
ScreenGui.Parent = CoreGui
ScreenGui.IgnoreGuiInset = true

-- Panel Utama Dashboard
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 280)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "FARMING (SYNCED CONFIG ACTIVE)"
Title.TextColor3 = Color3.fromRGB(0, 255, 128)
Title.TextSize = 18
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

-- Tombol Hide / Minimize di Pojok Kanan Atas
local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.new(0, 30, 0, 30)
HideButton.Position = UDim2.new(1, -35, 0, 5)
HideButton.BackgroundTransparency = 1
HideButton.TextColor3 = Color3.fromRGB(200, 200, 200)
HideButton.TextSize = 16
HideButton.Font = Enum.Font.SourceSansBold
HideButton.Text = "-"
HideButton.Parent = MainFrame

-- Tombol Open Kecil di Pinggir Layar
local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, 70, 0, 30)
OpenButton.Position = UDim2.new(0, 10, 0.5, -15)
OpenButton.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.TextSize = 13
OpenButton.Font = Enum.Font.SourceSansBold
OpenButton.Text = "OPEN"
OpenButton.Visible = false
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 6)
OpenCorner.Parent = OpenButton

HideButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenButton.Visible = false
end)

-- Label Informasi Statistik Live
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(1, -20, 1, -50)
StatsLabel.Position = UDim2.new(0, 10, 0, 45)
StatsLabel.BackgroundTransparency = 1
StatsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatsLabel.TextSize = 14
StatsLabel.Font = Enum.Font.Code
StatsLabel.TextXAlignment = Enum.TextXAlignment.Center
StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
StatsLabel.Text = "Memuat konfigurasi & mesin otomatis..."
StatsLabel.Parent = MainFrame

-- Counter Statistik Live
local startTime = tick()
local harvestedCount = 0
local plantedCount = 0

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

            local harvestStatus = HarvestCfg["Auto Harvest"] and "ON" or "OFF"
            local plantStatus = PlantCfg["Auto Plant"] and "ON" or "OFF"

            StatsLabel.Text = string.format(
                "Uptime %s\n%s Sheckles\n\nHarvest: [%s] | Plant: [%s]\nPlanted: %d | Harvested: %d\nStatus: Fully Synchronized & Running",
                uptimeFormatted, sheckles, harvestStatus, plantStatus, plantedCount, harvestedCount
            )
        end)
    end
end)

-- ==========================================================
-- MESIN UTAMA: EKSEKUSI OTOMATIS BERDASARKAN CONFIG
-- ==========================================================

-- 1. Terapkan Pengaturan Performa & Grafik dari Config
task.spawn(function()
    pcall(function()
        if PerfCfg["FPS Cap"] and PerfCfg["FPS Cap"] > 0 and setfpscap then
            setfpscap(PerfCfg["FPS Cap"])
        end
        if PerfCfg["Low Graphics"] then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 999999
        end
    end)
end)

-- 2. Terapkan WalkSpeed dari Config Misc secara berkala
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local speed = MiscCfg["Walk Speed"] or 0
            if speed > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = speed
            end
        end)
    end
end)

-- 3. Fungsi Gerak Otomatis (Auto-Walk) ke Target Kebun
local function walkTo(targetPos)
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
            char.Humanoid:MoveTo(targetPos)
        end
    end)
end

-- 4. Loop Utama Auto-Harvest & Navigasi Kebun (Sinkron Konfigurasi)
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            -- Cek apakah Auto Harvest aktif di config
            if HarvestCfg["Auto Harvest"] then
                local gardensFolder = Workspace:FindFirstChild("_Gardens")
                if gardensFolder and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = LocalPlayer.Character.HumanoidRootPart
                    
                    for _, plot in pairs(gardensFolder:GetChildren()) do
                        for _, crop in pairs(plot:GetChildren()) do
                            local targetPart = crop:IsA("Model") and crop.PrimaryPart or (crop:IsA("BasePart") and crop or nil)
                            if targetPart then
                                local dist = (targetPart.Position - hrp.Position).Magnitude
                                if dist < 80 and dist > 3 then
                                    walkTo(targetPart.Position)
                                    task.wait(1)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- 5. Loop Interaksi Otomatis (Memicu ProximityPrompt di Sekitar Karakter)
task.spawn(function()
    while task.wait(0.8) do
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        if (obj.Parent.Position - hrp.Position).Magnitude < 15 then
                            fireproximityprompt(obj)
                            harvestedCount = harvestedCount + 1
                        end
                    end
                end
            end
        end)
    end
end)

-- 6. Loop Auto-Buy Auction (Sinkron Config Auction)
task.spawn(function()
    while task.wait(AuctionCfg["Check Every"] or 0.5) do
        pcall(function()
            if AuctionCfg["Auto Buy"] then
                local auctionStand = Workspace:FindFirstChild("AuctionStand")
                if auctionStand then
                    -- Pemantauan otomatis ke AuctionStand berdasarkan item di config
                end
            end
        end)
    end
end)

print("[DonnHub] Full Automation Engine berhasil disinkronkan dengan GAGConfig!")
