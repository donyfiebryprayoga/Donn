-- File: loader/Core-Logic.lua (Instant Teleport Auto-Farm Engine)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local Config = _G.GAGConfig or {}
local HarvestCfg = Config["Harvest"] or {}
local PlantCfg = Config["Planting"] or {}
local PerfCfg = Config["Performance"] or {}
local MiscCfg = Config["Misc"] or {}

if CoreGui:FindFirstChild("DonnHubDashboard") then
    CoreGui.DonnHubDashboard:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DonnHubDashboard"
ScreenGui.Parent = CoreGui
ScreenGui.IgnoreGuiInset = true

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 460, 0, 260)
MainFrame.Position = UDim2.new(0.5, -230, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BackgroundTransparency = 0.08
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 10)
TopCorner.Parent = TopBar

local FixCover = Instance.new("Frame")
FixCover.Size = UDim2.new(1, 0, 0, 10)
FixCover.Position = UDim2.new(0, 0, 1, -10)
FixCover.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
FixCover.BorderSizePixel = 0
FixCover.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "DONNHUB  //  INSTANT AUTO-FARM"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.new(0, 30, 0, 30)
HideButton.Position = UDim2.new(1, -35, 0, 4)
HideButton.BackgroundTransparency = 1
HideButton.TextColor3 = Color3.fromRGB(160, 160, 180)
HideButton.TextSize = 18
HideButton.Font = Enum.Font.GothamBold
HideButton.Text = "-"
HideButton.Parent = TopBar

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, 85, 0, 32)
OpenButton.Position = UDim2.new(0, 15, 0.5, -16)
OpenButton.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
OpenButton.TextColor3 = Color3.fromRGB(0, 255, 150)
OpenButton.TextSize = 12
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Text = "OPEN HUB"
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

local ContentBox = Instance.new("Frame")
ContentBox.Size = UDim2.new(1, -24, 1, -58)
ContentBox.Position = UDim2.new(0, 12, 0, 48)
ContentBox.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
ContentBox.BackgroundTransparency = 0.4
ContentBox.BorderSizePixel = 0
ContentBox.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 6)
ContentCorner.Parent = ContentBox

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(1, -20, 1, -20)
StatsLabel.Position = UDim2.new(0, 10, 0, 10)
StatsLabel.BackgroundTransparency = 1
StatsLabel.TextColor3 = Color3.fromRGB(210, 210, 225)
StatsLabel.TextSize = 13
StatsLabel.Font = Enum.Font.Code
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
StatsLabel.Text = "Menghubungkan mesin teleport..."
StatsLabel.Parent = ContentBox

-- Live Counter
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

            StatsLabel.Text = string.format(
                " [ Status ] : Instant Farming Active\n [ Uptime ] : %s\n [ Sheckles ] : %s\n\n [ Harvest ] : ACTIVE\n [ Harvested Items ] : %d",
                uptimeFormatted, sheckles, harvestedCount
            )
        end)
    end
end)

-- ==========================================================
-- MESIN TELEPORT & AUTO-HARVEST INSTAN
-- ==========================================================
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

-- Loop Utama: Teleport instan ke tanaman di dalam folder _Gardens
task.spawn(function()
    while task.wait(1.5) do
        pcall(function()
            if HarvestCfg["Auto Harvest"] then
                local gardensFolder = Workspace:FindFirstChild("_Gardens")
                local char = LocalPlayer.Character
                if gardensFolder and char and char:FindFirstChild("HumanoidRootPart") then
                    local hrp = char.HumanoidRootPart
                    
                    for _, plot in pairs(gardensFolder:GetChildren()) do
                        for _, crop in pairs(plot:GetChildren()) do
                            local targetPart = crop:IsA("Model") and crop.PrimaryPart or (crop:IsA("BasePart") and crop or nil)
                            if targetPart then
                                -- Teleport langsung mendekati posisi tanaman
                                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                                task.wait(0.3)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- Loop Interaksi Prompt Otomatis
task.spawn(function()
    while task.wait(0.5) do
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

print("[DonnHub] Instant Teleport Engine Berhasil Diaktifkan!")
