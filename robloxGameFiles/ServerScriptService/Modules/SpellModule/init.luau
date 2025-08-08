local StateManager = require(game.ServerScriptService.Modules.StateManager)

local module = {}

local spellpaths = script.SpellPath

local function cdcheck(character,name)
	-- add conditionals here for like extra cd spells and stuff
	return false
end
function module.CastSpell(character, SpellInfo)
	local player = game.Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	if player.Name == "bypass player here heh im sigma" then
		return true
	end
	if StateManager.HasState(player, "Casting") then
		return nil
	end
	if cdcheck(character,SpellInfo.name)then
		return nil
	end
	if character.Humanoid.Health <= 0 then
		return nil
	end
	local Echo = character:GetAttribute("Echo")
	local nobackcast = false
	if SpellInfo.signs and SpellInfo.signs <= 0 then
		wait(0.05)
	end
	StateManager.AddState(player,"Casting")
	local animation
	if SpellInfo.signs and SpellInfo.signs > 0 then
		local cancelled = false
		local casted = 0
		for i = 1,SpellInfo.signs do
			if StateManager.HasState(player, "Knocked") then -- if player gets knocked
				StateManager.RemoveState(player, "Casting")
				return nil
			end
			if not character:FindFirstChild(SpellInfo.name)then -- if player unequips tool
				StateManager.RemoveState(player, "Casting")
				return nil
			end
			character.HumanoidRootPart.Whoosh:Play()
			if spellpaths[SpellInfo.name] then
				if animation then
					animation:Stop()
				end
				animation = character.Humanoid.Animator:LoadAnimation(game.ReplicatedStorage.Animations.CombatAnims.Tome["CastAnim"..spellpaths[SpellInfo.name][i]])
				animation.Priority = Enum.AnimationPriority.Action2
				animation:Play(0.04,1.3,1.5) -- 0.04 second fadein, 1.3 weight, 1.5 speed, DIDN'T TEST THESE, NO ANIMS!
				casted += 1
				if casted == #spellpaths[SpellInfo.name] then
					break
				end
				task.wait(0.15)
			else
				if animation then
					animation:Stop()
				end
				casted += 1
				if casted >= 6 then
					casted = 1
				end
				animation = character.Humanoid.Animator:LoadAnimation(game.ReplicatedStorage.Animations.CombatAnims.Tome["CastAnim"..casted])
				animation.Priority = Enum.AnimationPriority.Action2
				animation:Play(0.04,1.3,1.5) -- 0.04 second fadein, 1.3 weight, 1.5 speed, DIDN'T TEST THESE, NO ANIMS!
				task.wait(0.15)
			end
		end
	end
	StateManager.TempState(player, "SpellCD")
	StateManager.RemoveState(player, "Casting")
	if animation then
		animation:Stop()
	end
	if Echo >= SpellInfo.lowerbound and Echo <= SpellInfo.upperbound or nobackcast then
		return true
	else
		return false
	end
end
return module