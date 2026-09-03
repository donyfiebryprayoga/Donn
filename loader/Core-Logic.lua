-- File: loader/Core-Logic.lua (Working Proximity Scanner & Safe Mover)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local Config = _G.GAGConfig or {}
local HarvestCfg = Config["Harvest"] or {}
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
MainFrame.Size = UDim2.new(0, 620, 0, 380)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(40, 40, 50)
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "DONNHUB  //  GROW A GARDEN 2 CONTROL PANEL"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.new(0, 35, 0, 35)
HideButton.Position = UDim2.new(1, -45, 0, 5)
HideButton.BackgroundTransparency = 1
HideButton.TextColor3 = Color3.fromRGB(160, 160, 180)
HideButton.TextSize = 16
HideButton.Font = Enum.Font.GothamBold
HideButton.Text = "—"
HideButton.Parent = Header

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, 90, 0, 35)
OpenButton.Position = UDim2.new(0, 15, 0.5, -17)
OpenButton.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
OpenButton.TextColor3 = Color3.fromRGB(0, 255, 150)
OpenButton.TextSize = 12
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Text = "OPEN HUB"
OpenButton.Visible = false
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 8)
OpenCorner.Parent = OpenButton

local OpenStroke = Instance.new("UIStroke")
OpenStroke.Color = Color3.fromRGB(40, 40, 50)
OpenStroke.Thickness = 1
OpenStroke.Parent = OpenButton

HideButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenButton.Visible = false
end)

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -30, 1, -55)
ContentArea.Position = UDim2.new(0, 15, 0, 45)
ContentArea.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
ContentArea.BackgroundTransparency = 0.4
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8)
ContentCorner.Parent = ContentArea

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(1, -30, 1, -20)
StatsLabel.Position = UDim2.new(0, 15, 0, 10)
StatsLabel.BackgroundTransparency = 1
StatsLabel.TextColor3 = Color3.fromRGB(210, 210, 225)
StatsLabel.TextSize = 13
StatsLabel.Font = Enum.Font.Code
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
StatsLabel.Text = "Menghubungkan mesin pemindai prompt aktif..."
StatsLabel.Parent = ContentArea

-- Live Counter & Stats Engine
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
                " [ ENGINE STATUS ] : Active Scanner\n [ UPTIME ]        : %s\n [ SHECKLES ]      : %s\n\n [ CONFIG SYNC ]\n   • Auto Harvest  : Active (ON)\n   • Walk Speed    : %s\n\n [ STATISTICS ]\n   • Triggered     : %d Prompts",
                uptimeFormatted, sheckles, 
                tostring(MiscCfg["Walk Speed"] or "Default"),
                harvestedCount
            )
        end)
    end
end)

-- ==========================================================
-- MESIN PROXIMITY SCANNER LANGSUNG (TANPA TELEPORT ERROR)
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

-- Pemindai ProximityPrompt Aktif di Sekitar Karakter
task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            if HarvestCfg["Auto Harvest"] then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local hrp = char.HumanoidRootPart
                    
                    -- Iterasi semua prompt di Workspace
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") then
                            local part = obj.Parent
                            if part and (part:IsA("BasePart") or part:IsA("Model")) then
                                local targetPos = part:IsA("Model") and part:GetModelCFrame().Position or part.Position
                                local dist = (targetPos - hrp.Position).Magnitude
                                
                                -- Jika prompt berada dalam jangkauan render/interaksi (< 25 stud), tembak langsung
                                if dist < 25 then
                                    fireproximityprompt(obj)
                                    harvestedCount = harvestedCount + 1
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

print("[DonnHub] Working Proximity Scanner Berhasil Dimuat!")
