local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local WeaponHandler = {}
local PlayerData = require(script.Parent.Parent.PlayerData)
local weaponInfo = require(script.Parent.weaponInfo)

local function getCharacter(player)
    return player.Character or player.CharacterAdded:Wait()
end

local function removeExistingWeapon(player)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("WeaponTag") then
                tool:Destroy()
            end
        end
    end
    local character = getCharacter(player)
    for _, obj in ipairs(character:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("BackWeld") then
            obj:Destroy()
        end
    end
end

local function setBackWeaponVisibility(character, visible)
    for _, obj in ipairs(character:GetChildren()) do
        if obj.Name == "BackWeapon" then
          obj.Transparency = visible and 0 or 1
        end
    end
end

local function addBackSword(player, mesh)
    local character = getCharacter(player)
    for _, obj in ipairs(character:GetChildren()) do
        if obj:IsA("MeshPart") and obj.Name == "BackWeapon" then
            obj:Destroy()
        end
        if obj:IsA("Weld") and obj.Name == "BackWeld" then
            obj:Destroy()
        end
    end
    local meshClone = mesh:Clone()
	meshClone.Name = "BackWeapon"
	meshClone.CanCollide = false
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local backWeld = meshClone:FindFirstChild("BackWeld")
    if backWeld and backWeld:IsA("Weld") then
        backWeld.Enabled = true
        backWeld.Part1 = meshClone
        if torso then
            backWeld.Part0 = torso
        end
    end
    meshClone.Parent = character
end

local function removeBackSword(player)
    local character = getCharacter(player)
    for _, obj in ipairs(character:GetChildren()) do
        if obj:IsA("Model") and obj.Name == "BackWeapon" then
            obj:Destroy()
        end
    end
end

local function attachWeaponToSide(tool, player)
    local character = getCharacter(player)
    local rightArm = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    local handle = tool:FindFirstChild("Handle")
    if rightArm and handle then
        handle.Anchored = false
        local weld = Instance.new("Weld")
        weld.Name = "SideWeld"
        weld.Part0 = rightArm
        weld.Part1 = handle
        weld.C0 = CFrame.new(0, -1, 0.5) * CFrame.Angles(0, math.rad(90), 0)
        weld.Parent = rightArm
        tool.RequiresHandle = false
        if tool:FindFirstChild("ToolGrip") then tool.ToolGrip:Destroy() end
    end
end

local function detachWeaponFromSide(tool, player)
    local character = getCharacter(player)
    local rightArm = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    if rightArm then
        for _, weld in ipairs(rightArm:GetChildren()) do
            if weld:IsA("Weld") and weld.Name == "SideWeld" then
                weld:Destroy()
            end
        end
    end
end

function WeaponHandler.setPlayerWeapon(player, weaponName)
	if weaponName == "" then return end
    local weaponModels = ReplicatedStorage:FindFirstChild("WeaponModels")
    if not weaponModels then return end
    local mesh = weaponModels:FindFirstChild(weaponName):Clone()
    if not mesh then return end
    removeExistingWeapon(player)
    addBackSword(player, mesh)
    local tool = Instance.new("Tool")
    tool.Name = weaponName
    local tag = Instance.new("BoolValue")
    tag.Name = "WeaponTag"
    tag.Parent = tool
    local handle = mesh:FindFirstChild("Handle")
    if handle then
        local handleClone = handle:Clone()
        handleClone.Parent = tool
		local youstupid = Instance.new("Weld")
		youstupid.Parent = handleClone
		youstupid.Part0 = handleClone
		youstupid.Part1 = mesh
		handleClone.Parent = tool
		mesh.Parent = tool
    end
    tool.Parent = player:FindFirstChild("Backpack")

    local idleAnimTrack = nil
    local walkAnimTrack = nil
    local movementConnection = nil
    local lastMoveVector = Vector3.new(0, 0, 0)
    
    tool.Equipped:Connect(function()
        setBackWeaponVisibility(getCharacter(player), false)
        attachWeaponToSide(tool, player)
        local handle = tool:FindFirstChild("Handle")
        if handle and not handle:FindFirstChild("toolanim") then
            local toolAnim = Instance.new("StringValue")
            toolAnim.Name = "toolanim"
            toolAnim.Value = "None"
            toolAnim.Parent = handle
        end
        local info = weaponInfo[weaponName]
        
        if info and info.weaponType then
            local combatAnims = ReplicatedStorage:FindFirstChild("Animations"):FindFirstChild("CombatAnims")
            
            if combatAnims then
                local typeFolder = combatAnims:FindFirstChild(info.weaponType)
                if typeFolder and player.Character then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    
                    if humanoid then
                        local idleAnim = typeFolder:FindFirstChild("Idle")
                        local walkAnim = typeFolder:FindFirstChild("Walk")
                        
                        if idleAnim then
                            idleAnimTrack = humanoid:LoadAnimation(idleAnim)
                            idleAnimTrack.Priority = Enum.AnimationPriority.Idle
                        end
                        
                        if walkAnim then
                            walkAnimTrack = humanoid:LoadAnimation(walkAnim)
                            walkAnimTrack.Priority = Enum.AnimationPriority.Movement
                        end
                        
                        local function updateAnimation()
                            local moveVector = humanoid.MoveDirection
                            local isMoving = moveVector.Magnitude > 0.1
                            
                            if isMoving and lastMoveVector.Magnitude <= 0.1 then
                                if idleAnimTrack and idleAnimTrack.IsPlaying then
                                    idleAnimTrack:Stop()
                                end
                                if walkAnimTrack then
                                    walkAnimTrack:Play()
                                end
                            elseif not isMoving and lastMoveVector.Magnitude > 0.1 then
                                if walkAnimTrack and walkAnimTrack.IsPlaying then
                                    walkAnimTrack:Stop()
                                end
                                if idleAnimTrack then
                                    idleAnimTrack:Play()
                                end
                            end
                            
                            lastMoveVector = moveVector
                        end
                        
                        if idleAnimTrack then
                            print("Playing initial idle animation")
                            idleAnimTrack:Play()
                        else
                            print("No idle animation to play!")
                        end
                        movementConnection = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(updateAnimation)
                    end
                else
                    print("Missing type folder or character")
                end
            else
                print("CombatAnims folder not found in ReplicatedStorage")
            end
        else
            print("No weapon info or weapon type found")
        end
    end)
    tool.Unequipped:Connect(function()
        
        setBackWeaponVisibility(getCharacter(player), true)
        detachWeaponFromSide(tool, player)
        
        if movementConnection then
            movementConnection:Disconnect()
            movementConnection = nil
        end
        
        if idleAnimTrack then
            idleAnimTrack:Stop()
            idleAnimTrack:Destroy()
            idleAnimTrack = nil
        end
        
        if walkAnimTrack then
            walkAnimTrack:Stop()
            walkAnimTrack:Destroy()
            walkAnimTrack = nil
        end
        
        lastMoveVector = Vector3.new(0, 0, 0)
    end)
    PlayerData.SetWeapon(player, weaponName)
end

function WeaponHandler.loadPlayerWeapon(player)
    local weaponName = PlayerData.GetWeapon(player)
    if weaponName then
        local character = player.Character or player.CharacterAdded:Wait(5)
        if not character or not character:IsDescendantOf(game) then return end
        local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
        if not backpack then return end
        WeaponHandler.setPlayerWeapon(player, weaponName)
    end
end

return WeaponHandler 