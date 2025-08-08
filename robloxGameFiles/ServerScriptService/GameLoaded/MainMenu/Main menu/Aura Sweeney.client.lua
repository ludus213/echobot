local buttonsFrame = script.Parent:WaitForChild("Buttons")
local selection = script.Parent:WaitForChild("Selection")
local background = script.Parent.Parent:WaitForChild("Background")

local tweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local buttonNames = {"Play", "Credits"}
local originalSizes = {}
local sliderPositions = {
	Credits = UDim2.new(0.5, 0 ,0.597, 0),
	Play = UDim2.new(0.5, 0, 0.525, 0),
}


for _, name in ipairs(buttonNames) do
	local button = buttonsFrame:WaitForChild(name)
	originalSizes[button] = button.Size

	button.MouseEnter:Connect(function()
		local originalSize = originalSizes[button]
		tweenService:Create(button, tweenInfo, {
			Size = originalSize + UDim2.new(0.025, 0, 0.025, 0)
		}):Play()
		tweenService:Create(selection, tweenInfo, {
			Position = sliderPositions[name]
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		tweenService:Create(button, tweenInfo, {
			Size = originalSizes[button]
		}):Play()
	end)
end


local originalBackgroundSize = background.Size
task.spawn(function()
	while true do
		local grow = tweenService:Create(background, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Size = originalBackgroundSize + UDim2.new(0.02, 0, 0.02, 0)
		})
		local shrink = tweenService:Create(background, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			Size = originalBackgroundSize
		})

		grow:Play()
		grow.Completed:Wait()
		shrink:Play()
		shrink.Completed:Wait()
		wait(2)
	end
end)

local TweenService = game:GetService("TweenService")
local StarGui = script.Parent.Parent.Background
local Star = game.ReplicatedStorage.UI.Star
local MIN_SCALE = 0.14
local MAX_SCALE = 0.2
local SPAWN_INTERVAL = {0.5, 1}
local TWEEN_DURATION = 3
local VIEWPORT_SIZE = StarGui.AbsoluteSize
local tweenInfo = TweenInfo.new(
	TWEEN_DURATION,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.Out,
	0,
	false,
	0
)
local function spawnStar()
	local starClone = Star:Clone()
	starClone.Parent = StarGui
	local scaleFactor = math.random(MIN_SCALE * 100, MAX_SCALE * 100) / 100
	starClone.Size = UDim2.new(0, Star.Size.X.Offset * scaleFactor, 0, Star.Size.Y.Offset * scaleFactor)
	local randomX = math.random()
	starClone.Position = UDim2.new(randomX, -starClone.Size.X.Offset / 2, 0, -starClone.Size.Y.Offset)
	starClone.ImageTransparency = 0.3
	local glowTween = TweenService:Create(starClone, TweenInfo.new(
		1.5,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1,
		true
		), {ImageTransparency = 0.6})
	local rotationTween = TweenService:Create(starClone, tweenInfo, {
		Rotation = math.random(90, 180)
	})

	local positionTween = TweenService:Create(starClone, tweenInfo, {
		Position = UDim2.new(randomX, -starClone.Size.X.Offset / 2, 1, 0)
	})
	glowTween:Play()
	rotationTween:Play()
	positionTween:Play()
	positionTween.Completed:Connect(function()
		starClone:Destroy()
	end)
end
local star = task.spawn(function()
	while true do
		spawnStar()
		task.wait(math.random(SPAWN_INTERVAL[1], SPAWN_INTERVAL[2]))
	end
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local menuRemote = ReplicatedStorage.Requests:WaitForChild("menu")
local player = game.Players.LocalPlayer

local playButton = script.Parent:WaitForChild("Buttons"):WaitForChild("Play")
playButton.MouseButton1Click:Connect(function()
	print("[CLIENT] Play button pressed")
	task.cancel(star)
	game.SoundService["Lunar Tide"]:Stop()
	print("[CLIENT] firing menuRemote:FireServer('play')")
	menuRemote:FireServer("play")
	for i,v in script.Parent.Parent:GetChildren() do
		if v:IsA("ImageLabel") or v:IsA("ImageButton") then
			local transparency = TweenService:Create(v,TweenInfo.new(1.2,Enum.EasingStyle.Sine), { ImageTransparency = 1 })
			transparency:Play()
			transparency.Completed:Connect(function(playbackState: Enum.PlaybackState) 
				script.Parent.Parent:Destroy()
			end)
		end
	end
end)