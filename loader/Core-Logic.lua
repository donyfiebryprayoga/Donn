-- File: loader/Core-Logic.lua (Updated with Auto Walk to Garden & Valid Purchase Filters)
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
local AuctionCfg    = Config["Auction"] or {}
local EggsCfg       = Config["Eggs"] or {}
local PerfCfg       = Config["Performance"] or {}
local DebugCfg      = Config["Debug"] or {}

local purchaseCounters = {}

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

--// 2. Networking Hook (ByteNet Packet System)
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

local function invoke(path, ...)
	local n
	if type(path) == "table" then n = Net; for _, k in ipairs(path) do n = n and n[k] end
	else n = Net and Net[path] end
	if n and type(n.Fire) == "function" then
		local argc = select("#", ...)
		local extra = table.pack(...)
		local ok, res = pcall(function() return n:Fire(table.unpack(extra, 1, argc)) end)
		if ok then return res end
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
	local plotId = LocalPlayer:GetAttribute("PlotId")
	local gardens = Workspace:FindFirstChild("Gardens")
	if plotId and gardens then return gardens:FindFirstChild("Plot" .. tostring(plotId)) end
	return nil
end

-- Fungsi Otomatis Membawa Karakter Masuk ke Dalam Garden/Plot Sendiri
local function moveToGarden()
	pcall(function()
		local _, hrp, hum = getCharacter()
		local plot = getPlayerPlot()
		if hrp and hum and plot then
			-- Cari bagian tengah dari plot garden
			local targetPart = plot:FindFirstChild("Base") or plot:FindFirstChildOfClass("BasePart")
			if targetPart then
				local destPos = targetPart.Position + Vector3.new(0, 5, 0)
				-- Cek jika jarak karakter terlalu jauh dari plot, teleport/jalan otomatis
				if (hrp.Position - destPos).Magnitude > 35 then
					hrp.CFrame = CFrame.new(destPos)
				end
			end
		end
	end)
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

--// 4. Custom GUI & Toast Notification (Kanan Bawah)
if CoreGui:FindFirstChild("DonnHubDashboard") then
	CoreGui.DonnHubDashboard:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DonnHubDashboard"
ScreenGui.Parent = CoreGui
ScreenGui.IgnoreGuiInset = true

local ToastFrame = Instance.new("Frame")
ToastFrame.Size = UDim2.new(0, 310, 0, 50)
ToastFrame.Position = UDim2.new(1, 20, 1, -70)
ToastFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 18)
ToastFrame.BorderSizePixel = 0
ToastFrame.ZIndex = 20
ToastFrame.Parent = ScreenGui
Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 8)
local ToastStroke = Instance.new("UIStroke")
ToastStroke.Color = Color3.fromRGB(0, 255, 130)
ToastStroke.Thickness = 1.5
ToastStroke.Parent = ToastFrame

local ToastIcon = Instance.new("TextLabel")
ToastIcon.Size = UDim2.new(0, 40, 1, 0)
ToastIcon.BackgroundTransparency = 1
ToastIcon.Text = "🌱"
ToastIcon.TextSize = 20
ToastIcon.ZIndex = 21
ToastIcon.Parent = ToastFrame

local ToastText = Instance.new("TextLabel")
ToastText.Size = UDim2.new(1, -45, 1, 0)
ToastText.Position = UDim2.new(0, 40, 0, 0)
ToastText.BackgroundTransparency = 1
ToastText.TextColor3 = Color3.fromRGB(240, 255, 245)
ToastText.TextSize = 12
ToastText.Font = Enum.Font.GothamBold
ToastText.TextXAlignment = Enum.TextXAlignment.Left
ToastText.Text = "DonnHub Loaded Successfully!\nConfig & Automation Engine Active."
ToastText.ZIndex = 21
ToastText.Parent = ToastFrame

task.spawn(function()
	local tweenIn = TweenService:Create(ToastFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -330, 1, -70)})
	tweenIn:Play()
	tweenIn.Completed:Wait()
	
	task.wait(4)
	
	local tweenOut = TweenService:Create(ToastFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 20, 1, -70)})
	tweenOut:Play()
end)

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
TitleCenter.Text = "FARMING & FULL CONFIG ENGINE"
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
StatsContent.Text = "Uptime 00:00:00\n\nLoading Config Rules...\nPlants: 0 / 0\nHarvested 0\nWeather Clear"
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
RightText.Text = "[PLANT / SHOVEL]\n"
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

local purchasedLogs = {}
local plantShovelLogs = {}
local currentStatus = "Starting Engine"

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
	RightText.Text = "[PLANT / SHOVEL]\n" .. table.concat(plantShovelLogs, "\n")
	writeDebugLog("GAG_Plant_Shovel_Log", msg)
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
		RightText.Text = "[PLANT / SHOVEL]\n(Console Paused)"
	else
		ConsoleButton.Text = "CONSOLE: ON"
		ConsoleButton.TextColor3 = Color3.fromRGB(200, 220, 210)
	end
end)

--// 5. Strict Config Enforcement Helper Functions
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

--// 6. Config Enforcement & Automation Engine
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

-- Auto Positioning Task: Memastikan karakter selalu berada di dalam garden
task.spawn(function()
	while task.wait(5) do
		moveToGarden()
	end
end)

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
			local plantLimitConfig = PlantCfg["Plant Limit"] or 0
			local plantLimitStr = plantLimitConfig > 0 and tostring(plantLimitConfig) or "OFF"

			StatsContent.Text = string.format(
				"Uptime %s\n\n%s Sheckles\n+%s\n\nPlants: %d / %s\nHarvested %.1fK\nStatus: %s\n\nWeather Clear",
				uptimeFormatted, shecklesStr, rateStr, currentPlantsTotal, plantLimitStr, harvestedCount / 1000, currentStatus
			)
		end)
	end
end)

-- 1. Harvest Loop
task.spawn(function()
	while task.wait(1.5) do
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
							currentStatus = "Harvesting: " .. tostring(e.name)
							fire("Garden", "CollectFruit", e.plantId, e.fruitId)
							harvestedCount = harvestedCount + 1
							task.wait(0.1)
						end
					end
				else
					currentStatus = "Idle / Running"
				end
			end
		end)
	end
end)

-- 2. Sell Loop
task.spawn(function()
	while task.wait(HarvestCfg["Sell Every"] or 40) do
		pcall(function()
			if HarvestCfg["Auto Harvest"] ~= false and Net then
				currentStatus = "Selling Inventory..."
				local sellRes = invoke({ "NPCS", "SellAll" })
				if sellRes ~= false then
					pushPurchasedLog("sold inventory (SellAll)")
				end
			end
		end)
	end
end)

-- 3. Buy Seeds Loop
task.spawn(function()
	while task.wait(5) do
		pcall(function()
			if Net then
				local seedsToBuyMap = PlantCfg["Buy Seeds"] or {}
				
				for seedName, maxTarget in pairs(seedsToBuyMap) do
					if type(seedName) == "string" and type(maxTarget) == "number" then
						if not purchaseCounters[seedName] then purchaseCounters[seedName] = 0 end
						
						if purchaseCounters[seedName] < maxTarget then
							local dontBuyList = PlantCfg["Don't Buy"] or {}
							local isBlocked = false
							for _, db in ipairs(dontBuyList) do
								if string.lower(seedName) == string.lower(db) then isBlocked = true break end
							end

							if not isBlocked then
								currentStatus = "Buying Seed: " .. tostring(seedName)
								local res = invoke({ "SeedShop", "PurchaseSeed" }, seedName)
								if res ~= false and res ~= nil then
									purchaseCounters[seedName] = purchaseCounters[seedName] + 1
									pushPurchasedLog(string.format("buy seed %s (%d/%d)", seedName, purchaseCounters[seedName], maxTarget))
								end
								task.wait(0.2)
							end
						end
					end
				end
			end
		end)
	end
end)

-- 4. Buy Gear & Place Sprinklers Loop
local gearBuyList = GearCfg["Buy Gear"] or {}
task.spawn(function()
	while task.wait(10) do
		pcall(function()
			if GearCfg["Auto Buy"] and Net then
				for _, gearName in ipairs(gearBuyList) do
					currentStatus = "Buying Gear: " .. tostring(gearName)
					local res = invoke({ "GearShop", "PurchaseGear" }, gearName)
					if res ~= false and res ~= nil then
						pushPurchasedLog("buy gear " .. tostring(gearName))
					end
					task.wait(0.5)
				end
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(15) do
		pcall(function()
			if GearCfg["Place Sprinklers"] and Net then
				currentStatus = "Placing Sprinklers..."
				for _, tool in ipairs(getToolsWithAttribute("SprinklerTool")) do
					local sprinklerName = tool.Name or ""
					fire("Garden", "PlaceSprinkler", tool, getPlantPosition())
					pushPurchasedLog("placed sprinkler: " .. tostring(sprinklerName))
					task.wait(1)
				end
			end
		end)
	end
end)

-- 5. Plant Loop
task.spawn(function()
	while task.wait(1.5) do
		pcall(function()
			if PlantCfg["Auto Plant"] ~= false and Net then
				local plantLimit = PlantCfg["Plant Limit"] or 0
				local plants = myPlantModels()
				
				if plantLimit > 0 and #plants > plantLimit then
					local neverShovel = PlantCfg["Never Shovel"] or {}
					for i = plantLimit + 1, #plants do
						local p = plants[i]
						if p and p:GetAttribute("PlantId") then
							local pName = p:GetAttribute("SeedName") or p.Name or "Unknown Crop"
							local safe = false
							for _, ns in ipairs(neverShovel) do
								if string.lower(pName) == string.lower(ns) then safe = true break end
							end
							if not safe then
								currentStatus = "Shoveling excess plant..."
								local successShovel = pcall(function()
									fire("Garden", "ShovelPlant", p:GetAttribute("PlantId"))
								end)
								
								if successShovel then
									pushPlantShovelLog(string.format("[SUKSES] Shovel %s", tostring(pName)))
								else
									pushPlantShovelLog(string.format("[GAGAL] Shovel %s", tostring(pName)))
								end
								task.wait(0.2)
							end
						end
					end
				end

				for _, tool in ipairs(getToolsWithAttribute("SeedTool")) do
					local seedName = tool:GetAttribute("SeedTool") or "Seed"
					if isSeedAllowed(seedName, tool) then
						currentStatus = "Planting: " .. tostring(seedName)
						local pos = getPlantPosition()
						local _, _, hum = getCharacter()
						if pos and hum then
							if tool.Parent ~= LocalPlayer.Character then hum:EquipTool(tool) end
							task.wait(0.05)
							
							local successPlant = pcall(function()
								fire("Plant", "PlantSeed", pos, seedName, tool)
							end)
							
							if successPlant then
								pushPlantShovelLog(string.format("[SUKSES] Tanam %s", tostring(seedName)))
							else
								pushPlantShovelLog(string.format("[GAGAL] Tanam %s", tostring(seedName)))
							end
						end
					end
				end
			end
		end)
	end
end)

-- 6. Open Eggs & Auto Pets Loop
task.spawn(function()
	while task.wait(4) do
		pcall(function()
			if EggsCfg["Auto Open"] and Net then
				local openList = EggsCfg["Open"] or {}
				for _, eggName in ipairs(openList) do
					currentStatus = "Opening Egg: " .. tostring(eggName)
					local eggRes = invoke({ "Egg", "OpenEgg" }, eggName)
					if eggRes ~= false and eggRes ~= nil then
						pushPurchasedLog("opened egg: " .. tostring(eggName))
					end
					task.wait(0.5)
				end
			end
			
			if PetsCfg and PetsCfg["Auto Hatch"] and Net then
				currentStatus = "Hatching Pets..."
				invoke({ "Pets", "HatchEgg" }, PetsCfg["Target Egg"] or "Common Egg")
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
					currentStatus = "Checking Auction: " .. tostring(itemName)
					local aucRes = fire("Auctioneer", "PurchaseLot", itemName, maxPrice)
					if aucRes ~= false and aucRes ~= nil then
						pushPurchasedLog("auction won: " .. tostring(itemName))
					end
				end
			end
		end)
	end
end)

-- 8. Mailbox Auto Claim
task.spawn(function()
	while task.wait(30) do
		pcall(function()
			if MailCfg["Auto Claim"] and Net then
				currentStatus = "Claiming Mailbox..."
				local mailRes = fire("Mailbox", "ClaimAll")
				if mailRes ~= false then
					pushPurchasedLog("claimed mailbox items")
				end
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

print("[DonnHub] Script successfully loaded with Auto-Garden Positioning!")
