_G.hadInGame = {}
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StateManager = require(script.Parent.Modules.StateManager)
local PlayerData = require(script.Parent.PlayerData)
local CharacterAppearance = require(script.Parent.Modules.CharacterAppearance)
local WeaponHandler = require(script.Parent.Modules.WeaponHandler)
local DropItemRemote = ReplicatedStorage.Requests:WaitForChild("DropItem")
local menuRemote = ReplicatedStorage.Requests:FindFirstChild("menu")
local Relics = require(ReplicatedStorage:WaitForChild("Relics"))
local RelicSystem = require(script.Parent.Modules.RelicSystem)
local BagSystem = require(script.Parent.BagSystem)
local Climbremote = ReplicatedStorage.Requests.Climb

local function destroyMenuGui(player)
	local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
	for _, v in ipairs(playerGui:GetChildren()) do
		if v.Name == "MainMenu" then
			v:Destroy()
		end
	end
end

local function showMenuGui(player)
	local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
	destroyMenuGui(player)
	local menuTemplate = script.Parent.GameLoaded:FindFirstChild("MainMenu")
	if menuTemplate then
		local menuClone = menuTemplate:Clone()
		menuClone.Parent = playerGui
	end
end

local function enterMenu(player, force)
	
	if StateManager.HasState(player, "InGame") and not force then
		print("[State] Ignoring menu entry: already InGame")
		return
	end
	_G.hadInGame[player] = false
	print("[State] Setting state to Menu for", player.Name)
	StateManager.SetState(player, "Menu")
	PlayerData.SavePlayerPosition(player)
	if player.Character then
		player.Character.Parent = nil
	end

	local inMenuAccessory = Instance.new("StringValue")
	inMenuAccessory.Name = "InMenu"
	inMenuAccessory.Parent = player

	showMenuGui(player)
end

local function enterGame(player)
	if StateManager.HasState(player, "InGame") then
		print("[State] Already InGame for", player.Name)
		return
	end
	_G.hadInGame[player] = true
	print("[State] Setting state to InGame for", player.Name)
	StateManager.SetState(player, "InGame")

	local inMenuAccessory = player:FindFirstChild("InMenu")
	if inMenuAccessory then
		inMenuAccessory:Destroy()
	end

	destroyMenuGui(player)
	player:LoadCharacter()
end

local function isRelic(itemName)
	for _, relic in ipairs(Relics.EchoRelics) do
		if relic.Name == itemName then
			return true
		end
	end
	return false
end

local function addRelicToInventory(player, relicName)
	local data = PlayerData.GetData(player)
	if not data then return end
	if not data.Relics then data.Relics = {} end
	if not table.find(data.Relics, relicName) then
		table.insert(data.Relics, relicName)
		PlayerData.UpdateExternalData(player)
	end
	local backpack = player:FindFirstChild("Backpack")
	if backpack and not backpack:FindFirstChild(relicName) then
		local tool = Instance.new("Tool")
		tool.Name = relicName
		tool.CanBeDropped = false
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1,1,1)
		handle.Parent = tool
		tool.Parent = backpack
	end
end

DropItemRemote.OnServerEvent:Connect(function(player, itemName)
	if not isRelic(itemName) then return end
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end
	local tool = backpack:FindFirstChild(itemName) or (player.Character and player.Character:FindFirstChild(itemName))
	if tool then
		local dropped = BagSystem.createBagDrop(player, itemName)
		if dropped then
			tool:Destroy()
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	print("[PlayerAdded] Showing menu for", player.Name)
	showMenuGui(player)
	player.CharacterAdded:Connect(function(character)
		print("[CharacterAdded] for", player.Name, "Current state:", table.concat(StateManager.GetStates(player), ", "))
		
		if _G.hadInGame[player] then
			print("adding state back")
			StateManager.AddState(player, "InGame")
		end
		
		if StateManager.HasState(player, "InGame") then
			character.Parent = Workspace:FindFirstChild("Living") or Workspace
			CharacterAppearance.ApplyPlayerAppearance(player)
			WeaponHandler.loadPlayerWeapon(player)
			PlayerData.LoadPlayerPosition(player)
			local data = PlayerData.GetData(player)
			if data and data.Relics then
				for _, relicName in ipairs(data.Relics) do
					RelicSystem:giveRelicTool(player, {Name = relicName})
				end
			end
			if data and data.health and data.Stomach then
				character:SetAttribute("Stomach", data.Stomach)
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.Health = data.health
					humanoid.MaxHealth = math.max(humanoid.MaxHealth, data.health)
				end
			end
			print("[CharacterAdded] Character loaded for InGame:", player.Name)
			local root = character:FindFirstChild("HumanoidRootPart")
			if root then
				local spawnPos = root.Position
				local ff = Instance.new("ForceField")
				ff.Name = "SpawnForceField"
				ff.Parent = character
				local alive = true
				local function removeFF()
					if alive and ff and ff.Parent then
						ff:Destroy()
						alive = false
					end
				end
				task.delay(120, removeFF)
				local maxDist = 20
				local heartbeatConn
				heartbeatConn = game:GetService("RunService").Heartbeat:Connect(function()
					if not root.Parent then removeFF() if heartbeatConn then heartbeatConn:Disconnect() end return end
					if (root.Position - spawnPos).Magnitude > maxDist then
						removeFF()
						if heartbeatConn then heartbeatConn:Disconnect() end
					end
				end)
			end
			
			local humanoid: Humanoid = character:WaitForChild("Humanoid")
			humanoid.Died:Connect(function()
				_G.hadInGame[player] = true
			end)
		else
			character.Parent = nil
			print("[CharacterAdded] Character removed (not InGame):", player.Name)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local data = PlayerData.GetData(player)
	if data and player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			data.health = humanoid.Health
			PlayerData.UpdateExternalData(player)
		end
	end
	_G.hadInGame[player] = nil
end)

menuRemote.OnServerEvent:Connect(function(player, action)
	print("[menuRemote] Received action:", action, "for", player.Name, "Current state:", table.concat(StateManager.GetStates(player), ", "))
	if action == "play" then
		enterGame(player)
	elseif action == "forceMenu" then
		enterMenu(player, true)
	elseif action == "menu" or not action then
		enterMenu(player)
	end
end)

