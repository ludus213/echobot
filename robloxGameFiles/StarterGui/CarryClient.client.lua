local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local carryRemote = ReplicatedStorage.Requests:WaitForChild("CarryPlayer")
local gripRemote = ReplicatedStorage.Requests:WaitForChild("GripPlayer")

local function canPerformAction()
	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	if humanoid.WalkSpeed == 0 then
		return false
	end
	if character:FindFirstChild("Knocked") then
		return false
	end
	if character:FindFirstChild("Grabbed") then
		return false
	end

	return true
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.V and canPerformAction() then
		carryRemote:FireServer()
	elseif input.KeyCode == Enum.KeyCode.B and canPerformAction() then
		gripRemote:FireServer()
	end
end)
