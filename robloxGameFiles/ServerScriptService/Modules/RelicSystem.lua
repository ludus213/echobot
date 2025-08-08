local RelicSystem = {}
RelicSystem.__index = RelicSystem

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Relics = require(ReplicatedStorage:WaitForChild("Relics"))
local PlayerData = require(script.Parent.Parent.PlayerData)

function RelicSystem.new()
    local self = setmetatable({}, RelicSystem)
    self.locations = {}
    self.activeRelics = {}
    self.spawnStates = {}
    self.cooldowns = {}
    self:init()
    return self
end

function RelicSystem:init()
    local locationsFolder = Workspace:FindFirstChild("RelicLocations")
    if locationsFolder then
        for _, part in ipairs(locationsFolder:GetChildren()) do
            if part:IsA("BasePart") then
                local relicValue = part:FindFirstChild("Relic")
                if not relicValue then
                    relicValue = Instance.new("BoolValue")
                    relicValue.Name = "Relic"
                    relicValue.Value = false
                    relicValue.Parent = part
                end
                
                local spawnedValue = part:FindFirstChild("Spawned")
                if not spawnedValue then
                    spawnedValue = Instance.new("BoolValue")
                    spawnedValue.Name = "Spawned"
                    spawnedValue.Value = false
                    spawnedValue.Parent = part
                end
                
                table.insert(self.locations, part)
                self.spawnStates[part] = false
            end
        end
    end
    
    self:startSpawnLoop()
end

function RelicSystem:startSpawnLoop()
    task.spawn(function()
        task.wait(60)
        while true do
            task.wait(5)
            for _, location in ipairs(self.locations) do
                if not location.Spawned.Value and not self.cooldowns[location] then
                    local nearbyPlayers = 0
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            local distance = (player.Character.HumanoidRootPart.Position - location.Position).Magnitude
                            if distance <= 200 then
                                nearbyPlayers = nearbyPlayers + 1
                            end
                        end
                    end
                    
                    if nearbyPlayers == 0 then
                        local playerCount = #Players:GetPlayers()
                        local baseChance = 15
                        local chanceMultiplier = math.max(0.3, 1 - (playerCount * 0.1))
                        local finalChance = baseChance * chanceMultiplier
                        
                        if math.random(1, 100) <= finalChance then
                            self:spawnRelic(location)
                        end
                    end
                end
                task.wait(0.1)
            end
        end
    end)
end

function RelicSystem:spawnRelic(location)
    if location.Spawned.Value or self.cooldowns[location] then return end
    
    local relicModelsFolder = ReplicatedStorage:FindFirstChild("RelicModels")
    if not relicModelsFolder then return end
    
    local relicData = Relics.GetRandomRelic()
    local relicMesh = relicModelsFolder:FindFirstChild(relicData.Name)
    
    if relicMesh then
        local clonedRelic = relicMesh:Clone()
        clonedRelic.CFrame = location.CFrame + Vector3.new(0, 2, 0)
        clonedRelic.Anchored = true
        clonedRelic.Parent = Workspace
        
        local clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 10
        clickDetector.Parent = clonedRelic
        
        local clicked = false
        clickDetector.MouseClick:Connect(function(player)
            if clicked then return end
            
            local character = player.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then return end
            
            local distance = (character.HumanoidRootPart.Position - clonedRelic.Position).Magnitude
            if distance > 15 then return end
            
            clicked = true
            self:onRelicClicked(player, clonedRelic, location, relicData)
        end)
        
        location.Spawned.Value = true
        location.Relic.Value = true
        self.activeRelics[location] = clonedRelic
        self.spawnStates[location] = true
    end
end

function RelicSystem:onRelicClicked(player, relic, location, relicData)
    if not relic.Parent then return end
    
    location.Spawned.Value = false
    location.Relic.Value = false
    self.activeRelics[location] = nil
    self.spawnStates[location] = false
    self.cooldowns[location] = true
    
    if relic.Parent then
        relic:Destroy()
    end
    
    self:giveRelicTool(player, relicData)
    
    task.spawn(function()
        task.wait(30)
        self.cooldowns[location] = nil
    end)
end

function RelicSystem:giveRelicTool(player, relicData)
    local data = PlayerData.GetData(player)
    if not data then return end
    if not data.Relics then data.Relics = {} end
    if not table.find(data.Relics, relicData.Name) then
        table.insert(data.Relics, relicData.Name)
        PlayerData.UpdateExternalData(player)
    end
    local backpack = player:FindFirstChild("Backpack")
    if backpack and not backpack:FindFirstChild(relicData.Name) then
        local tool = Instance.new("Tool")
        tool.Name = relicData.Name
        tool.CanBeDropped = false
        local relicModelsFolder = ReplicatedStorage:FindFirstChild("RelicModels")
        local relicMesh = relicModelsFolder and relicModelsFolder:FindFirstChild(relicData.Name)
        if relicMesh then
            local handle = relicMesh:Clone()
            handle.Name = "Handle"
            handle.Anchored = false
            handle.Parent = tool
        else
            local handle = Instance.new("Part")
            handle.Name = "Handle"
            handle.Size = Vector3.new(1,1,1)
            handle.Parent = tool
        end
        tool.Parent = backpack
    end
end

function RelicSystem:spawnAllRelics()
    for _, location in ipairs(self.locations) do
        self:spawnRelic(location)
    end
end

return RelicSystem 