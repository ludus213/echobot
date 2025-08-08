local CombatSystem = {}

type CharacterR6 = Model & {
	Humanoid: Humanoid & {
		Animator: Animator?
	},
	HumanoidRootPart: BasePart,
	Head: BasePart,
	Torso: BasePart,
	LeftArm: BasePart,
	RightArm: BasePart,
	LeftLeg: BasePart,
	RightLeg: BasePart,
}
local attackTable = require(script.AttackTable)


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateManager = require(script.Parent.StateManager)
local ActionCheck = require(script.Parent.ActionCheck)
local Hitbox = require(script.Parent.Hitbox)
local weaponInfo = require(script.Parent.weaponInfo)

local HITBOX_SIZE = Vector3.new(8, 8, 8)
local PERFECT_BLOCK_WINDOW = 0.3

local playerCombatData = {}

function CombatSystem.initialize()
	local combatAttackRemote = ReplicatedStorage:FindFirstChild("Requests"):FindFirstChild("CombatAttack")

	local combatBlockRemote = ReplicatedStorage:FindFirstChild("Requests"):FindFirstChild("CombatBlock")

	local perfectBlockEffectRemote = ReplicatedStorage:FindFirstChild("Requests"):FindFirstChild("PerfectBlockEffect")

	combatAttackRemote.OnServerEvent:Connect(CombatSystem.onAttackReceived)
	combatBlockRemote.OnServerEvent:Connect(CombatSystem.onBlockReceived)

	Players.PlayerAdded:Connect(CombatSystem.onPlayerAdded)
	Players.PlayerRemoving:Connect(CombatSystem.onPlayerRemoving)

	for _, player in pairs(Players:GetPlayers()) do
		CombatSystem.onPlayerAdded(player)
	end
end

function CombatSystem.onPlayerAdded(player)
	playerCombatData[player.UserId] = {
		currentCombo = 0,
		lastAttackTime = 0,
		comboResetTime = 2.5,
		isBlocking = false,
		blockStartTime = 0,
		perfectBlockActive = false
	}
end

function CombatSystem.onPlayerRemoving(player)
	playerCombatData[player.UserId] = nil
end

function CombatSystem.onAttackReceived(player, attackType, comboCount, isLastHit)
	print('attack remote recieved with args:', player, attackType, comboCount, isLastHit)
	if not CombatSystem.canPerformAction(player) then return end
	print('could perform action')

	local weaponData = CombatSystem.getCurrentWeaponInfo(player)
	local playerData = playerCombatData[player.UserId]
	if not playerData then return end

	local currentTime = tick()

	if currentTime - playerData.lastAttackTime > playerData.comboResetTime then
		playerData.currentCombo = 0
	end

	playerData.currentCombo = playerData.currentCombo + 1
	if playerData.currentCombo > weaponData.M1Amount then
		playerData.currentCombo = 1
	end

	playerData.lastAttackTime = currentTime

	local actualIsLastHit = playerData.currentCombo == weaponData.M1Amount

	CombatSystem.performAttack(player, attackType, playerData.currentCombo, actualIsLastHit, weaponData)
	if actualIsLastHit then
		playerData.currentCombo = 0
	end
end

function CombatSystem.onBlockReceived(player, isBlocking)
	local playerData = playerCombatData[player.UserId]
	if not playerData then return end

	if isBlocking then
		if ActionCheck:check(player) then 
			return
		end
		if StateManager.HasState(player,"Running") then 
			return
		end
		playerData.isBlocking = true
		playerData.blockStartTime = tick()
		playerData.perfectBlockActive = true
		StateManager.AddState(player, "Blocking")
		local character:CharacterR6 = player.Character
		local block = character.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.CombatAnims.Fist.Block)
		block:Play()
		character.Humanoid.WalkSpeed -= 9

		task.spawn(function()
			task.wait(PERFECT_BLOCK_WINDOW)
			playerData.perfectBlockActive = false
		end)
	elseif StateManager.HasState(player,"Blocking") then
		playerData.isBlocking = false
		playerData.perfectBlockActive = false
		local character:CharacterR6 = player.Character
		for i,v in character.Humanoid.Animator:GetPlayingAnimationTracks() do 
			if v.Name == "Block" then
				v:Stop()
			end
		end
		character.Humanoid.WalkSpeed += 9
		StateManager.RemoveState(player, "Blocking")
	end
end

function CombatSystem.performAttack(attacker : Player, attackType : string, comboCount :number, isLastHit : boolean, weaponData)
	if not attacker.Character or not attacker.Character:FindFirstChild("HumanoidRootPart") then return end
	if not game.ReplicatedStorage.Animations.CombatAnims[weaponData.weaponType] or not game.ReplicatedStorage.Animations.CombatAnims[weaponData.weaponType][tostring("P"..comboCount)] then
		warn("Animation not found for weaponType: " .. weaponData.weaponType .. ", comboCount: " .. comboCount)
		return
	end
	local attackerCharacter : CharacterR6 = attacker.Character
	local attackerAnimator : Animator = attackerCharacter.Humanoid.Animator
	local animation = game.ReplicatedStorage.Animations.CombatAnims[weaponData.weaponType][tostring("P"..comboCount)]
	StateManager.AddState(attacker, "m1ing")

	local anim = attackerAnimator:LoadAnimation(animation)
	anim:Play()

	local rootPart = attacker.Character.HumanoidRootPart


	local attackInfo = CombatSystem.createAttackInfo(attackType, comboCount, isLastHit, weaponData, attacker)

	anim.KeyframeReached:Connect(function(keyframeName: string)
		if keyframeName == 'hitbox' then
			local hitboxPosition = rootPart.CFrame * CFrame.new(0, 0, -4)
			Hitbox.CreateHitbox(hitboxPosition, HITBOX_SIZE, attackInfo, attacker.Character)
		end
	end)

	local stunDuration = (attackInfo.stunTime or 0.8) / weaponData.attackSpeed
	if attackType == "Crit" then
		stunDuration = stunDuration * 1.5
	end

	StateManager.TempState(attacker, "Stunned", stunDuration)

	task.spawn(function()
		task.wait(0.1)
		StateManager.RemoveState(attacker, "m1ing")
	end)
end

function CombatSystem.createAttackInfo(attackType, comboCount, isLastHit, weaponData, attacker)
	local attackInfo = {
		damage = attackType == "Crit" and weaponData.critDamage or weaponData.damage,
		attackType = attackType,
		comboCount = comboCount,
		isLastHit = isLastHit,
		chip = weaponData.chip,
		blockDamageReduction = weaponData.blockDamageReduction,
		stunTime = 0.8,
		attacker = attacker
	}
	
	if attackType == "Crit" then
		attackInfo.ragdoll = true
		attackInfo.ragdollTime = 2
		attackInfo.knockback = 50
		attackInfo.perfectBlockWindow = true
		attackInfo.perfectBlockStun = 1.5
		attackInfo.punishMiss = true
		attackInfo.missStunTime = 0.5
		attackInfo.fire = true
	end

	if isLastHit then
		attackInfo.ragdoll = true
		attackInfo.ragdollTime = 2
		attackInfo.knockback = 20
		attackInfo.punishMiss = true
		attackInfo.missStunTime = 0.5
	else
		attackInfo.stun = true
		attackInfo.stunTime = 0.4
	end



	return attackInfo
end

function CombatSystem.getCurrentWeaponInfo(player)
	if not player.Character then return weaponInfo["Fist"] end

	local equippedTool = player.Character:FindFirstChildOfClass("Tool")
	if equippedTool and equippedTool:FindFirstChild("WeaponTag") then
		print(equippedTool.Name)
		return weaponInfo[equippedTool.Name] or weaponInfo["Fist"]
	end
	return weaponInfo["Fist"]
end

function CombatSystem.canPerformAction(player)
	print('checking action')
	if not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") then return false end
	if StateManager.HasState(player, "Stunned") then return false end
	if StateManager.HasState(player, "Ragdolled") then return false end
	if StateManager.HasState(player, "Blocking") then return false end
	if ActionCheck:check(player) then return false end
	print(' returned true!')
	return true
end

function CombatSystem.PerformSkillAttack(player : Player,animation :Animation)
	local character : CharacterR6 = player.Character
	local anim : AnimationTrack = character.Humanoid.Animator:LoadAnimation(animation)
	anim:Play()
	anim.KeyframeReached:Connect(function(name)
		if name == 'hitbox' then
			local hitboxPosition = character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -4)
			Hitbox.CreateHitbox(hitboxPosition, HITBOX_SIZE, {
				damage = 10,
				stunTime = 1,
				attacker = character
			}, character)
		else
			local attackinfo = attackTable[name]
			local hitboxposition = character.HumanoidRootPart.CFrame * attackinfo.hitboxoffset
			local hitboxsize = attackinfo.hitboxsize
			local hitboxinfo = attackinfo.hitboxinfo
			Hitbox.CreateHitbox(hitboxposition,hitboxsize,hitboxinfo,character)
		end
	end)
end

return CombatSystem
