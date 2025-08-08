local StateManager = require(script.Parent.StateManager)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ActionCheck = {}

local actionCheckRemote = ReplicatedStorage:FindFirstChild("ActionCheck")
if not actionCheckRemote then
	actionCheckRemote = Instance.new("RemoteFunction")
	actionCheckRemote.Name = "ActionCheck"
	actionCheckRemote.Parent = ReplicatedStorage
end
function ActionCheck:check(player)
	if StateManager.HasState(player, "Dashing") then
		return true
	end
	if StateManager.HasState(player, "techyLockedInAlienSkibidiToilet") then
		return true
	end
	if StateManager.HasState(player, "m1ing") then
		return true
	end
	if StateManager.HasState(player, "Stunned") then
		return true
	end
	if StateManager.HasState(player, "Blocking") then
		return true
	end
	return false
end

actionCheckRemote.OnServerInvoke = function(player)
	return ActionCheck:check(player)
end

return ActionCheck
