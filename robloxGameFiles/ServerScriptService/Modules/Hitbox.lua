local Hitbox = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local StunModule = require(script.Parent.StunModule)
local StateManager = require(script.Parent.StateManager)
local RagdollModule = require(script.Parent.RagdollModule)

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

function Hitbox.CreateHitbox(position, size, attackInfo, attacker)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = {workspace.Living}

	local visualBox = Instance.new("Part")
	visualBox.Size = size
	visualBox.CFrame = position
	visualBox.Anchored = true
	visualBox.CanCollide = false
	visualBox.Transparency = 0.5
	visualBox.Color = Color3.fromRGB(255, 0, 0)
	visualBox.Material = Enum.Material.Neon
	visualBox.Name = "HitboxVisualizer"
	visualBox.Parent = workspace
	game:GetService("Debris"):AddItem(visualBox, 0.25)

	local partsInBox = workspace:GetPartBoundsInBox(position, size, overlapParams)
	local alreadyHit = {}
	local hitTargets = {}

	for _, part in ipairs(partsInBox) do
		if part.Parent:IsA("Model") then
			local character = part.Parent
			local humanoid = character:FindFirstChildOfClass("Humanoid")

			if humanoid and not table.find(alreadyHit, character) and character ~= attacker then
				local player = Players:GetPlayerFromCharacter(character)
				if not player then continue end

				if StateManager.HasState(player, "knocked") then continue end
				if StateManager.HasState(player, "Ragdolled") then continue end

				table.insert(alreadyHit, character)
				table.insert(hitTargets, {player = player, character = character, humanoid = humanoid})
			end	
		end
	end
	for i, target in ipairs(hitTargets) do
		print(i,":", target)
		Hitbox.ApplyHitEffects(target.player, target.character, target.humanoid, attackInfo, attacker)
	end
	if hitTargets == {} then
		print('attempting endlag')
		local endlag = attackInfo.punishMiss or false
		if endlag then 
			local endlagStun = attackInfo.missStunTime or 0.5 
			StunModule.Stun(attacker, endlagStun)
		end
	end

	return hitTargets
end

function Hitbox.ApplyHitEffects(victim, character, humanoid, attackInfo, attackerCharacter)
	local attacker = Players:GetPlayerFromCharacter(attackerCharacter)
	local damage = attackInfo.damage or 0
	local isBlocking = StateManager.HasState(victim, "Blocking")
	if isBlocking then
		if attackInfo.attackType == "Crit" and attackInfo.perfectBlockWindow then
			Hitbox.HandlePerfectBlock(attacker, victim, attackInfo)
			return
		else
			damage = Hitbox.ApplyBlockDamageReduction(damage, attackInfo)
		end
	end

	if damage > 0 then
		humanoid:TakeDamage(damage)
	end

	Hitbox.ApplyStatusEffects(victim, character, attackInfo, attacker)
end

function Hitbox.HandlePerfectBlock(attacker : CharacterR6, victim : CharacterR6, attackInfo)
	StateManager.TempState(attacker, "Stunned", attackInfo.perfectBlockStun or 1.5)

	local perfectBlockEffectRemote = ReplicatedStorage:FindFirstChild("PerfectBlockEffect")
	if perfectBlockEffectRemote then
		perfectBlockEffectRemote:FireClient(attacker)
	end
end

function Hitbox.ApplyBlockDamageReduction(damage, attackInfo)
	local blockReduction = attackInfo.blockDamageReduction or 0.8
	local reducedDamage = damage * (1 - blockReduction)

	if not attackInfo.chip then
		reducedDamage = reducedDamage * 0.3
	end

	return reducedDamage
end


function Hitbox.ApplyStatusEffects(victim, character, attackInfo, attacker)
	if attackInfo.ragdoll then
		local ragdollTime = attackInfo.ragdollTime or 2
		RagdollModule.ragdollWithTime(character, ragdollTime)
		StateManager.TempState(victim, "Ragdolled", ragdollTime)

		if attackInfo.knockback and attacker and attacker.Character then
			Hitbox.ApplyKnockback(character, attacker.Character, attackInfo.knockback)
		end
	end
	if attackInfo.stun then
		local stunTime = attackInfo.stunTime or 0.8
		StateManager.TempState(victim, "Stunned", stunTime)
	end
	if attackInfo.fire then
		local fireTime = attackInfo.fireTime or 5
		Hitbox.ApplyNormalFire(victim,fireTime,0.2)
	end
	if attackInfo.poison then
		local poisontime = attackInfo.poisonTime or 4
		Hitbox.ApplyPoison(victim,poisontime,5)
	end
end

function Hitbox.ApplyKnockback(victimCharacter, attackerCharacter, knockbackForce)
	local victimRoot = victimCharacter:FindFirstChild("HumanoidRootPart")
	local attackerRoot = attackerCharacter:FindFirstChild("HumanoidRootPart")

	if not victimRoot or not attackerRoot then return end

	local direction = (victimRoot.Position - attackerRoot.Position).Unit
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
	bodyVelocity.Velocity = direction * (knockbackForce or 50)
	bodyVelocity.Parent = victimRoot

	task.spawn(function()
		task.wait(0.5)
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
	end)
end

function Hitbox.ApplyNormalFire(Victim : CharacterR6 ,Firetime : number, FireDamage : number)
	if StateManager.HasState(game.Players:GetPlayerFromCharacter(Victim), "Burning") then
		print('already burning')
		return
	end
	StateManager.TempState(game.Players:GetPlayerFromCharacter(Victim), "Burning", Firetime)
	if not Firetime then Firetime = 30 end
	local victimRoot = Victim:FindFirstChild("HumanoidRootPart")
	if not victimRoot then return end
	local timeinseconds = 0
	local willkill = false
	local fireSound

	for _,v in victimRoot:GetChildren() do
		if v.Name == "FireEffect" and v:IsA("ParticleEmitter") then
			v.Enabled = true
		end
		if v.Name == "Fire" and v:IsA("Sound") then
			v.Looped = true
			v:Play()
			fireSound = v
		end
	end

	task.spawn(function()
		while victimRoot:FindFirstChild("Fire") and victimRoot.Fire.IsPlaying do 
			if timeinseconds > Firetime then
				for _,v in Victim.Torso:GetChildren() do
					if v.Name == "FireEffect" and v:IsA("ParticleEmitter") then
						v.Enabled = false 
					end
				end
				if fireSound then
						fireSound:Stop()
				end
				break
			else
				if Victim:FindFirstChild("Knocked") and not willkill then
					timeinseconds = 0
					willkill = true
				end
				task.wait(0.5)
				timeinseconds += 0.5
				Victim.Humanoid:TakeDamage(FireDamage)
			end
			if willkill and timeinseconds < 6  then
				local shirt = Victim:FindFirstChildOfClass("Shirt")
				local pants = Victim:FindFirstChildOfClass("Pants")
				if shirt then
					shirt:Destroy()
				end
				if pants then
					pants:Destroy()
				end
				local parts = {"Left Arm", "Right Arm", "Left Leg", "Right Leg", "Torso", "Head"}
				for _,partName in ipairs(parts) do
					local part = Victim:FindFirstChild(partName)
					if part and part:IsA("BasePart") then
						part.Material = Enum.Material.Concrete
						part.BrickColor = BrickColor.new("Dark stone grey")
						local tweenInfo = TweenInfo.new(5, Enum.EasingStyle.Linear)
						local tween = game:GetService("TweenService"):Create(part, tweenInfo, {Size = Vector3.new(0, 0, 0)})
						tween:Play()
					end
				end
				StateManager.TempState(game.Players:GetPlayerFromCharacter(Victim),"Dead",0.5)
				Victim.Humanoid:TakeDamage(1000)
				
				for _,v in Victim:GetDescendants() do
					if v.Name == "FireEffect" and v:IsA("ParticleEmitter") then
						v.Enabled = false
					end
				end
				if fireSound then
					fireSound:Stop()
				end
				break
			end
		end
	end)
end

function Hitbox.ApplyPoison(Victim : CharacterR6)
	local player = game.Players:GetPlayerFromCharacter(Victim)
	if StateManager.HasState(player, "Poison") then return end
	StateManager.AddState(player, "Poison")
	local victimroot = Victim.HumanoidRootPart
	local sound : Sound = victimroot.Poison
	victimroot.PoisonEffect.Enabled = true
	sound:Play()
	
	task.spawn(function()
		local totaldam = Victim.Humanoid.MaxHealth / 5
		local damage = totaldam / 20
		for i = 1, 20 do
			task.wait(0.2)
			Victim.Humanoid:TakeDamage(damage)
			victimroot.PoisonEffect:Emit(8)
		end
		victimroot.PoisonEffect.Enabled = false
		StateManager.RemoveState(player, "Poison")
	end)
	
end

return Hitbox
