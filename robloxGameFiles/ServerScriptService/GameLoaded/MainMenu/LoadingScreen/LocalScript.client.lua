--[[game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)]]

local tweenService = game:GetService("TweenService")
local gameName1 = script.Parent:WaitForChild("GameName1")
local buttons = script.Parent.Parent:WaitForChild("Main menu"):WaitForChild("Buttons"):GetChildren()
local wheel = script.Parent:WaitForChild("Wheel")
local slider = script.Parent.Parent["Main menu"].Selection
local rotationSpeed = 360
local targetPosition = UDim2.new(0.5, 0, 0.282, 0)
local fadeInTransparency = 0
local fadeOutTransparency = 1
local tweenInfo = TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweensigma = TweenInfo.new(0.7)
local fadeSoundInfo = TweenInfo.new(3, Enum.EasingStyle.Linear)

local player = game.Players.LocalPlayer
local character = player.Character

local gameNameTween = tweenService:Create(gameName1, tweenInfo, {
	Position = targetPosition
})

local wheelFadeOutTween = tweenService:Create(wheel, tweensigma, {
	ImageTransparency = fadeOutTransparency
})

local sliderFadeInTween = tweenService:Create(slider, tweensigma, {
	ImageTransparency = fadeInTransparency
})

local function rotateWheel(duration)
	task.spawn(function()
		local startTime = tick()
		while tick() - startTime < duration do
			wheel.Rotation = (wheel.Rotation + rotationSpeed * (1/60)) % 360
			task.wait(1/60)
		end
	end)
end

rotateWheel(8)
task.wait(5)

gameNameTween:Play()

local sound = game.SoundService:FindFirstChild("Lunar Tide")
if sound then
	sound.Volume = 0
	sound:Play()
	tweenService:Create(sound, fadeSoundInfo, { Volume = 1 }):Play()
end

wheelFadeOutTween:Play()
wheelFadeOutTween.Completed:Wait()
sliderFadeInTween:Play()

for _, v in pairs(buttons) do
	if typeof(v) == "boolean" then continue end
	if v:IsA("TextButton") then
		local buttonsFadeInTween = tweenService:Create(v, tweenInfo, {
			TextTransparency = fadeInTransparency
		})
		buttonsFadeInTween:Play()
	end
end
