local AreaModule = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AreaFolder = Workspace:WaitForChild("Areas")
local AreaChangeRemote = ReplicatedStorage:WaitForChild("Requests"):WaitForChild("AreaChange")

local function checkMethod(p, cf, s)
    local r = cf:PointToObjectSpace(p)
    return math.abs(r.X) <= s.X * 0.5 + 15 and math.abs(r.Z) <= s.Z * 0.5 + 15 and r.Y < 0
end

local function startAreaListener(player)
    local lastArea = nil
    local function onCharacter(char)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            char:GetPropertyChangedSignal("Parent"):Connect(function()
                hrp = char:FindFirstChild("HumanoidRootPart")
            end)
        end
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not player.Parent or not char.Parent then conn:Disconnect() return end
            hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local foundArea = nil
            for _, part in ipairs(AreaFolder:GetChildren()) do
                if part:IsA("BasePart") then
                    if checkMethod(hrp.Position, part.CFrame, part.Size) then
                        foundArea = part.Name
                        break
                    end
                end
            end
            if foundArea ~= lastArea then
                lastArea = foundArea
                if foundArea then
                    AreaChangeRemote:FireClient(player, foundArea)
                end
            end
        end)
        char.AncestryChanged:Connect(function(_, parent)
            if not parent then
                if conn then conn:Disconnect() end
            end
        end)
    end
    player.CharacterAdded:Connect(onCharacter)
    if player.Character then
        onCharacter(player.Character)
    end
end

function AreaModule.start()
    for _, player in ipairs(Players:GetPlayers()) do
        startAreaListener(player)
    end
    Players.PlayerAdded:Connect(startAreaListener)
end

return AreaModule 