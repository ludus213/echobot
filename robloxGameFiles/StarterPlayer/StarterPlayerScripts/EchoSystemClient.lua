local EchoSystemClient = {}
EchoSystemClient.__index = EchoSystemClient


local chargeEcho = game.ReplicatedStorage.Requests.ChargeEcho
local UIS = game:GetService("UserInputService")

function EchoSystemClient.new()
    local self = setmetatable({}, EchoSystemClient)
    self:init()
    return self
end

function EchoSystemClient:init()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local Remote = ReplicatedStorage.Requests:WaitForChild("Notify")
    Remote.OnClientEvent:Connect(function()
        self:showNotification()
    end)
end

function EchoSystemClient:showNotification()
    local StarterGui = game:GetService("StarterGui")
    local player = game:GetService("Players").LocalPlayer
    local screenGui = Instance.new("ScreenGui")
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Font = Enum.Font.Garamond
    textLabel.Text = ""
    textLabel.TextSize = 36
    textLabel.AnchorPoint = Vector2.new(0.5, 0)
    textLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
    textLabel.Size = UDim2.new(0, 400, 0, 50)
    textLabel.Parent = screenGui
    local fullText = "Echo Potential increased"
    for i = 1, #fullText do
        textLabel.Text = string.sub(fullText, 1, i)
        task.wait(0.04)
    end
    task.wait(1.5)
    local tweenService = game:GetService("TweenService")
    local tween = tweenService:Create(textLabel, TweenInfo.new(1), {TextTransparency = 1})
    tween:Play()
    tween.Completed:Wait()
    screenGui:Destroy()
end

local inputKey = Enum.KeyCode.G
local charging = false

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == inputKey and not charging then
		charging = true
		task.spawn(function()
			while charging do
				chargeEcho:FireServer()
				task.wait(0.1)
			end
		end)
	end
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == inputKey then
		charging = false
	end
end)


return EchoSystemClient 