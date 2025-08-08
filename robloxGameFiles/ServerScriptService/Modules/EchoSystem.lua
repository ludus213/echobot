local EchoSystem = {}
local actioncheck = require(script.Parent.ActionCheck)
local statemanager = require(script.Parent.StateManager)
EchoSystem.__index = EchoSystem

local chargeEcho = game.ReplicatedStorage.Requests.ChargeEcho
local PlayerData = require(script.Parent.Parent.PlayerData)

function EchoSystem.new()
    local self = setmetatable({}, EchoSystem)
    self.locations = {}
    self:init()
    return self
end

function EchoSystem:init()
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Remote = ReplicatedStorage.Requests:FindFirstChild("Notify")
    local locationsFolder = Workspace:FindFirstChild("EchoLocations")
    if locationsFolder then
        for _, part in ipairs(locationsFolder:GetChildren()) do
            if part:IsA("BasePart") then
                table.insert(self.locations, part)
            end
        end
    end
    Players.PlayerAdded:Connect(function(player)
        self:onPlayerAdded(player)
    end)
    for _, player in ipairs(Players:GetPlayers()) do
        self:onPlayerAdded(player)
    end
end

function EchoSystem:onPlayerAdded(player)
    player.CharacterAdded:Connect(function(char)
        self:onCharacterAdded(player, char)
    end)
    if player.Character then
        self:onCharacterAdded(player, player.Character)
    end
end

function EchoSystem:onCharacterAdded(player, character)
    self:startProximityCheck(player, character)
end

function EchoSystem:startProximityCheck(player, character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local run = game:GetService("RunService")
    local workspace = game:GetService("Workspace")
    local conn
    conn = run.Heartbeat:Connect(function()
        if not player.Parent or not character.Parent then conn:Disconnect() return end
        hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then conn:Disconnect() return end
        for i, part in ipairs(self.locations) do
            if not PlayerData.HasEnteredZone(player, part.Name) then
                local hrpPos = hrp.Position
                local partPos = part.Position
                local partSize = part.Size
                local partCFrame = part.CFrame
                local check = self:checkMethod(hrpPos, partCFrame, partSize)
                if check then
                    local data = PlayerData.GetData(player)
                    if data then
                        data.LatentEcho = data.LatentEcho + 5
                        PlayerData.UpdateLatentEcho(player, data.LatentEcho)
                        PlayerData.AddEnteredZone(player, part.Name)
                        self:notifyEchoIncrease(player)
                    end
                end
            end
        end
    end)
end

function EchoSystem:checkMethod(p, cf, s)
    local r = cf:PointToObjectSpace(p)
    return math.abs(r.X) <= s.X * 0.5 + 15 and math.abs(r.Z) <= s.Z * 0.5 + 15 and r.Y < 0
end

function EchoSystem:notifyEchoIncrease(player)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Remote = ReplicatedStorage.Requests:FindFirstChild("Notify")
    Remote:FireClient(player)
end

local Players = game:GetService("Players")
local lastChargeTime = {}

local function changeEcho(player, delta)
    local character = player.Character
    if not character then return end
    
    local echoValue = character:GetAttribute("Echo")
    if typeof(echoValue) ~= "number" then return end
    
    local newValue = math.clamp(echoValue + delta, 0, 100)
    character:SetAttribute("Echo", newValue)
end

chargeEcho.OnServerEvent:Connect(function(player)
	if actioncheck:check(player) then return end
	if statemanager.HasState(player,"Running") then return end
    lastChargeTime[player] = os.clock()
    changeEcho(player, 3)
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            if character and character:GetAttribute("Echo") then
                local lastTime = lastChargeTime[player] or 0
                if os.clock() - lastTime >= 0.1 then
                    changeEcho(player, -3)
                end
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        char:SetAttribute("Echo", 0)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    lastChargeTime[player] = nil
end)

return EchoSystem