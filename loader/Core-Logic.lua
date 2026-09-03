-- File: loader/Core-Logic.lua (GAG2 Anti-Cheat Bypass GUI Engine)
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
local GearCfg       = Config["Gear"] or {}
local EventSeedCfg  = Config["Event Seeds"] or {}
local MailCfg       = Config["Mail"] or {}
local MiscCfg       = Config["Misc"] or {}
local GuildCfg      = Config["Guild"] or {}
local AuctionCfg    = Config["Auction"] or {}
local EggsCfg       = Config["Eggs"] or {}
local PerfCfg       = Config["Performance"] or {}

local purchasedLogs = {}
local plantShovelLogs = {}
local rareCounters = { Gold = 0, Rainbow = 0, Mega = 0 }
local lastPlantedName = "None"

print("[DonnHub] Starting Anti-Cheat Bypass Engine...")

--// Safe Networking Hook
local Net = nil
task.spawn(function()
	while not Net do
		pcall(function()
			local cm = ReplicatedStorage:WaitForChild("ClientModules", 3)
			if cm then
				Net = require(cm:WaitForChild("Networking", 3))
			end
		end)
		if not Net then task.wait(1) end
	end
	print("[DonnHub] Network connected safely!")
end)

local function fire(category, action, ...)
	if not Net then return end
	local ok, res = pcall(function()
		if type(Net) == "table" and Net[category] then
			if type(Net[category].Fire) == "function" then
				return Net[category]:Fire(action, ...)
			elseif type(Net[category][action]) == "function" then
				return Net[category][action](...)
			end
		end
	end)
	return res
end

local function invoke(path, ...)
	if not Net then return end
	local n = Net
	pcall(function()
		if type(path) == "table" then
			for _, k in ipairs(path) do n = n and n[k] end
		else
			n = Net[path]
		end
	end)
	if n then
		local ok, res = pcall(function()
			if type(n.Invoke) == "function" then return n:Invoke(...)
			elseif type(n.Fire) == "function" then return n:Fire(...)
			elseif type(n) == "function" then return n(...) end
		end)
		if ok then return res end
	end
	return nil
end

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
		if tonumber(plot:GetAttribute("UserId")) == myId then return plot end
	end
	return gardens:GetChildren()[1]
end

local function moveToGarden()
	pcall(function()
		local _, hrp, _ = getCharacter()
		local plot = getPlayerPlot()
		if hrp and plot then
			local targetPart = plot:FindFirstChild("Base") or plot:FindFirstChildOfClass("BasePart")
			if targetPart then
				local destPos = targetPart.Position + Vector3.new(0, 4, 0)
				if (hrp.Position - destPos).Magnitude > 25 then
					hrp.CFrame = CFrame.new(destPos)
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
								out[#out + 1] = { plantId = plantId, fruitId = fruitId, name = plantName }
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
		if string.lower(tostring(seedName)) == string.lower(tostring(dp)) then return false end
	end
	return true
end

--// GUI Builder Menggunakan gethui() agar kebal blokir game
local parentUI = nil
pcall(function()
	if gethui then parentUI = gethui()
	else parentUI = CoreGui end
end)
if not parentUI then parentUI = LocalPlayer:WaitForChild("PlayerGui") end

for _, guiName in ipairs({"DonnHubDashboard", "GAGHubGui", "DonnHubGui"}) do
	if parentUI:FindFirstChild(guiName) then parentUI[guiName]:Destroy() end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DonnHubDashboard"
ScreenGui.Parent = parentUI
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false

local Container = Instance.new("Frame")
Container.Size = UDim2.new(0, 780, 0, 480)
Container.Position = UDim2.new(0.5, -390, 0.5, -240)
Container.BackgroundColor3 = Color3.fromRGB(14, 18, 16)
Container.BackgroundTransparency = 0.05
Container.BorderSizePixel = 0
Container.ZIndex = 3
Container.Parent = ScreenGui
Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 12)
local ContainerStroke = Instance.new("UIStroke")
ContainerStroke.Color = Color3.fromRGB(0, 255, 130)
ContainerStroke.Thickness = 1.5
ContainerStroke.Parent = Container

-- Title & Status di GUI
local TitleCenter = Instance.new("TextLabel")
TitleCenter.Size = UDim2.new(1, 0, 0, 40)
TitleCenter.Position = UDim2.new(0, 0, 0, 10)
TitleCenter.BackgroundTransparency = 1
TitleCenter.Text = "DONNHUB GAG2 ENGINE (ACTIVE)"
TitleCenter.TextColor3 = Color3.fromRGB(0, 255, 130)
TitleCenter.TextSize = 18
TitleCenter.Font = Enum.Font.GothamBold
TitleCenter.Parent = Container

local StatsContent = Instance.new("TextLabel")
StatsContent.Size = UDim2.new(1, -40, 0, 150)
StatsContent.Position = UDim2.new(0, 20, 0, 60)
StatsContent.BackgroundTransparency = 1
StatsContent.TextColor3 = Color3.fromRGB(230, 245, 240)
StatsContent.TextSize = 14
StatsContent.Font = Enum.Font.GothamBold
StatsContent.TextXAlignment = Enum.TextXAlignment.Center
StatsContent.TextYAlignment = Enum.TextYAlignment.Top
StatsContent.Text = "Status: Bot is running smoothly in background...\nCheck F9 for raw logs."
StatsContent.Parent = Container

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 150, 0, 35)
ToggleButton.Position = UDim2.new(0.5, -75, 1, -50)
ToggleButton.BackgroundColor3 = Color3.fromRGB(15, 22, 18)
ToggleButton.TextColor3 = Color3.fromRGB(0, 255, 150)
ToggleButton.TextSize = 12
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "🌱 HIDE / OPEN"
ToggleButton.Parent = Container
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 6)

ToggleButton.MouseButton1Click:Connect(function()
	Container.Visible = not Container.Visible
end)

--// Loops Otomatisasi Utama
task.spawn(function()
	while task.wait(3) do moveToGarden() end
end)

task.spawn(function()
	while task.wait(1.0) do
		pcall(function()
			if HarvestCfg["Auto Harvest"] ~= false then
				local list = scanCollectibleDetailed()
				if #list > 0 then
					for _, e in ipairs(list) do
						fire("Garden", "CollectFruit", e.plantId, e.fruitId)
						if #list >= (HarvestCfg["Sell At"] or 75) then
							fire("NPCS", "SellAll")
							invoke({ "NPCS", "SellAll" })
						end
						task.wait(0.04)
					end
				end
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(HarvestCfg["Sell Every"] or 20) do
		pcall(function()
			if HarvestCfg["Auto Harvest"] ~= false then
				fire("NPCS", "SellAll")
				invoke({ "NPCS", "SellAll" })
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(3) do
		pcall(function()
			local seedsToBuyMap = PlantCfg["Buy Seeds"] or {}
			local keepSeedsMap = PlantCfg["Keep Seeds"] or {}
			for seedName, _ in pairs(seedsToBuyMap) do
				invoke({ "SeedShop", "PurchaseSeed" }, seedName)
				fire("SeedShop", "PurchaseSeed", seedName)
				task.wait(0.2)
			end
			for seedName, _ in pairs(keepSeedsMap) do
				invoke({ "SeedShop", "PurchaseSeed" }, seedName)
				fire("SeedShop", "PurchaseSeed", seedName)
				task.wait(0.2)
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(1.2) do
		pcall(function()
			if PlantCfg["Auto Plant"] ~= false then
				local plantLimit = PlantCfg["Plant Limit"] or 69
				local plants = myPlantModels()
				
				if plantLimit > 0 and #plants > plantLimit then
					for _, p in ipairs(plants) do
						if #myPlantModels() <= plantLimit then break end
						if p and p:GetAttribute("PlantId") then
							local pName = p:GetAttribute("SeedName") or p.Name or "Unknown"
							local safe = string.lower(pName):find("eclipse bloom") ~= nil
							local plantTier = string.lower(tostring(p:GetAttribute("Tier") or p:GetAttribute("Rarity") or ""))
							if plantTier:find("mythic") or plantTier:find("super") or plantTier:find("secret") or plantTier:find("legendary") then
								safe = true
							end
							if not safe then
								fire("Garden", "ShovelPlant", p:GetAttribute("PlantId"))
								task.wait(0.3)
								break
							end
						end
					end
				end

				for _, tool in ipairs(getToolsWithAttribute("SeedTool")) do
					local seedName = tool:GetAttribute("SeedTool") or "Seed"
					if isSeedAllowed(seedName, tool) then
						lastPlantedName = tostring(seedName)
						local pos = getPlantPosition()
						local _, _, hum = getCharacter()
						if pos and hum then
							if tool.Parent ~= LocalPlayer.Character then hum:EquipTool(tool) end
							task.wait(0.05)
							fire("Plant", "PlantSeed", pos, seedName, tool)
							task.wait(0.3)
						end
					end
				end
			end
		end)
	end
end)

print("[DonnHub] GUI Engine loaded with gethui bypass!")
