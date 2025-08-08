local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkinTones = require(ReplicatedStorage.SkinTones)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Clothing = require(ReplicatedStorage.Clothing)
local insertservice = game:GetService("InsertService")
local WeaponHandler = require(script.Parent.WeaponHandler)

local CharacterAppearance = {}

local function cloneAvatarAccessoriesToCharacter(player, character)
    if not player or not character then return end
    local userId = player.UserId
    local success, appearanceModel = pcall(function()
        return Players:GetCharacterAppearanceAsync(userId)
    end)
    if not success or not appearanceModel then return end
    for _, accessory in ipairs(appearanceModel:GetChildren()) do
        if accessory:IsA("Accessory") then
            accessory.Parent = character
        end
    end
    appearanceModel:Destroy()
end

local function applySkinToneToCharacter(character, skinTone)
    if not character or not skinTone then return end
    local partsToColor = {"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
    for _, partName in ipairs(partsToColor) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.BrickColor = BrickColor.new(skinTone)
        end
    end
end

local function applyHairColorToCharacter(character, hairColor)
    if not character or not hairColor then return end
    for _, accessory in ipairs(character:GetChildren()) do
        if accessory:IsA("Accessory") and (accessory.AccessoryType == Enum.AccessoryType.Hat or accessory.AccessoryType == Enum.AccessoryType.Hair or accessory.AccessoryType == Enum.AccessoryType.Unknown) then
            local handle = accessory:FindFirstChild("Handle")
            if handle then
                for _, mesh in ipairs(handle:GetChildren()) do
                    if mesh:IsA("SpecialMesh") or mesh:IsA("Mesh") or mesh:IsA("MeshPart") then
                        if mesh:IsA("SpecialMesh") or mesh:IsA("Mesh") then
                            mesh.TextureId = ""
                        elseif mesh:IsA("MeshPart") then
                            mesh.TextureID = ""
                        end
                    end
                end
                if handle:IsA("MeshPart") or handle:IsA("Part") then
                    handle.Color = hairColor
                    handle.Transparency = 0
                end
            end
        end
    end
end

function CharacterAppearance.ApplyPlayerAppearance(player)
    local character = player.Character
    if not character then return end
    
    cloneAvatarAccessoriesToCharacter(player, character)
    
    local data = PlayerData.GetData(player)
    if not data then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and data.Armor and Clothing[data.Armor] then
		local outfit = Clothing[data.Armor]
        for _, obj in ipairs(character:GetChildren()) do
			if obj:IsA("Shirt") or obj:IsA("Pants") then
				obj:Destroy()
			end
		end
		local shirt = character:FindFirstChildOfClass("Shirt")
		local pants = character:FindFirstChildOfClass("Pants")
		if not shirt then
			shirt = Instance.new("Shirt")
			shirt.Parent = character
		end
		if not pants then
			pants = Instance.new("Pants")
			pants.Parent = character
		end
		shirt.ShirtTemplate = "http://www.roblox.com/asset/?id=" .. tostring(outfit.Pants)
		pants.PantsTemplate = "http://www.roblox.com/asset/?id=" .. tostring(outfit.Pants)
       --[[ if outfit.Pants then
            local pants = Instance.new("Pants")
            pants.PantsTemplate = "rbxassetid://" .. tostring(outfit.Pants)
            pants.Parent = character
        end
        if outfit.Shirt then
            local shirt = Instance.new("Shirt")
            shirt.ShirtTemplate = "rbxassetid://" .. tostring(outfit.Shirt)
            shirt.Parent = character
        end]]
        if outfit.Boosts then
            if humanoid and outfit.Boosts.Health then
                humanoid.MaxHealth = 100 * outfit.Boosts.Health
                humanoid.Health = humanoid.MaxHealth
            end
            if humanoid and outfit.Boosts.Walkspeed then
                humanoid.WalkSpeed = 16 + outfit.Boosts.Walkspeed
            end
        end
    end
    
    local skinTone
    if data.skinTone then
        if typeof(data.skinTone) == "table" and #data.skinTone == 3 then
            local r, g, b = data.skinTone[1], data.skinTone[2], data.skinTone[3]
            if r <= 1 and g <= 1 and b <= 1 then
                r = r * 255
                g = g * 255
                b = b * 255
            end
            skinTone = Color3.fromRGB(r, g, b)
        elseif typeof(data.skinTone) == "Color3" then
            skinTone = data.skinTone
        end
    elseif player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("skinTone") then
        local v = player.PlayerData:FindFirstChild("skinTone")
        if v and v:IsA("Color3Value") then
            skinTone = v.Value
        end
    end
    
    if skinTone then
        applySkinToneToCharacter(character, skinTone)
    end
    
    local hairColor
    if data.hairColor then
        if typeof(data.hairColor) == "table" and #data.hairColor == 3 then
            local r, g, b = data.hairColor[1], data.hairColor[2], data.hairColor[3]
            if r <= 1 and g <= 1 and b <= 1 then
                r = r * 255
                g = g * 255
                b = b * 255
            end
            hairColor = Color3.fromRGB(r, g, b)
        elseif typeof(data.hairColor) == "Color3" then
            hairColor = data.hairColor
        end
    elseif player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("hairColor") then
        local v = player.PlayerData:FindFirstChild("hairColor")
        if v and v:IsA("Color3Value") then
            hairColor = v.Value
        end
    end
    
    if hairColor then
        applyHairColorToCharacter(character, hairColor)
	end
	for i,v in character:GetChildren() do
		if v:IsA("Accessory") and not v:FindFirstChild("Handle"):FindFirstChild("HairAttachment") then v:Destroy()
			
		end
	end
    WeaponHandler.loadPlayerWeapon(player)
end



return CharacterAppearance 