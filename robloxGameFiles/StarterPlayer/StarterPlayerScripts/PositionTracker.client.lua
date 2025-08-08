local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local updateEvent = ReplicatedStorage.Requests:WaitForChild("UpdatePosition")
local allowSaveRemote = ReplicatedStorage.Requests:FindFirstChild("AllowPositionSave")

local function sendPosition()
    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    updateEvent:FireServer(root.Position)
end

local function applyForceField()
    local character = player.Character
    if not character then return end
    if not character:FindFirstChildOfClass("ForceField") then
        Instance.new("ForceField", character)
    end
end

local function removeForceField()
    local character = player.Character
    if not character then return end
    local ff = character:FindFirstChildOfClass("ForceField")
    if ff then ff:Destroy() end
end

player.CharacterAdded:Connect(function(character)
    local root = character:WaitForChild("HumanoidRootPart", 5)
    if not root then return end
    applyForceField()
    local startPos = root.Position
    local moved = false
    local startTime = tick()
    while character.Parent do
        sendPosition()
        if (root.Position - startPos).magnitude > 10 then
            moved = true
            break
        end
        if tick() - startTime > 120 then
            break
        end
        task.wait(0.1)
    end
    removeForceField()
    allowSaveRemote:FireServer()
    while character.Parent do
        sendPosition()
        task.wait(0.1)
    end
end)

if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
    local root = player.Character:WaitForChild("HumanoidRootPart", 5)
    if not root then return end
    applyForceField()
    local startPos = root.Position
    local moved = false
    local startTime = tick()
    while player.Character.Parent do
        sendPosition()
        if (root.Position - startPos).magnitude > 10 then
            moved = true
            break
        end
        if tick() - startTime > 120 then
            break
        end
        task.wait(0.1)
    end
    removeForceField()
    allowSaveRemote:FireServer()
    while player.Character.Parent do
        sendPosition()
        task.wait(0.1)
    end
end 