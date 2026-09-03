-- File: loader/Core-Logic.lua (Custom Minimalist Dashboard GUI)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Hapus GUI lama jika ada agar tidak menumpuk
if CoreGui:FindFirstChild("DonnHubDashboard") then
    CoreGui.DonnHubDashboard:Destroy()
end

-- 1. Buat ScreenGui Utama
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DonnHubDashboard"
ScreenGui.Parent = CoreGui
ScreenGui.IgnoreGuiInset = true

-- 2. Panel Kotak Tengah (Farming Dashboard)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 240)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Judul "FARMING"
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "FARMING"
Title.TextColor3 = Color3.fromRGB(0, 255, 128)
Title.TextSize = 18
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

-- Label Informasi Statistik (Uptime, Sheckles, Planted, dll)
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(1, -20, 1, -50)
StatsLabel.Position = UDim2.new(0, 10, 0, 40)
StatsLabel.BackgroundTransparency = 1
StatsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatsLabel.TextSize = 14
StatsLabel.Font = Enum.Font.Code
StatsLabel.TextXAlignment = Enum.TextXAlignment.Center
StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
StatsLabel.Text = [[
Uptime 00:58:09
43.62M Sheckles
+5.13M (+5.29M/hr)
Planted 151     Harvested 35.6K
Pets 0     Sprinklers 22
Event Seeds 0 taken / 0 missed (G 0 R 0 M 0)
Weather Clear
]]
StatsLabel.Parent = MainFrame

-- Tombol HIDE GUI di Bawah
local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.new(0, 180, 0, 30)
HideButton.Position = UDim2.new(0.5, -90, 1, -35)
HideButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
HideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HideButton.TextSize = 14
HideButton.Font = Enum.Font.SourceSansBold
HideButton.Text = "HIDE GUI"
HideButton.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = HideButton

-- Fungsi Toggle Hide/Show GUI
local hidden = false
HideButton.MouseButton1Click:Connect(function()
    hidden = not hidden
    MainFrame.Visible = not hidden
end)

print("[DonnHub] Custom Minimalist GUI Berhasil Dimuat!")
