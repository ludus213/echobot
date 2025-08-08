local EchoSystem = require(script.Parent.Modules.EchoSystem)
local RelicSystem = require(script.Parent.Modules.RelicSystem)
local PlayerData = require(script.Parent.PlayerData)
local CharacterAppearance = require(script.Parent.Modules.CharacterAppearance)
local CharacterSetupCoordinator = require(script.Parent.Modules.CharacterSetupCoordinator)
local DialogueHandler = require(script.Parent.Modules.DialogueHandler)
local AreaModule = require(script.Parent.Modules.AreaModule)
local system = EchoSystem.new()
local relicSystem = RelicSystem.new()
local combatSystem = require(game.ServerScriptService.Modules.CombatSystem)
local gimmedanger = game.ServerStorage.GimmeDanger
local treesway = require(game.ServerScriptService.Modules.TreeSway)
local statemanager = require(game.ServerScriptService.Modules.StateManager)
local swayInstance = treesway.Create()

combatSystem.initialize()
AreaModule.start()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local menuRemote = ReplicatedStorage.Requests:WaitForChild("menu")

local allowSaveRemote = ReplicatedStorage.Requests:WaitForChild("AllowPositionSave")

local fallDamageRemote = ReplicatedStorage.Requests:WaitForChild("FallDamageEvent")

local slotDataRemote = ReplicatedStorage.Requests:WaitForChild("UpdateSlotData")

local getSlotDataRemote = ReplicatedStorage.Requests:WaitForChild("GetSlotData")
allowSaveRemote.OnServerEvent:Connect(function(player)
	PlayerData.AllowPositionSave(player)
end)
local function giveSkillTools(player)
	local data = PlayerData.GetData(player)
	if not data or not data.Skills then
		return
	end
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
	local skillsFolder = ServerStorage:FindFirstChild("Skills")
	if not skillsFolder then
		return
	end
	for _, skillName in ipairs(data.Skills) do
		local skillTool = skillsFolder:FindFirstChild(skillName)
		if skillTool and not backpack:FindFirstChild(skillName) then
			local toolClone = skillTool:Clone()
			toolClone.Parent = backpack
		end
	end
end

local inns = { "Calypso", "Ohio", "Thalari" }

function assignEchoData(player)
	task.spawn(function()
		local attempts = 0
		local maxAttempts = 10
		while attempts < maxAttempts do
			local data = PlayerData.GetData(player)
			if data then
				if data.LatentEcho == nil then
					data.LatentEcho = math.random(10, 30)
					PlayerData.UpdateLatentEcho(player, data.LatentEcho)
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
							PlayerData.UpdateEchoType(player, echoType.name)
							break
						end
					end
				end
				if data.origin == "" then
					local origin = PlayerData.RollOrigin()
					data.origin = origin
					PlayerData.UpdateOrigin(player, origin)
				end
				if data.skinTone == nil then
					PlayerData.AssignRandomSkinTone(player, data.origin)
					PlayerData.UpdateExternalData(player)
					task.wait(0.5)
					CharacterAppearance.ApplyPlayerAppearance(player)
				end
				if data.hairColor == nil then
					PlayerData.AssignHairColor(player, data.origin)
					PlayerData.UpdateExternalData(player)
					task.wait(0.5)
					CharacterAppearance.ApplyPlayerAppearance(player)
				end
				if data.vestige == nil then
					data.vestige = 5
					PlayerData.UpdateVestige(player, 5)
				end
				if data.Inn == nil then
					local randomInn = inns[math.random(1, #inns)]
					PlayerData.SetInn(player, randomInn)
				end
				local Clothing = require(game.ReplicatedStorage.Clothing)
				if not data.Armor or not Clothing[data.Armor] then
					local defaults =
						{ "LegacyBlackOutfit", "LegacyRedOutfit", "LegacyGreenOutfit", "LegacyPurpleOutfit" }
					data.Armor = defaults[math.random(1, #defaults)]
				end
				CharacterAppearance.ApplyPlayerAppearance(player)
				giveSkillTools(player)
				break
			end
			attempts = attempts + 1
			task.wait(0.5)
		end
	end)
	-- CharacterSetupCoordinator.SetupPlayer(player)
end

Players.PlayerAdded:Connect(assignEchoData)
for _, player in ipairs(Players:GetPlayers()) do
	assignEchoData(player)
end

local Hitbox = require(game.ServerScriptService.Modules.Hitbox)
local CollectionService = game:GetService("CollectionService")

for i, v in pairs(workspace.Campfires:GetDescendants()) do
	if v.Name == "Fire" then
		CollectionService:AddTag(v, "Fire")
	end
end

for _, fire in pairs(CollectionService:GetTagged("Fire")) do
	if fire:IsA("BasePart") then
		fire.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			
			if humanoid then
				Hitbox.ApplyPoison(character) 
			end
		end)
	end
end



ReplicatedStorage.Requests.MenuDone.OnServerEvent:Connect(function(player: Player, ...: any)
	CharacterSetupCoordinator.SetupPlayer(player)
end)

local function calculateFallDamage(fallDistance, fallSpeed)
	local baseDamage = 0
	local maxDamage = 100

	if fallDistance > 25 then
		baseDamage = math.min((fallDistance - 25) * 2, maxDamage)
	end

	if fallSpeed > 80 then
		local speedDamage = math.min((fallSpeed - 80) * 0.5, maxDamage)
		baseDamage = math.max(baseDamage, speedDamage)
	end

	return math.floor(baseDamage)
end

fallDamageRemote.OnServerInvoke = function(player, fallDistance, fallSpeed)
	local character = player.Character
	if not character then
		return 0
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return 0
	end

	local damage = calculateFallDamage(fallDistance, fallSpeed)

	if damage > 0 then
		print(
			"[FallDamage] Player",
			player.Name,
			"took",
			damage,
			"damage from fall. Distance:",
			fallDistance,
			"Speed:",
			fallSpeed
		)
		humanoid:TakeDamage(damage)

		local data = PlayerData.GetData(player)
		if data then
			data.health = humanoid.Health
			PlayerData.UpdateExternalData(player)
		end
	end

	return damage
end

slotDataRemote.OnServerEvent:Connect(function(player, slotData)
	PlayerData.UpdateSlotData(player, slotData)
end)

getSlotDataRemote.OnServerInvoke = function(player)
	return PlayerData.GetSlotData(player)
end
Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		character.Humanoid.Died:Connect(function()
			local data = PlayerData.GetData(player)
			if data then
				local innsinquestion = game.Workspace.Inns[data.Inn]:GetChildren()
				local inntobeused = innsinquestion[math.random(1, #innsinquestion)]
				data.position = inntobeused.Position + Vector3.new(0, 2.5, 0)
				if character.Torso then
					data.vestige -= 1
				end
				local danger = gimmedanger:Invoke()

				local playerdanger = danger[player.Name]
				local damagetable = playerdanger.damagetable
				local highestdamage = 0
				local attacker = nil
				for i, v in damagetable do
					print(i, v)
					if v.damage > highestdamage then
						highestdamage = v.damage
						attacker = i
					end
				end
				if attacker then
					local attackerCharacter = game.Workspace.Living:WaitForChild(attacker)
					if attackerCharacter then
						local attackerinstance = attackerCharacter:Clone()
						local gui = script.KillScreen:Clone()
						local attackerdata = PlayerData.GetData(
							Players:GetPlayerFromCharacter(game.Workspace.Living:FindFirstChild(attacker))
						)
						gui.Parent = player.PlayerGui
						attackerinstance.Parent = gui:WaitForChild("ParentFrame"):WaitForChild("CharacterViewport")
						gui.ParentFrame.NameLabel.Text = attackerdata.name
						gui.ParentFrame.PlayerLabel.Text = attacker
						gui.ParentFrame.DeathInstance.Text = tostring(Players:GetUserIdFromNameAsync(attacker))
						gui.ParentFrame.Timestamp.Text = os.date("{%I:%M %p, %m/%d/%y}")
					end
				end
				local HttpService = game:GetService("HttpService")
				local instanceId = HttpService:GenerateGUID(false)
				local pos = character:FindFirstChild("Torso") and character.Torso.Position or Vector3.new()
				local position = { x = pos.X, y = pos.Y, z = pos.Z }
				local body = {
					instance_id = instanceId,
					attacker = attacker,
					victim = player.Name,
					cause = "combat",
					position = position,
					time = os.date("!%Y-%m-%dT%H:%M:%SZ")
				}
				local url = "http://127.0.0.1:8000/death"
				HttpService:RequestAsync({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(body) })
			end
		end)
	end)
end)
