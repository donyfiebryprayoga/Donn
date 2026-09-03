-- File: loader/Core-Logic.lua (GAG2 Safe Error-Resilient Engine)
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local VirtualUser       = game:GetService("VirtualUser")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local TweenService      = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Config        = _G.GAGConfig or {}
local HarvestCfg    = Config["Harvest"] or {}
local PlantCfg      = Config["Planting"] or {}
local MoneyCfg      = Config["Money"] or {}
local NeverSellCfg  = Config["Never Sell"] or {}
local PetsCfg       = Config["Pets"] or {}
local GearCfg       = Config["Gear"] or {}
local EventSeedCfg  = Config["Event Seeds"] or {}
local MailCfg       = Config["Mail"] or {}
local MiscCfg       = Config["Misc"] or {}
local FriendsCfg    = Config["Friends"] or {}
local GuildCfg      = Config["Guild"] or {}
local AuctionCfg    = Config["Auction"] or {}
local EggsCfg       = Config["Eggs"] or {}
local PerfCfg       = Config["Performance"] or {}
local DebugCfg      = Config["Debug"] or {}

local purchaseCounters = {}
local rareCounters = {
	Gold = 0,
	Rainbow = 0,
	Mega = 0
}

local lastPlantedName = "None"

--// 1. Delta File Logging System
local function writeDebugLog(fileName, message)
	pcall(function()
		if DebugCfg["Log To File"] and writefile and appendfile then
			local folderName = "GAG_Logs"
			if makefolder and not isfolder(folderName) then
				makefolder(folderName)
			end
			local filePath = folderName .. "/" .. fileName .. ".txt"
			local timestamp = os.date("%Y-%m-%d %H:%M:%S")
			local formattedMessage = string.format("[%s] %s\n", timestamp, message)
			if not isfile(filePath) then
				writefile(filePath, formattedMessage)
			else
				appendfile(filePath, formattedMessage)
			end
		end
	end)
end

--// 2. Networking Hook (ByteNet Packet System - GAG2 Robust Routing)
local Net
pcall(function()
	Net = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))
end)

local function fire(category, action, ...)
	if not Net then return end
	local ok, res = pcall(function()
		if type(Net) == "table" then
			if Net[category] and type(Net[category].Fire) == "function" then
				return Net[category]:Fire(action, ...)
			elseif Net[category] and type(Net[category][action]) == "function" then
				return Net[category][action](...)
			elseif Net[category] and type(Net[category][action]) == "table" and type(Net[category][action].Fire) == "function" then
				return Net[category][action]:Fire(...)
			end
		end
	end)
	return res
end

local function invoke(path, ...)
	local n
	if type(path) == "table" then
		n = Net
		for _, k in ipairs(path) do 
			n = n and n[k] 
		end
	else 
		n = Net and Net[path] 
	end
	
	if n then
		if type(n.Fire) == "function" then
			local ok, res = pcall(function() return n:Fire(...) end)
			if ok then return res end
		elseif type(n.Invoke) == "function" then
			local ok, res = pcall(function() return n:Invoke(...) end)
			if ok then return res end
		elseif type(n) == "function" then
			local ok, res = pcall(function() return n(...) end)
			if ok then return res end
		end
	end
	return nil
end

--// 3. Helper Functions
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
	local gardens = Workspace:FindFirstChild("Gardens")
	if not gardens then return nil end
	local myId = LocalPlayer.UserId
	
	for _, plot in ipairs(gardens:GetChildren()) do
		if tonumber(plot:GetAttribute("UserId")) == myId then
			return plot
		end
	end
	
	local plotId = LocalPlayer:GetAttribute("PlotId")
	if plotId and gardens:FindFirstChild("Plot" .. tostring(plotId)) then
		return gardens:FindFirstChild("Plot" .. tostring(plotId))
	end
	
	return gardens:GetChildren()[1]
end

local function moveToGarden()
	pcall(function()
		local _, hrp, _ = getCharacter()
		local plot = getPlayerPlot()
		if hrp and plot then
			local targetPart = plot:FindFirstChild("Base") or plot:FindFirstChild("PlotBase") or plot:FindFirstChildOfClass("BasePart")
			if targetPart then
				local destPos = targetPart.Position + Vector3.new(0, 4, 0)
				if (hrp.Position - destPos).Magnitude > 25 then
					if MiscCfg["Fast Travel"] then
						local tweenInfo = TweenInfo.new((hrp.Position - destPos).Magnitude / (MiscCfg["Slide Speed"] or 30), Enum.EasingStyle.Linear)
						local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(destPos)})
						tween:Play()
					else
						hrp.CFrame = CFrame.new(destPos)
					end
				end
			end
		end
	end)
end

local function hasItemInInventory(itemName)
	local function scan(container)
		if not container then return false end
		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool") and (string.lower(item.Name) == string.lower(itemName) or item:GetAttribute("EggName") == itemName) then
				return true
			end
		end
		return false
	end
	if scan(LocalPlayer:FindFirstChild("Backpack")) then return true end
	if scan(LocalPlayer.Character) then return true end
	return false
end

local function scanCollectibleDetailed()
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
					local plantName = plant:GetAttribute("SeedName") or plant.Name or "Crop"
					local fruitsFolder = plant:FindFirstChild("Fruits")
					if fruitsFolder and #fruitsFolder:GetChildren() > 0 then
						for _, fruit in ipairs(fruitsFolder:GetChildren()) do
							local fruitId = fruit:GetAttribute("FruitId")
							if typeof(fruitId) == "string" then
								local age, maxAge = fruit:GetAttribute("Age"), fruit:GetAttribute("MaxAge")
								local ripe = (typeof(age) ~= "number" or typeof(maxAge) ~= "number") or (age >= maxAge)
								if ripe then out[#out + 1] = { plantId = plantId, fruitId = fruitId, name = plantName } end
							end
						end
					else
						out[#out + 1] = { plantId = plantId, fruitId = "", name = plantName }
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

local function getActiveWeather()
	local currentWeather = "Sunny"
	pcall(function()
		if Workspace:GetAttribute("Weather") then
			currentWeather = tostring(Workspace:GetAttribute("Weather"))
		elseif ReplicatedStorage:FindFirstChild("WeatherData") then
			local wData = ReplicatedStorage.WeatherData
			if wData:IsA("StringValue") then currentWeather = wData.Value
			elseif wData:GetAttribute("Current") then currentWeather = tostring(wData:GetAttribute("Current")) end
		else
			local clockTime = Lighting.ClockTime
			if clockTime < 6 or clockTime > 18 then
				currentWeather = "Night"
			elseif Lighting:FindFirstChild("Atmosphere") and Lighting.Atmosphere.Density > 0.4 then
				currentWeather = "Cloudy"
			end
		end
	end)
	return currentWeather
end

--// 4. Bulletproof GUI Setup (Safe Container Generation)
local parentUI = CoreGui
pcall(function()
	if gethui then
		parentUI = gethui()
	elseif syn and syn.protect_gui then
		parentUI = CoreGui
	else
		parentUI = LocalPlayer:WaitForChild("PlayerGui")
	end
end)

for _, guiName in ipairs({"DonnHubDashboard", "GAGHubGui", "DonnHubGui"}) do
	if parentUI:FindFirstChild(guiName) then
		parentUI[guiName]:Destroy()
	end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DonnHubDashboard"
ScreenGui.Parent = parentUI
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.Position = UDim2.new(0, 0, 0, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 14)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 2
MainFrame.Parent = ScreenGui

local Container = Instance.new("Frame")
Container.Size = UDim2.new(0, 780, 0, 480)
Container.Position = UDim2.new(0.5, -390, 0.5, -240)
Container.BackgroundColor3 = Color3.fromRGB(14, 18, 16)
Container.BackgroundTransparency = 0.05
Container.BorderSizePixel = 0
Container.ZIndex = 3
Container.Parent = MainFrame
Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 12)
local ContainerStroke = Instance.new("UIStroke")
ContainerStroke.Color = Color3.fromRGB(0, 255, 130)
ContainerStroke.Thickness = 1.5
ContainerStroke.Parent = Container

-- Kolom Kiri (Purchased Log)
local LeftCol = Instance.new("ScrollingFrame")
LeftCol.Size = UDim2.new(0, 175, 1, -85)
LeftCol.Position = UDim2.new(0, 15, 0, 15)
LeftCol.BackgroundColor3 = Color3.fromRGB(8, 10, 12)
LeftCol.BackgroundTransparency = 0.4
LeftCol.BorderSizePixel = 0
LeftCol.ScrollBarThickness = 2
LeftCol.CanvasSize = UDim2.new(0, 0, 5, 0)
LeftCol.ZIndex = 4
LeftCol.Parent = Container
Instance.new("UICorner", LeftCol).CornerRadius = UDim.new(0, 8)

local LeftText = Instance.new("TextLabel")
LeftText.Size = UDim2.new(1, -8, 1, 0)
LeftText.Position = UDim2.new(0, 4, 0, 4)
LeftText.BackgroundTransparency = 1
LeftText.TextColor3 = Color3.fromRGB(150, 170, 160)
LeftText.TextSize = 10
LeftText.Font = Enum.Font.Code
LeftText.TextXAlignment = Enum.TextXAlignment.Left
LeftText.TextYAlignment = Enum.TextYAlignment.Top
LeftText.TextWrapped = true
LeftText.ZIndex = 4
LeftText.Text = "[PURCHASED LOG]\n"
LeftText.Parent = LeftCol

-- Kolom Tengah (Farming Stats)
local CenterCol = Instance.new("Frame")
CenterCol.Size = UDim2.new(0, 390, 1, -85)
CenterCol.Position = UDim2.new(0, 195, 0, 15)
CenterCol.BackgroundTransparency = 1
CenterCol.ZIndex = 4
CenterCol.Parent = Container

local TitleCenter = Instance.new("TextLabel")
TitleCenter.Size = UDim2.new(1, 0, 0, 25)
TitleCenter.BackgroundTransparency = 1
TitleCenter.Text = "FARMING & FULL CONFIG ENGINE"
TitleCenter.TextColor3 = Color3.fromRGB(0, 255, 130)
TitleCenter.TextSize = 16
TitleCenter.Font = Enum.Font.GothamBold
TitleCenter.ZIndex = 4
TitleCenter.Parent = CenterCol

local StatsContent = Instance.new("TextLabel")
StatsContent.Size = UDim2.new(1, 0, 1, -25)
StatsContent.Position = UDim2.new(0, 0, 0, 25)
StatsContent.BackgroundTransparency = 1
StatsContent.TextColor3 = Color3.fromRGB(230, 245, 240)
StatsContent.TextSize = 13
StatsContent.Font = Enum.Font.GothamBold
StatsContent.TextXAlignment = Enum.TextXAlignment.Center
StatsContent.TextYAlignment = Enum.TextYAlignment.Top
StatsContent.ZIndex = 4
StatsContent.Text = "Uptime 00:00:00\n\nLoading Config Rules...\nPlants: 0 / 0\nHarvested 0\nWeather: Sunny"
StatsContent.Parent = CenterCol

-- Sub Status Bar di Bawah Harvest
local SubStatusBar = Instance.new("Frame")
SubStatusBar.Size = UDim2.new(1, -20, 0, 26)
SubStatusBar.Position = UDim2.new(0, 10, 0, 150)
SubStatusBar.BackgroundColor3 = Color3.fromRGB(22, 35, 28)
SubStatusBar.BackgroundTransparency = 0.1
SubStatusBar.BorderSizePixel = 0
SubStatusBar.ZIndex = 5
SubStatusBar.Parent = CenterCol
Instance.new("UICorner", SubStatusBar).CornerRadius = UDim.new(0, 6)
local SubStatusStroke = Instance.new("UIStroke")
SubStatusStroke.Color = Color3.fromRGB(255, 200, 0)
SubStatusStroke.Thickness = 1.2
SubStatusStroke.Parent = SubStatusBar

local SubStatusText = Instance.new("TextLabel")
SubStatusText.Size = UDim2.new(1, 0, 1, 0)
SubStatusText.BackgroundTransparency = 1
SubStatusText.TextColor3 = Color3.fromRGB(255, 235, 100)
SubStatusText.TextSize = 11
SubStatusText.Font = Enum.Font.GothamBold
SubStatusText.TextXAlignment = Enum.TextXAlignment.Center
SubStatusText.TextYAlignment = Enum.TextYAlignment.Center
SubStatusText.ZIndex = 6
SubStatusText.Text = "Status: Initializing Engine..."
SubStatusText.Parent = SubStatusBar

-- Kolom Kanan (Shovel / Rare Seed Log)
local RightCol = Instance.new("ScrollingFrame")
RightCol.Size = UDim2.new(0, 175, 1, -85)
RightCol.Position = UDim2.new(1, -190, 0, 15)
RightCol.BackgroundColor3 = Color3.fromRGB(8, 10, 12)
RightCol.BackgroundTransparency = 0.4
RightCol.BorderSizePixel = 0
RightCol.ScrollBarThickness = 2
RightCol.CanvasSize = UDim2.new(0, 0, 5, 0)
RightCol.ZIndex = 4
RightCol.Parent = Container
Instance.new("UICorner", RightCol).CornerRadius = UDim.new(0, 8)

local RightText = Instance.new("TextLabel")
RightText.Size = UDim2.new(1, -8, 1, 0)
RightText.Position = UDim2.new(0, 4, 0, 4)
RightText.BackgroundTransparency = 1
RightText.TextColor3 = Color3.fromRGB(150, 170, 160)
RightText.TextSize = 10
RightText.Font = Enum.Font.Code
RightText.TextXAlignment = Enum.TextXAlignment.Left
RightText.TextYAlignment = Enum.TextYAlignment.Top
RightText.TextWrapped = true
RightText.ZIndex = 4
RightText.Text = "[PLANT / RARE SEED]\n"
RightText.Parent = RightCol

-- Bottom Bar
local BottomBar = Instance.new("Frame")
BottomBar.Size = UDim2.new(1, -30, 0, 85)
BottomBar.Position = UDim2.new(0, 15, 1, -90)
BottomBar.BackgroundTransparency = 1
BottomBar.ZIndex = 4
BottomBar.Parent = Container

local RareCounterLabel = Instance.new("TextLabel")
RareCounterLabel.Size = UDim2.new(1, 0, 0, 18)
RareCounterLabel.Position = UDim2.new(0, 0, 0, 0)
RareCounterLabel.BackgroundTransparency = 1
RareCounterLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
RareCounterLabel.TextSize = 11
RareCounterLabel.Font = Enum.Font.GothamBold
RareCounterLabel.TextXAlignment = Enum.TextXAlignment.Center
RareCounterLabel.TextYAlignment = Enum.TextYAlignment.Center
RareCounterLabel.ZIndex = 5
RareCounterLabel.Text = "G 0 R 0 M 0"
RareCounterLabel.Parent = BottomBar

local CompactInfoLabel = Instance.new("TextLabel")
CompactInfoLabel.Size = UDim2.new(1, 0, 0, 18)
CompactInfoLabel.Position = UDim2.new(0, 0, 0, 18)
CompactInfoLabel.BackgroundTransparency = 1
CompactInfoLabel.TextColor3 = Color3.fromRGB(150, 230, 200)
CompactInfoLabel.TextSize = 10
CompactInfoLabel.Font = Enum.Font.Gotham
CompactInfoLabel.TextXAlignment = Enum.TextXAlignment.Center
CompactInfoLabel.TextYAlignment = Enum.TextYAlignment.Center
CompactInfoLabel.ZIndex = 5
CompactInfoLabel.Text = "Plant: 0 | Sell: 20s | Gear: None | Last: None"
CompactInfoLabel.Parent = BottomBar

local ConsoleButton = Instance.new("TextButton")
ConsoleButton.Size = UDim2.new(0, 120, 0, 18)
ConsoleButton.Position = UDim2.new(0.5, -60, 0, 38)
ConsoleButton.BackgroundColor3 = Color3.fromRGB(22, 28, 25)
ConsoleButton.TextColor3 = Color3.fromRGB(180, 220, 200)
ConsoleButton.TextSize = 9
ConsoleButton.Font = Enum.Font.GothamBold
ConsoleButton.Text = "CONSOLE: ON"
ConsoleButton.ZIndex = 5
ConsoleButton.Parent = BottomBar
Instance.new("UICorner", ConsoleButton).CornerRadius = UDim.new(0, 5)
local ConsoleStroke = Instance.new("UIStroke")
ConsoleStroke.Color = Color3.fromRGB(0, 255, 130)
ConsoleStroke.Transparency = 0.5
ConsoleStroke.Parent = ConsoleButton

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 130, 0, 22)
ToggleButton.Position = UDim2.new(0.5, -65, 0, 58)
ToggleButton.BackgroundColor3 = Color3.fromRGB(15, 22, 18)
ToggleButton.TextColor3 = Color3.fromRGB(0, 255, 150)
ToggleButton.TextSize = 11
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "🌱 HIDE GUI"
ToggleButton.ZIndex = 5
ToggleButton.Parent = BottomBar
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 6)
local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 255, 150)
ToggleStroke.Thickness = 1.2
ToggleStroke.Parent = ToggleButton

local purchasedLogs = {}
local plantShovelLogs = {}
local currentStatus = "Starting Engine"

local function updateTopStatus(text)
	currentStatus = text
	SubStatusText.Text = "Status: " .. text
end

local function updateRareCounterDisplay()
	RareCounterLabel.Text = string.format("G %d R %d M %d", rareCounters.Gold, rareCounters.Rainbow, rareCounters.Mega)
end

local function updateCompactInfo(totalPlants)
	local sellEvery = HarvestCfg["Sell Every"] or 20
	local gearBuyList = GearCfg["Buy Gear"] or {}
	local activeGear = (#gearBuyList > 0) and tostring(gearBuyList[1]) or "None"
	CompactInfoLabel.Text = string.format("Plant: %d | Sell: %ds | Gear: %s | Last: %s", totalPlants, sellEvery, activeGear, lastPlantedName)
end

local function pushPurchasedLog(msg)
	if ConsoleButton.Text ~= "CONSOLE: ON" then return end
	local timestamp = os.date("%H:%M:%S")
	table.insert(purchasedLogs, 1, string.format("[%s] %s", timestamp, msg))
	if #purchasedLogs > 30 then table.remove(purchasedLogs) end
	LeftText.Text = "[PURCHASED LOG]\n" .. table.concat(purchasedLogs, "\n")
	writeDebugLog("GAG_Purchased_Log", msg)
end

local function pushPlantShovelLog(msg)
	if ConsoleButton.Text ~= "CONSOLE: ON" then return end
	local timestamp = os.date("%H:%M:%S")
	table.insert(plantShovelLogs, 1, string.format("[%s] %s", timestamp, msg))
	if #plantShovelLogs > 30 then table.remove(plantShovelLogs) end
	RightText.Text = "[PLANT / RARE SEED]\n" .. table.concat(plantShovelLogs, "\n")
	writeDebugLog("GAG_Plant_Shovel_Log", msg)
end

ToggleButton.MouseButton1Click:Connect(function()
	if Container.Visible then
		Container.Visible = false
		MainFrame.BackgroundTransparency = 1
		ToggleButton.Text = "🌱 OPEN GUI"
	else
		Container.Visible = true
		MainFrame.BackgroundTransparency = 0.15
		ToggleButton.Text = "🌱 HIDE GUI"
	end
end)

ConsoleButton.MouseButton1Click:Connect(function()
	if ConsoleButton.Text == "CONSOLE: ON" then
		ConsoleButton.Text = "CONSOLE: OFF"
		ConsoleButton.TextColor3 = Color3.fromRGB(120, 120, 120)
		LeftText.Text = "[PURCHASED LOG]\n(Console Paused)"
		RightText.Text = "[PLANT / RARE SEED]\n(Console Paused)"
	else
		ConsoleButton.Text = "CONSOLE: ON"
		ConsoleButton.TextColor3 = Color3.fromRGB(180, 220, 200)
	end
end)

--// 5. Config Enforcement & Safe Execution Helpers
local function isSeedAllowed(seedName, toolObj)
	if not seedName then return false end
	
	if toolObj then
		local isGold = toolObj:GetAttribute("Gold") or false
		local isRainbow = toolObj:GetAttribute("Rainbow") or false
		local isMega = toolObj:GetAttribute("Mega") or false
		
		if EventSeedCfg["Only Gold"] and not isGold then return false end
		if EventSeedCfg["Only Rainbow"] and not isRainbow then return false end
		if EventSeedCfg["Only Mega"] and not isMega then return false end
	end

	local dontPlant = PlantCfg["Don't Plant"] or {}
	for _, dp in ipairs(dontPlant) do
		if string.lower(tostring(seedName)) == string.lower(tostring(dp)) then
			return false
		end
	end

	local onlyPlant = PlantCfg["Only Plant"] or {}
	if type(onlyPlant) == "table" and #onlyPlant > 0 then
		local found = false
		for _, op in ipairs(onlyPlant) do
			if string.lower(tostring(seedName)) == string.lower(tostring(op)) then
				found = true
				break
			end
		end
		if not found then return false end
	end

	return true
end

--// 6. Automation Loops Engine
local startTime = tick()
local initialSheckles = 0
local currentShecklesNum = 0
local harvestedCount = 0

pcall(function()
	if LocalPlayer:FindFirstChild("leaderstats") then
		local cash = LocalPlayer.leaderstats:FindFirstChild("Sheckles") or LocalPlayer.leaderstats:FindFirstChild("Cash")
		if cash then initialSheckles = tonumber(cash.Value) or 0 end
	end
end)

-- Misc & Performance Integration
task.spawn(function()
	while task.wait(3) do
		pcall(function()
			if PerfCfg["FPS Cap"] and PerfCfg["FPS Cap"] > 0 and setfpscap then
				setfpscap(PerfCfg["FPS Cap"])
			end
			if PerfCfg["Low Graphics"] then
				Lighting.GlobalShadows = false
				Lighting.FogEnd = 999999
			end
			local hum = select(3, getCharacter())
			if hum and MiscCfg["Walk Speed"] and MiscCfg["Walk Speed"] > 0 then
				hum.WalkSpeed = MiscCfg["Walk Speed"]
			end
		end)
	end
end)

-- Auto Return to Garden Loop
task.spawn(function()
	while task.wait(3) do
		pcall(function()
			if MiscCfg["Auto Return To Garden"] then
				moveToGarden()
			end
		end)
	end
end)

-- UI Status Refresh Loop
task.spawn(function()
	while task.wait(1) do
		pcall(function()
			local uptimeSeconds = math.floor(tick() - startTime)
			local hours = math.floor(uptimeSeconds / 3600)
			local minutes = math.floor((uptimeSeconds % 3600) / 60)
			local seconds = uptimeSeconds % 60
			local uptimeFormatted = string.format("%02d:%02d:%02d", hours, minutes, seconds)

			local shecklesStr = "43.62M"
			if LocalPlayer:FindFirstChild("leaderstats") then
				local cash = LocalPlayer.leaderstats:FindFirstChild("Sheckles") or LocalPlayer.leaderstats:FindFirstChild("Cash")
				if cash then
					currentShecklesNum = tonumber(cash.Value) or currentShecklesNum
					shecklesStr = tostring(cash.Value)
				end
			end

			local earned = currentShecklesNum - initialSheckles
			local hoursElapsed = uptimeSeconds / 3600
			local ratePerHr = hoursElapsed > 0 and (earned / hoursElapsed) or 0
			local rateStr = string.format("%.2fM/hr", ratePerHr / 1000000)

			local currentPlantsTotal = #myPlantModels()
			local plantLimitConfig = PlantCfg["Plant Limit"] or 69
			local plantLimitStr = plantLimitConfig > 0 and tostring(plantLimitConfig) or "OFF"
			local liveWeather = getActiveWeather()

			StatsContent.Text = string.format(
				"Uptime %s\n\n%s Sheckles\n+%s\n\nPlants: %d / %s\nHarvested %.1fK\n\nWeather: %s",
				uptimeFormatted, shecklesStr, rateStr, currentPlantsTotal, plantLimitStr, harvestedCount / 1000, liveWeather
			)

			updateCompactInfo(currentPlantsTotal)
		end)
	end
end)

-- 1. Harvest & Reliable Selling Loop
task.spawn(function()
	while task.wait(1.0) do
		pcall(function()
			if HarvestCfg["Auto Harvest"] ~= false and Net then
				local list = scanCollectibleDetailed()
				local dontHarvestList = HarvestCfg["Don't Harvest"] or {}
				
				if #list > 0 then
					for _, e in ipairs(list) do
						local skip = false
						for _, dh in ipairs(dontHarvestList) do
							if string.lower(e.name) == string.lower(dh) then skip = true break end
						end
						
						if not skip then
							updateTopStatus("Harvesting: " .. tostring(e.name))
							local collectRes = fire("Garden", "CollectFruit", e.plantId, e.fruitId)
							
							if collectRes == "Full" or collectRes == false or #list >= (HarvestCfg["Sell At"] or 75) then
								updateTopStatus("Inventory Full / Sell At Reached! Selling...")
								fire("NPCS", "SellAll")
								invoke({ "NPCS", "SellAll" })
								pushPurchasedLog("sold inventory (Sell Trigger)")
							end
							
							harvestedCount = harvestedCount + 1
							task.wait(0.04)
						end
					end
				else
					updateTopStatus("Idle / Running")
				end
			end
		end)
	end
end)

-- 2. Timed Sell Loop (Sell Every)
task.spawn(function()
	local sellInterval = HarvestCfg["Sell Every"] or 20
	if sellInterval > 0 then
		while task.wait(sellInterval) do
			pcall(function()
				if HarvestCfg["Auto Harvest"] ~= false and Net then
					updateTopStatus("Selling Fruit / Inventory (Interval)...")
					fire("NPCS", "SellAll")
					invoke({ "NPCS", "SellAll" })
					pushPurchasedLog("sold inventory (Sell Every)")
				end
			end)
		end
	end
end)

-- 3. Buy Seeds Loop
task.spawn(function()
	while task.wait(3) do
		pcall(function()
			if Net then
				local seedsToBuyMap = PlantCfg["Buy Seeds"] or {}
				local keepSeedsMap = PlantCfg["Keep Seeds"] or {}
				
				local combinedBuyList = {}
				for k, v in pairs(seedsToBuyMap) do combinedBuyList[k] = v end
				for k, v in pairs(keepSeedsMap) do combinedBuyList[k] = v end

				for seedName, maxTarget in pairs(combinedBuyList) do
					if type(seedName) == "string" then
						local dontBuyList = PlantCfg["Don't Buy"] or {}
						local isBlocked = false
						for _, db in ipairs(dontBuyList) do
							if string.lower(seedName) == string.lower(db) then isBlocked = true break end
						end

						if not isBlocked then
							updateTopStatus("Buying Seed: " .. tostring(seedName))
							local res = invoke({ "SeedShop", "PurchaseSeed" }, seedName) or fire("SeedShop", "PurchaseSeed", seedName)
							if res ~= false and res ~= nil then
								pushPurchasedLog(string.format("beli benih %s", seedName))
							end
							task.wait(0.15)
						end
					end
				end
			end
		end)
	end
end)

-- 4. Buy Gear Loop
local gearBuyList = GearCfg["Buy Gear"] or {}
task.spawn(function()
	while task.wait(10) do
		pcall(function()
			if GearCfg["Auto Buy"] and Net then
				for _, gearName in ipairs(gearBuyList) do
					updateTopStatus("Buying Gear: " .. tostring(gearName))
					local res = invoke({ "GearShop", "PurchaseGear" }, gearName) or fire("GearShop", "PurchaseGear", gearName)
					if res ~= false and res ~= nil then
						pushPurchasedLog("beli gear " .. tostring(gearName))
					end
					task.wait(0.5)
				end
			end
		end)
	end
end)

-- 5. Plant & Shovel Loop
task.spawn(function()
	while task.wait(1.2) do
		pcall(function()
			if PlantCfg["Auto Plant"] ~= false and Net then
				local plantLimit = PlantCfg["Plant Limit"] or 69
				local plants = myPlantModels()
				
				if plantLimit > 0 and #plants > plantLimit then
					local neverShovel = PlantCfg["Never Shovel"] or {}
					for _, p in ipairs(plants) do
						if #myPlantModels() <= plantLimit then break end
						if p and p:GetAttribute("PlantId") then
							local pName = p:GetAttribute("SeedName") or p.Name or "Unknown Crop"
							local safe = false
							
							for _, ns in ipairs(neverShovel) do
								if string.lower(pName) == string.lower(ns) then safe = true break end
							end
							
							if string.lower(pName):find("eclipse bloom") then
								safe = true
							end

							local isGold = p:GetAttribute("Gold") or false
							local isRainbow = p:GetAttribute("Rainbow") or false
							local isMega = p:GetAttribute("Mega") or false
							
							if PlantCfg["Shovel Mutated"] == false and (isGold or isRainbow or isMega) then
								safe = true
							end

							local plantTier = string.lower(tostring(p:GetAttribute("Tier") or p:GetAttribute("Rarity") or ""))
							
							if plantTier == "mythic" or plantTier == "super" or plantTier == "secret" then
								safe = true
							end

							if not safe then
								updateTopStatus("Replacing over limit: " .. tostring(pName))
								local successShovel = pcall(function()
									fire("Garden", "ShovelPlant", p:GetAttribute("PlantId"))
								end)
								
								if successShovel then
									pushPlantShovelLog(string.format("[REPLACE] Shovel %s", tostring(pName)))
								else
									pushPlantShovelLog(string.format("[GAGAL] Shovel %s", tostring(pName)))
								end
								task.wait(0.3)
								break
							end
						end
					end
				end

				for _, tool in ipairs(getToolsWithAttribute("SeedTool")) do
					local seedName = tool:GetAttribute("SeedTool") or "Seed"
					if isSeedAllowed(seedName, tool) then
						local isGold = tool:GetAttribute("Gold") or false
						local isRainbow = tool:GetAttribute("Rainbow") or false
						local isMega = tool:GetAttribute("Mega") or false
						
						local variantTag = ""
						if isGold then
							variantTag = "[GOLD] "
							rareCounters.Gold = rareCounters.Gold + 1
							updateRareCounterDisplay()
						elseif isRainbow then
							variantTag = "[RAINBOW] "
							rareCounters.Rainbow = rareCounters.Rainbow + 1
							updateRareCounterDisplay()
						elseif isMega then
							variantTag = "[MEGA] "
							rareCounters.Mega = rareCounters.Mega + 1
							updateRareCounterDisplay()
						end

						lastPlantedName = tostring(seedName)
						updateTopStatus("Planting: " .. variantTag .. seedName)
						local pos = getPlantPosition()
						local _, _, hum = getCharacter()
						if pos and hum then
							if tool.Parent ~= LocalPlayer.Character then hum:EquipTool(tool) end
							task.wait(0.05)
							
							local successPlant = pcall(function()
								fire("Plant", "PlantSeed", pos, seedName, tool)
							end)
							
							if successPlant then
								pushPlantShovelLog(string.format("[SUKSES] Tanam %s%s", variantTag, seedName))
							else
								pushPlantShovelLog(string.format("[GAGAL] Tanam %s%s", variantTag, seedName))
							end
							task.wait(0.3)
						end
					end
				end
			end
		end)
	end
end)

-- 6. Open Eggs Loop
task.spawn(function()
	while task.wait(4) do
		pcall(function()
			if EggsCfg["Auto Open"] and Net then
				local openList = EggsCfg["Open"] or {"all"}
				for _, eggName in ipairs(openList) do
					if hasItemInInventory(eggName) or eggName == "all" then
						updateTopStatus("Opening Egg...")
						local eggRes = invoke({ "Egg", "OpenEgg" }, eggName) or fire("Egg", "OpenEgg", eggName)
						if eggRes ~= false and eggRes ~= nil then
							pushPurchasedLog("buka egg")
						end
					end
					task.wait(0.5)
				end
			end
		end)
	end
end)

-- 7. Auctioneer Auto Buy Loop
task.spawn(function()
	while task.wait(AuctionCfg["Check Every"] or 0.2) do
		pcall(function()
			if AuctionCfg["Auto Buy"] and Net then
				local buyItems = AuctionCfg["Buy"] or {}
				for itemName, maxPrice in pairs(buyItems) do
					updateTopStatus("Checking Auction: " .. tostring(itemName))
					local ok, aucRes = pcall(function()
						return fire("Auctioneer", "PurchaseLot", itemName, maxPrice) or invoke({ "Auctioneer", "PurchaseLot" }, itemName, maxPrice)
					end)
					if ok and aucRes ~= false and aucRes ~= nil then
						pushPurchasedLog("beli lelang " .. tostring(itemName))
					end
					task.wait(0.2)
				end
			end
		end)
	end
end)

-- 8. Mailbox & Guild Auto Loop
task.spawn(function()
	while task.wait(30) do
		pcall(function()
			if MailCfg["Auto Claim"] and Net then
				updateTopStatus("Claiming Mailbox...")
				fire("Mailbox", "ClaimAll")
				invoke({ "Mailbox", "ClaimAll" })
			end
			if GuildCfg["Auto Accept Invite"] and Net then
				fire("Guild", "AcceptInvite")
				invoke({ "Guild", "AcceptInvite" })
			end
		end)
	end
end)

-- 9. Anti-AFK Engine
task.spawn(function()
	local ok, idle = pcall(function() return LocalPlayer.Idled end)
	if ok and idle then
		idle:Connect(function()
			pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
		end)
	end
end)

print("[DonnHub] Script successfully loaded with error protection!")
