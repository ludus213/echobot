task.wait(3)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

while player:FindFirstChild("InMenu") do
	task.wait()
end

local dangerGui = script.Parent
local danger = dangerGui:WaitForChild("Danger")
local skull = danger:WaitForChild("Skull")
local danger1 = danger:WaitForChild("Danger")
local danger2 = danger:WaitForChild("DangerText")

local originalPositions = {}
local isInDanger = false
local timerVisible = false

local DangerMessages = {
    ["Leaving now could seal your fate."] = 5000,
    ["Fleeing now may cost you everything."] = 5000,
    ["Turning back now could be a fatal mistake."] = 5000,
    ["The void stirs-stay or be claimed."] = 5000,
    ["Escape is unwise. Danger still lingers."] = 5000,
    ["Your presence is still bound to this fight."] = 5000,
    ["Departing now may doom your soul."] = 5000,
    ["You are not safe. Remain where you stand."] = 5000,
    ["The echo of danger has not faded yet."] = 5000,
    ["Abandoning now may have dire consequences."] = 5000,
    ["Don't CLog, or else you'll die."] = 1
}

local function getRandomDangerMessage()
    local totalWeight = 0
    for _, weight in pairs(DangerMessages) do
        totalWeight = totalWeight + weight
    end
    
    local random = math.random() * totalWeight
    local currentWeight = 0
    
    for message, weight in pairs(DangerMessages) do
        currentWeight = currentWeight + weight
        if random <= currentWeight then
            return message
        end
    end
    
    return "Danger lurks in the shadows."
end

local function storeOriginalPositions()
    originalPositions[danger] = danger.Position
    originalPositions[skull] = skull.Position
    originalPositions[danger1] = danger1.Position
    originalPositions[danger2] = danger2.Position
end

local function moveOffScreen()
    local offScreenY = -200
    danger.Position = UDim2.new(danger.Position.X.Scale, danger.Position.X.Offset, 0, offScreenY)
    skull.Position = UDim2.new(skull.Position.X.Scale, skull.Position.X.Offset, 0, offScreenY)
    danger1.Position = UDim2.new(danger1.Position.X.Scale, danger1.Position.X.Offset, 0, offScreenY)
    danger2.Position = UDim2.new(danger2.Position.X.Scale, danger2.Position.X.Offset, 0, offScreenY)
end

local function slideIn()
    if isInDanger then return end
    isInDanger = true
    
    danger2.Text = getRandomDangerMessage()
    
    local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    local dangerTween = TweenService:Create(danger, tweenInfo, {Position = originalPositions[danger]})
    local skullTween = TweenService:Create(skull, tweenInfo, {Position = originalPositions[skull]})
    local danger1Tween = TweenService:Create(danger1, tweenInfo, {Position = originalPositions[danger1]})
    local danger2Tween = TweenService:Create(danger2, tweenInfo, {Position = originalPositions[danger2]})
    
    dangerTween:Play()
    skullTween:Play()
    danger1Tween:Play()
    danger2Tween:Play()
end

local function slideOut()
    if not isInDanger then return end
    isInDanger = false
    timerVisible = false
    
    local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    local offScreenY = -200
    
    local dangerTween = TweenService:Create(danger, tweenInfo, {Position = UDim2.new(danger.Position.X.Scale, danger.Position.X.Offset, 0, offScreenY)})
    local skullTween = TweenService:Create(skull, tweenInfo, {Position = UDim2.new(skull.Position.X.Scale, skull.Position.X.Offset, 0, offScreenY)})
    local danger1Tween = TweenService:Create(danger1, tweenInfo, {Position = UDim2.new(danger1.Position.X.Scale, danger1.Position.X.Offset, 0, offScreenY)})
    local danger2Tween = TweenService:Create(danger2, tweenInfo, {Position = UDim2.new(danger2.Position.X.Scale, danger2.Position.X.Offset, 0, offScreenY)})
    
    dangerTween:Play()
    skullTween:Play()
    danger1Tween:Play()
    danger2Tween:Play()
end

local function updateTimer()
    local dangerTime = player:FindFirstChild("DangerTime")
    if not dangerTime then return end
    
    local timeValue = dangerTime.Value
    if timeValue > 0 then
        if not isInDanger then
            slideIn()
        end
    else
        if isInDanger then
            slideOut()
        end
    end
end

local function updateTimerDisplay()
    if timerVisible then
        local dangerTime = player:FindFirstChild("DangerTime")
        if dangerTime then
            local timeValue = dangerTime.Value
            local minutes = math.floor(timeValue / 60)
            local seconds = timeValue % 60
            local timeText = string.format("%02d:%02d", minutes, seconds)
            skull.Time.Text = timeText
        end
    end
end

local function setupHoverEffects()
    skull.MouseEnter:Connect(function()
        if isInDanger then
            timerVisible = true
            updateTimerDisplay()
            skull.Time.Visible = true
        end
    end)
    
    skull.MouseLeave:Connect(function()
        timerVisible = false
        skull.Time.Visible = false
    end)
end

local function initialize()
    storeOriginalPositions()
    moveOffScreen()
    setupHoverEffects()
    danger.Visible = true
    local dangerTime = player:WaitForChild("DangerTime",9e9)
    dangerTime.Changed:Connect(function()
        updateTimer()
        updateTimerDisplay()
    end)
    updateTimer()
end

initialize()

