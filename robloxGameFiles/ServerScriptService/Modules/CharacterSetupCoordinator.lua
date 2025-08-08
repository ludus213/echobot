local Players = game:GetService("Players")
local CharacterAppearance = require(script.Parent.CharacterAppearance)
local PlayerData = require(script.Parent.Parent.PlayerData)

local CharacterSetupCoordinator = {}

local function setupCharacterForPlayer(player)
    local character = player.Character
    if not character then return end
    CharacterAppearance.ApplyPlayerAppearance(player)
    local function onRoot()
        PlayerData.LoadPlayerPosition(player)
    end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        onRoot()
    else
        local conn
        conn = character.ChildAdded:Connect(function(child)
            if child.Name == "HumanoidRootPart" then
                onRoot()
                conn:Disconnect()
            end
        end)
    end
end

function CharacterSetupCoordinator.SetupPlayer(player)
    local function onCharacterAdded(character)
        setupCharacterForPlayer(player)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then
        setupCharacterForPlayer(player)
    end
end



return CharacterSetupCoordinator 