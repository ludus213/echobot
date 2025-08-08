local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local function getRemote()
    local remote = ReplicatedStorage.Requests:FindFirstChild("FallDamageEvent")
    if not remote then
        remote = Instance.new("RemoteFunction")
        remote.Name = "FallDamageEvent"
        remote.Parent = ReplicatedStorage
    end
    return remote
end

local function setupFallDetection(character)
    local humanoid = character:FindFirstChild("Humanoid") or character.ChildAdded:Wait()
    while humanoid and not humanoid:IsA("Humanoid") do
        humanoid = character.ChildAdded:Wait()
    end
    local root = character:FindFirstChild("HumanoidRootPart") or character.ChildAdded:Wait()
    while root and not root:IsA("BasePart") or root.Name ~= "HumanoidRootPart" do
        root = character.ChildAdded:Wait()
    end
    local falling = false
    local maxFallSpeed = 0
    local lastY = root.Position.Y
    humanoid.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Freefall then
            falling = true
            maxFallSpeed = 0
            lastY = root.Position.Y
        elseif falling and (new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Seated) then
            falling = false
            local landedY = root.Position.Y
            local fallDistance = lastY - landedY
            if fallDistance > 25 or math.abs(maxFallSpeed) > 80 then
                local remote = getRemote()
                local damage = remote:InvokeServer(fallDistance, math.abs(maxFallSpeed))
            end
        end
    end)
    root.Touched:Connect(function(hit)
        if falling then
            local landedY = root.Position.Y
            local fallDistance = lastY - landedY
            if fallDistance > 25 or math.abs(maxFallSpeed) > 80 then
                local remote = getRemote()
                local damage = remote:InvokeServer(fallDistance, math.abs(maxFallSpeed))
            end
            falling = false
        end
    end)
    game:GetService("RunService").RenderStepped:Connect(function()
        if falling then
            local vy = root.Velocity.Y
            if vy < maxFallSpeed then
                maxFallSpeed = vy
            end
        end
    end)
end

player.CharacterAdded:Connect(setupFallDetection)
if player.Character then
    setupFallDetection(player.Character)
end 