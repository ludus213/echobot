local StateManager = require(script.Parent.StateManager)
local StunModule = {}
local timers = {}
local baseSpeed = 16
local stunSpeed = 0

function StunModule.Stun(player, duration)
    if timers[player] then timers[player]:Disconnect() end
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local root = character:FindFirstChild("HumanoidRootPart")
        if humanoid then
            humanoid.WalkSpeed = stunSpeed
        end
        for _, v in ipairs(StateManager.GetStates(player)) do
            if v ~= "Stunned" then
                StateManager.RemoveState(player, v)
            end
        end
        if root then
            for _, bv in ipairs(root:GetChildren()) do
                if bv:IsA("BodyVelocity") then
                    bv:Destroy()
                end
            end
        end
    end
    StateManager.TempState(player, "Stunned", duration)
    timers[player] = game:GetService("RunService").Heartbeat:Connect(function(step)
        duration = duration - step
        if duration <= 0 then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.WalkSpeed = baseSpeed end
            end
            timers[player]:Disconnect()
            timers[player] = nil
        end
    end)
end

return StunModule 