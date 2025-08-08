local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerDataTemplate = require(ReplicatedStorage:WaitForChild("PlayerData"))
local ProfileStore = require(ServerScriptService:WaitForChild("Packages"):WaitForChild("ProfileStore"))
local EchoNames = require(ReplicatedStorage:WaitForChild("EchoNames"))
local StateManager = require(script.Parent.Modules.StateManager)

if not ReplicatedStorage:FindFirstChild("UpdatePosition") then
	local event = Instance.new("RemoteEvent")
	event.Name = "UpdatePosition"
	event.Parent = ReplicatedStorage
end

local UpdatePosition = ReplicatedStorage.Requests:WaitForChild("UpdatePosition")
local lastKnownPositions = {}
local canTrackPosition = {}
local canSavePosition = {}

UpdatePosition.OnServerEvent:Connect(function(player, position)
	if canTrackPosition[player.UserId] then
		lastKnownPositions[player.UserId] = position
	end
end)

local DATA_STORE_KEY = "Production1"
if RunService:IsStudio() then
	DATA_STORE_KEY = "Test11124124"
end

local PlayerStore = ProfileStore.New(DATA_STORE_KEY, PlayerDataTemplate.DEFAULT_PLAYER_DATA)
local Profiles = {}

local Local = {}
local Shared = {}

local function CreatValueTypesAndInputData(player, Table, folder)
	for name, value in pairs(Table) do
		if typeof(value) == "table" then
			if (name == "skinTone" or name == "hairColor") and #value == 3 then
				local colorValue = Instance.new("Color3Value")
				colorValue.Name = tostring(name)
				colorValue.Parent = folder
				colorValue.Value = Color3.new(value[1], value[2], value[3])
			elseif name == "position" then
				local existingValue = folder:FindFirstChild("position")
				if existingValue and existingValue:IsA("Vector3Value") then
					existingValue.Value = Vector3.new(value.x or -95.311, value.y or 9.88, value.z or -42.87)
				else
					local vector3Value = Instance.new("Vector3Value")
					vector3Value.Name = tostring(name)
					vector3Value.Parent = folder
					vector3Value.Value = Vector3.new(value.x or -95.311, value.y or 9.88, value.z or -42.87)
				end
			else
				local Children = Instance.new("Folder")
				Children.Name = tostring(name)
				Children.Parent = folder
				CreatValueTypesAndInputData(player, value, Children)
			end
		elseif typeof(value) == "number" then
			local number = Instance.new("NumberValue")
			number.Name = tostring(name)
			number.Parent = folder
			number.Value = value
		elseif typeof(value) == "boolean" then
			local boolean = Instance.new("BoolValue")
			boolean.Name = tostring(name)
			boolean.Parent = folder
			boolean.Value = value
		elseif typeof(value) == "string" then
			local String = Instance.new("StringValue")
			String.Name = tostring(name)
			String.Parent = folder
			String.Value = value
		end
	end
end

local function CreatExternalData(player)
	local existingPlayerData = player:FindFirstChild("PlayerData")
	local existingPosition = nil

	if existingPlayerData and existingPlayerData:FindFirstChild("position") then
		local posValue = existingPlayerData.position
		if posValue:IsA("Vector3Value") then
			existingPosition = posValue.Value
		end
	end

	if existingPlayerData then
		existingPlayerData:Destroy()
	end

	local PlayerData = Instance.new("Folder")
	PlayerData.Name = "PlayerData"
	PlayerData.Parent = player
	local data = Shared.GetData(player)
	if not data then
		return
	end
	CreatValueTypesAndInputData(player, data, PlayerData)

	if existingPosition and PlayerData:FindFirstChild("position") then
		local newPosValue = PlayerData.position
		if newPosValue:IsA("Vector3Value") then
			newPosValue.Value = existingPosition
		end
	end
end

local function UpdateExternalData(player)
	if player:FindFirstChild("PlayerData") then
		player.PlayerData:Destroy()
	end
	CreatExternalData(player)
end

local function UpdateLatentEcho(player, amount)
	local profile = Profiles[player]
	if profile then
		profile.Data.LatentEcho = amount
		if player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("LatentEcho") then
			player.PlayerData.LatentEcho.Value = amount
		end
	end
end

local function UpdateEchoType(player, echoType)
	local profile = Profiles[player]
	if profile then
		profile.Data.echoType = echoType
		if player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("echoType") then
			player.PlayerData.echoType.Value = echoType
		end
	end
end

local function AddEnteredZone(player, zoneName)
	local profile = Profiles[player]
	if profile then
		profile.Data.enteredZones[zoneName] = true
		if player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("enteredZones") then
			local zoneValue = Instance.new("StringValue")
			zoneValue.Name = zoneName
			zoneValue.Value = zoneName
			zoneValue.Parent = player.PlayerData.enteredZones
		end
	end
end

local function HasEnteredZone(player, zoneName)
	local profile = Profiles[player]
	if profile then
		return profile.Data.enteredZones[zoneName] == true
	end
	return false
end

local function RollOrigin()
	local origins = {
		{ name = "Auralin", weight = 18 },
		{ name = "Veyren", weight = 13 },
		{ name = "Thalari", weight = 12 },
		{ name = "Soryn", weight = 12 },
		{ name = "Drazel", weight = 12 },
		{ name = "Korrin", weight = 10 },
		{ name = "Elvarei", weight = 8 },
		{ name = "Myrr", weight = 6 },
		{ name = "Heshari", weight = 5 },
		{ name = "Tollin", weight = 4 },
	}
	local totalWeight = 0
	for _, origin in ipairs(origins) do
		totalWeight = totalWeight + origin.weight
	end
	local random = math.random(1, totalWeight)
	local currentWeight = 0
	for _, origin in ipairs(origins) do
		currentWeight = currentWeight + origin.weight
		if random <= currentWeight then
			return origin.name
		end
	end
	return origins[1].name
end

local function AssignRandomName(player, origin, gender)
	local namesTable = EchoNames[origin] or EchoNames.General
	local genderList = namesTable and namesTable[gender or "Male"] or EchoNames.General.Male
	local randomName = genderList[math.random(1, #genderList)]
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayName = randomName
		end
	end
	return randomName
end

local function UpdateName(player, name)
	local profile = Profiles[player]
	if profile then
		profile.Data.name = name
		if player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("name") then
			player.PlayerData.name.Value = name
		end
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.DisplayName = name
			end
		end
	end
end

local function AddMinutesSurvived(player, minutes)
	local profile = Profiles[player]
	if profile then
		local current = profile.Data.MinutesSurvived or 0
		profile.Data.MinutesSurvived = current + minutes
		if player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("MinutesSurvived") then
			player.PlayerData.MinutesSurvived.Value = current + minutes
		end
	end
end

local function SetMinutesSurvived(player, minutes)
	local profile = Profiles[player]
	if profile then
		profile.Data.MinutesSurvived = minutes
		if player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("MinutesSurvived") then
			player.PlayerData.MinutesSurvived.Value = minutes
		end
	end
end

local function AddDaysSurvived(player, days)
	local profile = Profiles[player]
	if profile then
		local current = profile.Data.DaysSurvived or 0
		profile.Data.DaysSurvived = current + days
		if player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("DaysSurvived") then
			player.PlayerData.DaysSurvived.Value = current + days
		end
	end
end

local function UpdateOrigin(player, origin)
	local profile = Profiles[player]
	if profile then
		profile.Data.origin = origin
		if player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("origin") then
			player.PlayerData.origin.Value = origin
		end
	end
end

local function UpdateVestige(player, vestige)
	local profile = Profiles[player]
	if profile then
		profile.Data.vestige = vestige
		if player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("vestige") then
			player.PlayerData.vestige.Value = vestige
		end
	end
end

local function UpdateSkinTone(player, skinTone, skinToneIndex)
	local profile = Profiles[player]
	if profile then
		if typeof(skinTone) == "Color3" then
			profile.Data.skinTone = { skinTone.R, skinTone.G, skinTone.B }
		else
			profile.Data.skinTone = skinTone
		end
		profile.Data.skinToneIndex = skinToneIndex
		UpdateExternalData(player)
	end
end

local function AssignRandomSkinTone(player, origin)
	local SkinTones = require(ReplicatedStorage:WaitForChild("SkinTones"))
	local skinTone = SkinTones.GetRandomSkinTone(origin)
	local skinToneIndex = math.random(1, 11)
	UpdateSkinTone(player, skinTone, skinToneIndex)
	return skinTone, skinToneIndex
end

local function UpdateHairColor(player, hairColor)
	local profile = Profiles[player]
	if profile then
		if typeof(hairColor) == "Color3" then
			profile.Data.hairColor = { hairColor.R, hairColor.G, hairColor.B }
		else
			profile.Data.hairColor = hairColor
		end
		UpdateExternalData(player)
	end
end

local function AssignHairColor(player, origin)
	local SkinTones = require(ReplicatedStorage:WaitForChild("SkinTones"))
	local hairColor = SkinTones.GetHairColor(origin)
	UpdateHairColor(player, hairColor)
	return hairColor
end

local function SavePlayerPosition(player)
	if not canSavePosition[player] then
		return
	end
	local profile = Profiles[player]
	if not profile then
		return
	end
	if not canTrackPosition[player.UserId] then
		return
	end
	local pos = lastKnownPositions[player.UserId]
	if pos then
		profile.Data.position = { x = pos.X, y = pos.Y, z = pos.Z }
	end
	profile:Save()
end

local function LoadPlayerPosition(player)
	local profile = Profiles[player]
	if not profile then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	local position = profile.Data.position
	if profile.Data.vestige == 0 then
		humanoidRootPart.CFrame = CFrame.new(-394.211, 848.225, 67.455)
		StateManager.AddState(player, "techyLockedInAlienSkibidiToilet")
	else
		StateManager.RemoveState(player, "Dead")
		if position and position.x and position.y and position.z then
			humanoidRootPart.CFrame = CFrame.new(position.x, position.y, position.z)
		else
			humanoidRootPart.CFrame = CFrame.new(-95.311, 9.88, -42.87)
		end
	end
	canTrackPosition[player.UserId] = true
end

local function AssignEchoData(player)
	task.spawn(function()
		local attempts = 0
		local maxAttempts = 10
		while attempts < maxAttempts do
			local data = Shared.GetData(player)
			if data then
				if data.LatentEcho == nil then
					data.LatentEcho = math.random(10, 30)
					UpdateLatentEcho(player, data.LatentEcho)
				end
				if data.echoType == "" then
					local echoTypes = {
						{ name = "Resonant", weight = 14 },
						{ name = "Aegis", weight = 14 },
						{ name = "Chorus", weight = 14 },
						{ name = "Veil", weight = 14 },
						{ name = "Catalyst", weight = 13 },
						{ name = "Warden", weight = 13 },
						{ name = "Requiem", weight = 9 },
						{ name = "Pulse", weight = 9 },
					}
					local totalWeight = 0
					for _, echoType in ipairs(echoTypes) do
						totalWeight = totalWeight + echoType.weight
					end
					local random = math.random(1, totalWeight)
					local currentWeight = 0
					for _, echoType in ipairs(echoTypes) do
						currentWeight = currentWeight + echoType.weight
						if random <= currentWeight then
							data.echoType = echoType.name
							UpdateEchoType(player, echoType.name)
							break
						end
					end
				end
				if data.origin == "" then
					local origin = RollOrigin()
					data.origin = origin
					UpdateOrigin(player, origin)
				end
				if data.skinTone == nil then
					AssignRandomSkinTone(player, data.origin)
					UpdateExternalData(player)
				end
				if data.hairColor == nil then
					AssignHairColor(player, data.origin)
					UpdateExternalData(player)
				end
				if data.vestige == nil then
					data.vestige = 5
					UpdateVestige(player, 5)
				end
				local Clothing = require(game.ReplicatedStorage.Clothing)
				if not data.Armor or not Clothing[data.Armor] then
					local defaults =
						{ "LegacyBlackOutfit", "LegacyRedOutfit", "LegacyGreenOutfit", "LegacyPurpleOutfit" }
					data.Armor = defaults[math.random(1, #defaults)]
				end
				break
			end
			attempts = attempts + 1
			task.wait(0.5)
		end
	end)
end

local function setInn(player, inn)
	local profile = Profiles[player]
	if profile then
		profile.Data.Inn = inn
	end
	profile:Save()
	UpdateExternalData(player)
end

local function Wipe(player, gender)
	local profile = Profiles[player]
	if profile then
		profile.Data.name = ""
		profile.Data.LatentEcho = 0
		profile.Data.vestige = 5
		profile.Data.enteredZones = {}
		profile.Data.skinTone = nil
		profile.Data.skinToneIndex = 1
		profile.Data.hairColor = nil
		profile.Data.position = { x = -394.211, y = 848.225, z = 67.455 }
		profile.Data.Armor = nil
		profile.Data.Weapon = ""
		profile.Data.Relics = {}
		profile.Data.Skills = {}
		profile.Data.health = 100
		profile.Data.Trinkets = {}
		profile.Data.SlotData = {}
		if player:FindFirstChild("Backpack") then
			for _, item in ipairs(player.Backpack:GetChildren()) do
				item:Destroy()
			end
		end
		if player:FindFirstChild("StarterGear") then
			for _, item in ipairs(player.StarterGear:GetChildren()) do
				item:Destroy()
			end
		end
		if Shared and Shared.SetWeapon then
			Shared.SetWeapon(player, "")
		end
		local origin = profile.Data.origin or RollOrigin()
		local newName = AssignRandomName(player, origin, gender)
		UpdateName(player, newName)
		if player:FindFirstChild("PlayerData") then
			if player.PlayerData:FindFirstChild("name") then
				player.PlayerData.name.Value = newName
			end
			if player.PlayerData:FindFirstChild("LatentEcho") then
				player.PlayerData.LatentEcho.Value = 0
			end
			if player.PlayerData:FindFirstChild("vestige") then
				player.PlayerData.vestige.Value = 5
			end
			if player.PlayerData:FindFirstChild("enteredZones") then
				for _, v in ipairs(player.PlayerData.enteredZones:GetChildren()) do
					v:Destroy()
				end
			end
			if player.PlayerData:FindFirstChild("skinTone") then
				player.PlayerData.skinTone.Value = Color3.new(1, 1, 1)
			end
			if player.PlayerData:FindFirstChild("skinToneIndex") then
				player.PlayerData.skinToneIndex.Value = 1
			end
			if player.PlayerData:FindFirstChild("hairColor") then
				player.PlayerData.hairColor.Value = Color3.new(1, 1, 1)
			end
			if player.PlayerData:FindFirstChild("position") then
				player.PlayerData.position.Value = Vector3.new(-394.211, 848.225, 67.455)
			end
			if player.PlayerData:FindFirstChild("Armor") then
				player.PlayerData.Armor.Value = ""
			end
			if player.PlayerData:FindFirstChild("Weapon") then
				player.PlayerData.Weapon.Value = ""
			end
			if player.PlayerData:FindFirstChild("Relics") then
				for _, v in ipairs(player.PlayerData.Relics:GetChildren()) do
					v:Destroy()
				end
			end
			if player.PlayerData:FindFirstChild("Skills") then
				for _, v in ipairs(player.PlayerData.Skills:GetChildren()) do
					v:Destroy()
				end
			end
			if player.PlayerData:FindFirstChild("Trinkets") then
				for _, v in ipairs(player.PlayerData.Trinkets:GetChildren()) do
					v:Destroy()
				end
			end
			if player.PlayerData:FindFirstChild("health") then
				player.PlayerData.health.Value = 100
			end
		end
		UpdateExternalData(player)
		profile:Save()
		player:LoadCharacter()
	end
end

local function SetWeapon(player, weaponName)
	local profile = Profiles[player]
	if profile then
		profile.Data.Weapon = weaponName
		UpdateExternalData(player)
	end
end

local function getData(player)
	local profile = Profiles[player]
	return profile
end

local function GetWeapon(player)
	local profile = Profiles[player]
	if profile then
		return profile.Data.Weapon
	end
	return nil
end

local function sanitizeForUTF8(str)
	if typeof(str) ~= "string" then
		return str
	end
	return string.gsub(str, "[^\32-\126]", "")
end

local function sanitizeSlotData(slotData)
	local sanitized = {}
	for key, value in pairs(slotData) do
		sanitized[tostring(key)] = sanitizeForUTF8(tostring(value))
	end
	return sanitized
end

local function UpdateSlotData(player, slotData)
	local profile = Profiles[player]
	if profile then
		local HttpService = game:GetService("HttpService")
		local sanitizedData = sanitizeSlotData(slotData)
		local success, slotDataString = pcall(function()
			return HttpService:JSONEncode(sanitizedData)
		end)
		if success then
			profile.Data.SlotData = slotDataString
			if player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("SlotData") then
				player.PlayerData.SlotData.Value = slotDataString
			end
		else
			warn("Failed to encode SlotData for player " .. player.Name .. ": " .. tostring(slotDataString))
			profile.Data.SlotData = "{}"
			if player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("SlotData") then
				player.PlayerData.SlotData.Value = "{}"
			end
		end
	end
end

local function GetSlotData(player)
	local profile = Profiles[player]
	if profile then
		local HttpService = game:GetService("HttpService")
		local slotDataString = profile.Data.SlotData or "{}"
		local success, slotData = pcall(function()
			return HttpService:JSONDecode(slotDataString)
		end)
		return success and slotData or {}
	end
	return {}
end

--[[
	██████╗ ██╗      █████╗ ██╗   ██╗███████╗██████╗     ██████╗  █████╗ ████████╗ █████╗ 
	██╔══██╗██║     ██╔══██╗╚██╗ ██╔╝██╔════╝██╔══██╗    ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗
	██████╔╝██║     ███████║ ╚████╔╝ █████╗  ██████╔╝    ██║  ██║███████║   ██║   ███████║
	██╔═══╝ ██║     ██╔══██║  ╚██╔╝  ██╔══╝  ██╔══██╗    ██║  ██║██╔══██║   ██║   ██╔══██║
	██║     ███████╗██║  ██║   ██║   ███████╗██║  ██║    ██████╔╝██║  ██║   ██║   ██║  ██║
	╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
	========================== PLAYER DATA ============================
--]]

function Local.OnStart()
	for _, player in pairs(Players:GetChildren()) do
		task.spawn(Local.LoadProfile, player)
	end
	Players.PlayerAdded:Connect(Local.LoadProfile)
	Players.PlayerRemoving:Connect(Local.RemoveProfile)
end

function Local.LoadProfile(player: Player)
	local profile = PlayerStore:StartSessionAsync(`${player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if profile == nil then
		return player:Kick("Profile load faild. Please rejoin.")
	end
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	if not profile.Data.Armor then
		local defaults = { "LegacyBlackOutfit", "LegacyRedOutfit", "LegacyGreenOutfit", "LegacyPurpleOutfit" }
		profile.Data.Armor = defaults[math.random(1, #defaults)]
	end
	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick("Profile session ended. Please rejoin.")
	end)
	local isInGame = player.Parent == Players
	if isInGame then
		Profiles[player] = profile
		coroutine.wrap(CreatExternalData)(player)
		if profile.Data.banned then
			player:Kick("Banned")
		end
	else
		profile:EndSession()
	end
end

function Local.RemoveProfile(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		SavePlayerPosition(player)
		lastKnownPositions[player.UserId] = nil
		canTrackPosition[player.UserId] = nil
		profile:Save()
		task.wait(0.1)
		profile:EndSession()
	end
end

function Shared.GetData(player: Player): PlayerDataTemplate.PlayerData?
	local profile = Profiles[player]
	if not profile then
		return
	end
	return profile.Data
end

Shared.UpdateLatentEcho = UpdateLatentEcho
Shared.UpdateEchoType = UpdateEchoType
Shared.AddEnteredZone = AddEnteredZone
Shared.HasEnteredZone = HasEnteredZone
Shared.RollOrigin = RollOrigin
Shared.AssignRandomName = AssignRandomName
Shared.UpdateName = UpdateName
Shared.UpdateOrigin = UpdateOrigin
Shared.UpdateVestige = UpdateVestige
Shared.UpdateSkinTone = UpdateSkinTone
Shared.AssignRandomSkinTone = AssignRandomSkinTone
Shared.UpdateHairColor = UpdateHairColor
Shared.AssignHairColor = AssignHairColor
Shared.UpdateExternalData = UpdateExternalData
Shared.SavePlayerPosition = SavePlayerPosition
Shared.LoadPlayerPosition = LoadPlayerPosition
Shared.Wipe = Wipe
Shared.SetWeapon = SetWeapon
Shared.GetWeapon = GetWeapon
Shared.AssignEchoData = AssignEchoData
Shared.UpdateSlotData = UpdateSlotData
Shared.GetSlotData = GetSlotData
Shared.SetInn = setInn
Shared.AddMinutesSurvived = AddMinutesSurvived
Shared.SetMinutesSurvived = SetMinutesSurvived
Shared.AddDaysSurvived = AddDaysSurvived
Shared.getData = getData

function Shared.AllowPositionSave(player)
	canSavePosition[player] = true
end
function Shared.DisallowPositionSave(player)
	canSavePosition[player] = false
end

Local.OnStart()

return Shared
