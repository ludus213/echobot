local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RelicSystem = require(script.Parent.Modules.RelicSystem)
local PhysicsService = game:GetService("PhysicsService")

local BagSystem = {}

local playerBags = {}
local playerDropTimestamps = {}
local lastBagDropTimestamps = {}

-- Ensure collision groups are set up
local function setupCollisionGroups()
    pcall(function()
        if not PhysicsService:CollisionGroupExists("Bag") then
            PhysicsService:RegisterCollisionGroup("Bag")
        end
        if not PhysicsService:CollisionGroupExists("Players") then
            PhysicsService:RegisterCollisionGroup("Players")
        end
        PhysicsService:CollisionGroupSetCollidable("Bag", "Bag", false)
        PhysicsService:CollisionGroupSetCollidable("Bag", "Players", false)
        PhysicsService:CollisionGroupSetCollidable("Bag", "Default", false)
    end)
end
setupCollisionGroups()

local function setCollisionGroupRecursive(object, group)
    pcall(function()
        if object:IsA("BasePart") then
            object.CollisionGroup = group
        end
        for _, child in ipairs(object:GetChildren()) do
            setCollisionGroupRecursive(child, group)
        end
    end)
end

local function setLivingCollisionGroup()
    local living = workspace:FindFirstChild("Living")
    if living then
        for _, obj in ipairs(living:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.CollisionGroup = "Players"
            end
        end
    end
end
setLivingCollisionGroup()

function BagSystem.createBagDrop(player, itemName)
    local now = tick()
    local userId = player.UserId
    playerBags[userId] = playerBags[userId] or {}
    playerDropTimestamps[userId] = playerDropTimestamps[userId] or {}
    lastBagDropTimestamps[userId] = lastBagDropTimestamps[userId] or 0
    local dropTimes = playerDropTimestamps[userId]
    table.insert(dropTimes, now)
    while #dropTimes > 0 and now - dropTimes[1] > 10 do table.remove(dropTimes, 1) end
    local recentDrops = #dropTimes
    local pickupDelay = math.clamp(1.2 + (recentDrops-1)*0.6, 1.2, 5)
    local dropCooldown = math.clamp(0.2 + (recentDrops-1)*0.8, 0.2, 5)
    if now - lastBagDropTimestamps[userId] < dropCooldown then return false end
    lastBagDropTimestamps[userId] = now
    if #playerBags[userId] >= 5 then
        local oldest = table.remove(playerBags[userId], 1)
        if oldest and oldest.Parent then oldest:Destroy() end
    end
    local character = player.Character
    if not character then return false end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local bagMesh = ReplicatedStorage:FindFirstChild("Meshes") and ReplicatedStorage.Meshes:FindFirstChild("Bag")
    if not bagMesh then return false end
    local bag = bagMesh:Clone()
    bag.Name = "DroppedBag"
    bag.Anchored = false
    bag.CanCollide = false
    bag.Position = root.Position + root.CFrame.LookVector * 4 + Vector3.new(0, 2, 0)
    bag.Orientation = Vector3.new(0, root.Orientation.Y, 0)
    bag.Parent = Workspace
    table.insert(playerBags[userId], bag)
    -- set up collision group for bags and disable collision with players
    setCollisionGroupRecursive(bag, "Bag")
    setLivingCollisionGroup()
    bag.Transparency = 0.2
    local canPickup = false
    task.delay(pickupDelay, function()
        bag.Transparency = 0
        canPickup = true
    end)
    local touchConn
    touchConn = bag.Touched:Connect(function(hit)
        if not canPickup then return end
        local toucher = Players:GetPlayerFromCharacter(hit.Parent)
        if toucher then
            RelicSystem:giveRelicTool(toucher, {Name = itemName})
            bag:Destroy()
            if touchConn then touchConn:Disconnect() end
            for i, b in ipairs(playerBags[userId]) do
                if b == bag then table.remove(playerBags[userId], i) break end
            end
        end
    end)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BagBillboard"
    billboard.Adornee = bag
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.MaxDistance = 50
    billboard.AlwaysOnTop = true
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "Bag: " .. itemName
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.5
    label.TextScaled = true
    label.Font = Enum.Font.FredokaOne
    label.Parent = billboard
    billboard.Parent = bag
    return true
end

return BagSystem 