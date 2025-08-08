local Players = game:GetService("Players")
local ChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local emotesFolder = game.ReplicatedStorage.Animations.EmoteAnims
-- TYPES:
-- "loop": Animation loops until the player moves.
-- "once": Animation plays once and then stops.
-- "hold": Animation plays, then freezes at the last keyframe until the player moves.

local EMOTE_IDS = {
    ["defy"] = {Anim = emotesFolder["Defy Emote"], Type = "loop"},
    ["rest"] = {Anim = emotesFolder["Resting Emote"], Type = "hold"},
    ["ponder"] = {Anim = emotesFolder["Pondering Emote"], Type = "loop"},
    ["meditate"] = {Anim = emotesFolder["Meditate Emote"], Type = "hold"},
    ["disappointed"] = {Anim = emotesFolder["Disappointed Emote"], Type = "loop"},
    ["l"] = {Anim = emotesFolder["L Emote"], Type = "loop"},
    ["laugh"] = {Anim = emotesFolder["Laughing Emote"], Type = "once"},
    ["kneel"] = {Anim = emotesFolder["Kneeling Emote"], Type = "hold"},
    ["wave"] = {Anim = emotesFolder["Wave Emote"], Type = "once"}
}

local activeEmotes = {}
local playerConnections = {}
local freezeConnections = {}
local positionConnections = {}

local function stopEmote(player)
    if activeEmotes[player] then
        if freezeConnections[player] then
            freezeConnections[player]:Disconnect()
            freezeConnections[player] = nil
        end
        if positionConnections[player] then
            positionConnections[player]:Disconnect()
            positionConnections[player] = nil
        end
        pcall(function()
            activeEmotes[player]:AdjustSpeed(1)
        end)
        activeEmotes[player]:Stop()
        activeEmotes[player] = nil
    end
    if playerConnections[player] then
        for _, connection in pairs(playerConnections[player]) do
            connection:Disconnect()
        end
        playerConnections[player] = nil
    end
end

local function setupMovementListener(player)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    if playerConnections[player] then
        for _, connection in pairs(playerConnections[player]) do
            connection:Disconnect()
        end
    end
    playerConnections[player] = {}
    local function onStateChanged(oldState, newState)
        if newState == Enum.HumanoidStateType.Jumping or 
           newState == Enum.HumanoidStateType.Running or 
           newState == Enum.HumanoidStateType.Climbing or
           newState == Enum.HumanoidStateType.Swimming then
            stopEmote(player)
        end
    end
    local function onMove()
        stopEmote(player)
    end
    table.insert(playerConnections[player], humanoid.StateChanged:Connect(onStateChanged))
    table.insert(playerConnections[player], humanoid.MoveToFinished:Connect(onMove))
end

local function handleEmoteCommand(player, message)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    local emoteName = message:match("/e%s+(%w+)")
    local emoteData = EMOTE_IDS[emoteName and emoteName:lower() or ""]
    if not emoteData or not emoteData.Anim or not emoteData.Anim:IsA("Animation") then return end
    stopEmote(player)
    setupMovementListener(player)
    local animationTrack = animator:LoadAnimation(emoteData.Anim)
    activeEmotes[player] = animationTrack
    local emoteType = emoteData.Type
    if emoteType == "loop" then
        animationTrack.Looped = true
        animationTrack:Play()
    elseif emoteType == "once" then
        animationTrack.Looped = false
        animationTrack:Play()
    elseif emoteType == "hold" then
        animationTrack.Looped = false
        animationTrack:Play()
        freezeConnections[player] = RunService.Heartbeat:Connect(function()
            if animationTrack.Length > 0 and animationTrack.TimePosition >= animationTrack.Length - 0.05 then
                animationTrack.TimePosition = animationTrack.Length - 0.01
                animationTrack:AdjustSpeed(0)
            end
        end)
    end
    local lastPos = root.Position
    positionConnections[player] = RunService.Heartbeat:Connect(function()
        if (root.Position - lastPos).magnitude > 2 then
            stopEmote(player)
        else
            lastPos = root.Position
        end
    end)
    animationTrack.Stopped:Connect(function()
        if freezeConnections[player] then
            freezeConnections[player]:Disconnect()
            freezeConnections[player] = nil
        end
        if positionConnections[player] then
            positionConnections[player]:Disconnect()
            positionConnections[player] = nil
        end
    end)
end

local function onPlayerChatted(player, message)
    if message:match("^/e%s+") then
        handleEmoteCommand(player, message)
    end
end

local function onPlayerAdded(player)
    player.Chatted:Connect(function(message)
        onPlayerChatted(player, message)
    end)
    player.CharacterAdded:Connect(function()
        setupMovementListener(player)
    end)
end

local function onPlayerRemoving(player)
    stopEmote(player)
    if playerConnections[player] then
        for _, connection in pairs(playerConnections[player]) do
            connection:Disconnect()
        end
        playerConnections[player] = nil
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end 