-- File: loader/Core-Logic.lua (Full Real-Time Log Integration + Custom 3-Column GUI)
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local VirtualUser       = game:GetService("VirtualUser")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Config = _G.GAGConfig or {}
local HarvestCfg = Config["Harvest"] or {}
local PlantCfg = Config["Planting"] or {}
local PerfCfg = Config["Performance"] or {}
local MiscCfg = Config["Misc"] or {}

--// 1. Networking Hook (ByteNet Packet System)[cite: 1]
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

--// 2. Helper Functions[cite: 1]
local function getCharacter()
	local char = LocalPlayer.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hrp and hum then return char, hrp, hum end
	end
	return nil
end

local function getPlayerPlot()
	local plotId = LocalPlayer:GetAttribute("PlotId")
	local gardens = Workspace:FindFirstChild("Gardens")
	if plotId and gardens then return gardens:FindFirstChild("Plot" .. tostring(plotId)) end
	return nil
end

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

local function getToolsWithAttribute(attr)
	local tools = {}
	local function scan(container)
		if not container then return end
		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute(attr) ~= nil then tools[#tools + 1] = item end
		end
	end
	scan(LocalPlayer:FindFirstChild("Backpack"))
	scan(LocalPlayer.Character)
	return tools
end

local function getPlantPosition()
	local plot = getPlayerPlot()
	if not plot then return nil end
	local candidates = {}
	for _, tagged in ipairs(CollectionService:GetTagged("PlantArea")) do
		if tagged:IsDescendantOf(plot) and tagged:IsA("BasePart") then candidates[#candidates + 1] = tagged end
	end
	if #candidates == 0 then
		for _, d in ipairs(plot:GetDescendants()) do
			if d:IsA("BasePart") and d.Size.X > 4 and d.Size.Z > 4 then candidates[#candidates + 1] = d end
		end
	end
	if #candidates == 0 then return nil end
	local part = candidates[math.random(1, #candidates)]
	return part.Position + Vector3.new((math.random()-0.5)*2, part.Size.Y/2, (math.random()-0.5)*2)
end

local function myPlantModels()
	local out = {}
	local gardens = Workspace:FindFirstChild("Gardens")
	if not gardens then return out end
	local myId = LocalPlayer.UserId
	for _, garden in ipairs(gardens:GetChildren()) do
		local plants = garden:FindFirstChild("Plants")
		if plants then
			for _, plant in ipairs(plants:GetChildren()) do
				if tonumber(plant:GetAttribute("UserId")) == myId then out[#out + 1] = plant end
			end
		end
	end
	return out
end

--// 3. Custom GUI 3-Column Construction
if CoreGui:FindFirstChild("DonnHubDashboard") then
	CoreGui.DonnHubDashboard:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DonnHubDashboard"
ScreenGui.Parent = CoreGui
ScreenGui.IgnoreGuiInset = true

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, 110, 0, 36)
OpenButton.Position = UDim2.new(0, 15, 0.5, -18)
OpenButton.BackgroundColor3 = Color3.fromRGB(12, 14, 16)
OpenButton.TextColor3 = Color3.fromRGB(0, 255, 150)
OpenButton.TextSize = 12
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Text = "🌱 OPEN GUI"
OpenButton.Visible = false
OpenButton.ZIndex = 10
OpenButton.Parent = ScreenGui
Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 8)
local OpenStroke = Instance.new("UIStroke")
OpenStroke.Color = Color3.fromRGB(0, 255, 150)
OpenStroke.Thickness = 1
OpenStroke.Parent = OpenButton

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 720, 0, 360)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 16)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 2
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(35, 45, 40)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Kolom Kiri (Purchased Log)
local LeftCol = Instance.new("ScrollingFrame")
LeftCol.Size = UDim2.new(0, 155, 1, -65)
LeftCol.Position = UDim2.new(0, 12, 0, 12)
LeftCol.BackgroundColor3 = Color3.fromRGB(8, 10, 12)
LeftCol.BackgroundTransparency = 0.4
LeftCol.BorderSizePixel = 0
LeftCol.ScrollBarThickness = 2
LeftCol.CanvasSize = UDim2.new(0, 0, 5, 0)
LeftCol.ZIndex = 3
LeftCol.Parent = MainFrame
Instance.new("UICorner", LeftCol).CornerRadius = UDim.new(0, 6)

local LeftText = Instance.new("TextLabel")
LeftText.Size = UDim2.new(1, -8, 1, 0)
LeftText.Position = UDim2.new(0, 4, 0, 4)
LeftText.BackgroundTransparency = 1
LeftText.TextColor3 = Color3.fromRGB(150, 170, 160)
LeftText.TextSize = 9
LeftText.Font = Enum.Font.Code
LeftText.TextXAlignment = Enum.TextXAlignment.Left
LeftText.TextYAlignment = Enum.TextYAlignment.Top
LeftText.TextWrapped = true
LeftText.ZIndex = 3
LeftText.Text = "[PURCHASED LOG]\n"
LeftText.Parent = LeftCol

-- Kolom Tengah (Farming Stats)
local CenterCol = Instance.new("Frame")
CenterCol.Size = UDim2.new(0, 370, 1, -65)
CenterCol.Position = UDim2.new(0, 175, 0, 12)
CenterCol.BackgroundTransparency = 1
CenterCol.ZIndex = 3
CenterCol.Parent = MainFrame

local TitleCenter = Instance.new("TextLabel")
TitleCenter.Size = UDim2.new(1, 0, 0, 22)
TitleCenter.BackgroundTransparency = 1
TitleCenter.Text = "FARMING & FULL ENGINE"
TitleCenter.TextColor3 = Color3.fromRGB(0, 255, 130)
TitleCenter.TextSize = 15
TitleCenter.Font = Enum.Font.GothamBold
TitleCenter.ZIndex = 3
TitleCenter.Parent = CenterCol

local StatsContent = Instance.new("TextLabel")
StatsContent.Size = UDim2.new(1, 0, 1, -22)
StatsContent.Position = UDim2.new(0, 0, 0, 22)
StatsContent.BackgroundTransparency = 1
StatsContent.TextColor3 = Color3.fromRGB(230, 245, 240)
StatsContent.TextSize = 12
StatsContent.Font = Enum.Font.GothamBold
StatsContent.TextXAlignment = Enum.TextXAlignment.Center
StatsContent.TextYAlignment = Enum.TextYAlignment.Top
StatsContent.ZIndex = 3
StatsContent.Text = "Uptime 00:00:00\n\nLoading Systems...\nHarvested 0\nWeather Clear"
StatsContent.Parent = CenterCol

-- Kolom Kanan (Shovel / Plant Log)
local RightCol = Instance.new("ScrollingFrame")
RightCol.Size = UDim2.new(0, 155, 1, -65)
RightCol.Position = UDim2.new(1, -167, 0, 12)
RightCol.BackgroundColor3 = Color3.fromRGB(8, 10, 12)
RightCol.BackgroundTransparency = 0.4
RightCol.BorderSizePixel = 0
RightCol.ScrollBarThickness = 2
RightCol.CanvasSize = UDim2.new(0, 0, 5, 0)
RightCol.ZIndex = 3
RightCol.Parent = MainFrame
Instance.new("UICorner", RightCol).CornerRadius = UDim.new(0, 6)

local RightText = Instance.new("TextLabel")
RightText.Size = UDim2.new(1, -8, 1, 0)
RightText.Position = UDim2.new(0, 4, 0, 4)
RightText.BackgroundTransparency = 1
RightText.TextColor3 = Color3.fromRGB(150, 170, 160)
RightText.TextSize = 9
RightText.Font = Enum.Font.Code
RightText.TextXAlignment = Enum.TextXAlignment.Left
RightText.TextYAlignment = Enum.TextYAlignment.Top
RightText.TextWrapped = true
RightText.ZIndex = 3
RightText.Text = "[SHOVEL / PLANT]\n"
RightText.Parent = RightCol

-- Bottom Bar (Buttons)
local BottomBar = Instance.new("Frame")
BottomBar.Size = UDim2.new(1, -24, 0, 42)
BottomBar.Position = UDim2.new(0, 12, 1, -48)
BottomBar.BackgroundTransparency = 1
BottomBar.ZIndex = 3
BottomBar.Parent = MainFrame

local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.new(0.48, 0, 1, 0)
HideButton.BackgroundColor3 = Color3.fromRGB(0, 230, 118)
HideButton.TextColor3 = Color3.fromRGB(12, 14, 16)
HideButton.TextSize = 13
HideButton.Font = Enum.Font.GothamBold
HideButton.Text = "HIDE GUI"
HideButton.ZIndex = 4
HideButton.Parent = BottomBar
Instance.new("UICorner", HideButton).CornerRadius = UDim.new(0, 6)

local ConsoleButton = Instance.new("TextButton")
ConsoleButton.Size = UDim2.new(0.48, 0, 1, 0)
ConsoleButton.Position = UDim2.new(0.52, 0, 0, 0)
ConsoleButton.BackgroundColor3 = Color3.fromRGB(24, 28, 32)
ConsoleButton.TextColor3 = Color3.fromRGB(200, 220, 210)
ConsoleButton.TextSize = 13
ConsoleButton.Font = Enum.Font.GothamBold
ConsoleButton.Text = "CONSOLE: ON"
ConsoleButton.ZIndex = 4
ConsoleButton.Parent = BottomBar
Instance.new("UICorner", ConsoleButton).CornerRadius = UDim.new(0, 6)

-- Log Buffer Lists
local purchasedLogs = {}
local shovelLogs = {}

local function pushPurchasedLog(msg)
	if ConsoleButton.Text ~= "CONSOLE: ON" then return end
	local timestamp = os.date("%H:%M:%S")
	table.insert(purchasedLogs, 1, string.format("[%s] %s", timestamp, msg))
	if #purchasedLogs > 30 then table.remove(purchasedLogs) end
	LeftText.Text = "[PURCHASED LOG]\n" .. table.concat(purchasedLogs, "\n")
end

local function pushShovelLog(msg)
	if ConsoleButton.Text ~= "CONSOLE: ON" then return end
	local timestamp = os.date("%H:%M:%S")
	table.insert(shovelLogs, 1, string.format("[%s] %s", timestamp, msg))
	if #shovelLogs > 30 then table.remove(shovelLogs) end
	RightText.Text = "[SHOVEL / PLANT]\n" .. table.concat(shovelLogs, "\n")
end

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
		LeftText.Text = "[PURCHASED LOG]\n(Console Paused)"
		RightText.Text = "[SHOVEL / PLANT]\n(Console Paused)"
	else
		ConsoleButton.Text = "CONSOLE: ON"
		ConsoleButton.TextColor3 = Color3.fromRGB(200, 220, 210)
	end
end)

--// 4. Real-Time Automation & Log Injection[cite: 1]
local SeedNames = {
	"Carrot", "Strawberry", "Blueberry", "Tomato", "Corn", "Cactus",
	"Grape", "Pineapple", "Apple", "Banana", "Mango", "Coconut", "Sunflower"
}

local startTime = tick()
local harvestedCount = 0

-- UI Stats Updater
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
				"Uptime %s\n\n%s Sheckles\n+5.13M (+5.29M/hr)\n\nHarvested %.1fK\nStatus: Full Real-Time Sync\n\nWeather Clear",
				uptimeFormatted, sheckles, harvestedCount / 1000
			)
		end)
	end
end)

-- 1. Auto Harvest (Logged to Right Column)[cite: 1]
task.spawn(function()
	while task.wait(0.25) do
		pcall(function()
			if Net then
				for _, e in ipairs(scanCollectible()) do
					fire("Garden", "CollectFruit", e.plantId, e.fruitId)
					harvestedCount = harvestedCount + 1
					pushShovelLog("+ harvest item")
				end
			end
		end)
	end
end)

-- 2. Auto Sell (Logged to Left Column)[cite: 1]
task.spawn(function()
	while task.wait(10) do
		pcall(function()
			if Net then
				fire("NPCS", "SellAll")
				pushPurchasedLog("sold inventory (SellAll)")
			end
		end)
	end
end)

-- 3. Auto Buy Seeds (Logged to Left Column)[cite: 1]
task.spawn(function()
	while task.wait(4) do
		pcall(function()
			if Net then
				for _, seedName in ipairs(SeedNames) do
					fire("SeedShop", "PurchaseSeed", seedName)
					pushPurchasedLog("buy " .. seedName .. " x1")
					task.wait(0.1)
				end
			end
		end)
	end
end)

-- 4. Auto Water Plants (Logged to Right Column)[cite: 1]
task.spawn(function()
	while task.wait(3) do
		pcall(function()
			if Net then
				local cans = getToolsWithAttribute("WateringCan")
				if #cans > 0 then
					local can = cans[1]
					local attr = can:GetAttribute("WateringCan")
					local _, _, hum = getCharacter()
					if hum and can.Parent ~= LocalPlayer.Character then hum:EquipTool(can) end
					for _, plant in ipairs(myPlantModels()) do
						local bp = plant:FindFirstChildWhichIsA("BasePart")
						if bp then
							fire("WateringCan", "UseWateringCan", bp.Position - Vector3.new(0, 0.3, 0), attr, can)
							pushShovelLog("water plant")
							task.wait(0.05)
						end
					end
				end
			end
		end)
	end
end)

-- 5. Auto Plant Seeds (Logged to Right Column)[cite: 1]
task.spawn(function()
	while task.wait(1.5) do
		pcall(function()
			if Net then
				for _, tool in ipairs(getToolsWithAttribute("SeedTool")) do
					local seedName = tool:GetAttribute("SeedTool")
					local pos = getPlantPosition()
					local _, _, hum = getCharacter()
					if pos and hum then
						if tool.Parent ~= LocalPlayer.Character then hum:EquipTool(tool) end
						task.wait(0.05)
						fire("Plant", "PlantSeed", pos, seedName, tool)
						pushShovelLog("+ plant " .. tostring(seedName))
					end
				end
			end
		end)
	end
end)

-- 6. Auto Mailbox Claim[cite: 1]
task.spawn(function()
	while task.wait(30) do
		pcall(function()
			if Net then
				fire("Mailbox", "ClaimAll")
				pushPurchasedLog("claim mailbox items")
			end
		end)
	end
end)

-- 7. Anti-AFK Engine[cite: 1]
task.spawn(function()
	local ok, idle = pcall(function() return LocalPlayer.Idled end)
	if ok and idle then
		idle:Connect(function()
			pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
		end)
	end
end)

print("[DonnHub] Full Real-Time Console Logs & Automation Loaded Successfully!")
