local StateManager = {}
local Players = game:GetService("Players")
local stateData = {}
local stateEvents = {}

function StateManager.SetState(player, state)
    if not stateData[player] then stateData[player] = {} end
    local old = {}
    for s in pairs(stateData[player]) do old[s] = true end
    stateData[player] = {[state] = true}
    if not stateEvents[player] then stateEvents[player] = Instance.new("BindableEvent") end
    stateEvents[player]:Fire(state, old)
end

function StateManager.AddState(player, state)
    if not stateData[player] then stateData[player] = {} end
    local old = {}
    for s in pairs(stateData[player]) do old[s] = true end
    stateData[player][state] = true
    if not stateEvents[player] then stateEvents[player] = Instance.new("BindableEvent") end
    stateEvents[player]:Fire(state, old)
end

function StateManager.RemoveState(player, state)
    if not stateData[player] then return end
    local old = {}
    for s in pairs(stateData[player]) do old[s] = true end
    stateData[player][state] = nil
    if not stateEvents[player] then stateEvents[player] = Instance.new("BindableEvent") end
    stateEvents[player]:Fire(state, old)
end

function StateManager.HasState(player, state)
    return stateData[player] and stateData[player][state] or false
end

function StateManager.GetStates(player)
    local t = {}
    if stateData[player] then
        for s in pairs(stateData[player]) do table.insert(t, s) end
	end
	print(t)
    return t
end

function StateManager.GetEvent(player)
    if not stateEvents[player] then stateEvents[player] = Instance.new("BindableEvent") end
    return stateEvents[player].Event
end

function StateManager.TempState(player,state, times)
	StateManager.AddState(player, state)
	task.delay(times, function()
		StateManager.RemoveState(player, state)
	end)
end

Players.PlayerRemoving:Connect(function(player)
    stateData[player] = nil
    if stateEvents[player] then stateEvents[player]:Destroy() stateEvents[player] = nil end
end)

return StateManager 