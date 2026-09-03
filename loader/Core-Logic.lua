-- File: loader/Core-Logic.lua (GAG2 Safe Delayed Bootstrapper)
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local VirtualUser       = game:GetService("VirtualUser")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local StarterGui        = game:GetService("StarterGui")

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

local rareCounters = {
	Gold = 0,
	Rainbow = 0,
	Mega = 0
}

local lastPlantedName = "None"

print("[DonnHub GAG2] Waiting for game loading to finish...")

--// 1. Safe Delayed Networking Hook (Menunggu ClientModules benar-benar ada)
local Net = nil
task.spawn(function()
	local cm = nil
	while not cm do
		cm = ReplicatedStorage:FindFirstChild("ClientModules")
		if not cm then
			task.wait(1)
		end
	end
	
	local netMod = nil
	while not netMod do
		netMod = cm:FindFirstChild("Networking")
		if not netMod then
			task.wait(1)
		end
	end
	
	pcall(function()
		Net = require(netMod)
	end)
	print("[DonnHub GAG2] Networking successfully loaded and synchronized!")
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
	if not Net then return end
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

--// 2. Helper Functions
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

	local onlyPlant = PlantCfg["Only Plant"] or {}
	if type(onlyPlant) == "table" and #onlyPlant > 0 then
		local found = false
		for _, op in ipairs(onlyPlant) do
			if string.lower(tostring(seedName)) == string.lower(tostring(op)) then found = true break end
		end
		if not found then return false end
	end
	return true
end

--// 3. Automation Loops
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

task.spawn(function()
	while task.wait(3) do
		moveToGarden()
	end
end)

-- Harvest & Sell Loop
task.spawn(function()
	while task.wait(1.0) do
		pcall(function()
			if HarvestCfg["Auto Harvest"] ~= false then
				local list = scanCollectibleDetailed()
				local dontHarvestList = HarvestCfg["Don't Harvest"] or {}
				
				if #list > 0 then
					for _, e in ipairs(list) do
						local skip = false
						for _, dh in ipairs(dontHarvestList) do
							if string.lower(e.name) == string.lower(dh) then skip = true break end
						end
						
						if not skip then
							local collectRes = fire("Garden", "CollectFruit", e.plantId, e.fruitId)
							if collectRes == "Full" or collectRes == false or #list >= (HarvestCfg["Sell At"] or 75) then
								fire("NPCS", "SellAll")
								invoke({ "NPCS", "SellAll" })
							end
							task.wait(0.04)
						end
					end
				end
			end
		end)
	end
end)

-- Timed Sell Loop
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

-- Seed Purchasing Loop
task.spawn(function()
	while task.wait(3) do
		pcall(function()
			local seedsToBuyMap = PlantCfg["Buy Seeds"] or {}
			local keepSeedsMap = PlantCfg["Keep Seeds"] or {}
			local combinedBuyList = {}
			for k, v in pairs(seedsToBuyMap) do combinedBuyList[k] = v end
			for k, v in pairs(keepSeedsMap) do combinedBuyList[k] = v end

			for seedName, _ in pairs(combinedBuyList) do
				if type(seedName) == "string" then
					local dontBuyList = PlantCfg["Don't Buy"] or {}
					local isBlocked = false
					for _, db in ipairs(dontBuyList) do
						if string.lower(seedName) == string.lower(db) then isBlocked = true break end
					end

					if not isBlocked then
						invoke({ "SeedShop", "PurchaseSeed" }, seedName)
						fire("SeedShop", "PurchaseSeed", seedName)
						task.wait(0.2)
					end
				end
			end
		end)
	end
end)

-- Gear Purchasing Loop
task.spawn(function()
	while task.wait(10) do
		pcall(function()
			if GearCfg["Auto Buy"] then
				local gearBuyList = GearCfg["Buy Gear"] or {}
				for _, gearName in ipairs(gearBuyList) do
					invoke({ "GearShop", "PurchaseGear" }, gearName)
					fire("GearShop", "PurchaseGear", gearName)
					task.wait(0.5)
				end
			end
		end)
	end
end)

-- Plant & Shovel Loop (Protected Eclipse Bloom & Tier Tinggi)
task.spawn(function()
	while task.wait(1.2) do
		pcall(function()
			if PlantCfg["Auto Plant"] ~= false then
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

							local isGold = p:GetAttribute("Gold"] or false
							local isRainbow = p:GetAttribute("Rainbow") or false
							local isMega = p:GetAttribute("Mega") or false
							
							if PlantCfg["Shovel Mutated"] == false and (isGold or isRainbow or isMega) then
								safe = true
							end

							local plantTier = string.lower(tostring(p:GetAttribute("Tier") or p:GetAttribute("Rarity") or ""))
							if plantTier == "mythic" or plantTier == "super" or plantTier == "secret" or plantTier == "legendary" then
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
					local seedName = tool:GetAttribute("SeedTool"] or "Seed"
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

-- Egg & Auction Loop
task.spawn(function()
	while task.wait(4) do
		pcall(function()
			if EggsCfg["Auto Open"] then
				local openList = EggsCfg["Open"] or {"all"}
				for _, eggName in ipairs(openList) do
					if hasItemInInventory(eggName) or eggName == "all" then
						invoke({ "Egg", "OpenEgg" }, eggName)
						fire("Egg", "OpenEgg", eggName)
					end
					task.wait(0.5)
				end
			end
			if AuctionCfg["Auto Buy"] then
				local buyItems = AuctionCfg["Buy"] or {}
				for itemName, maxPrice in pairs(buyItems) do
					fire("Auctioneer", "PurchaseLot", itemName, maxPrice)
					invoke({ "Auctioneer", "PurchaseLot" }, itemName, maxPrice)
					task.wait(0.2)
				end
			end
		end)
	end
end)

-- Mailbox & Anti-AFK
task.spawn(function()
	while task.wait(30) do
		pcall(function()
			if MailCfg["Auto Claim"] then
				fire("Mailbox", "ClaimAll")
				invoke({ "Mailbox", "ClaimAll" })
			end
			if GuildCfg["Auto Accept Invite"] then
				fire("Guild", "AcceptInvite")
				invoke({ "Guild", "AcceptInvite" })
			end
		end)
	end
end)

task.spawn(function()
	local ok, idle = pcall(function() return LocalPlayer.Idled end)
	if ok and idle then
		idle:Connect(function()
			pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
		end)
	end
end)

print("[DonnHub GAG2] Safe Bootstrapper Engine active! Watch actions in F9.")
