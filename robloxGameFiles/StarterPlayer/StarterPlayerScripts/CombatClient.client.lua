local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

local combatAttackRemote = ReplicatedStorage:FindFirstChild("Requests"):FindFirstChild("CombatAttack")
local combatBlockRemote = ReplicatedStorage:FindFirstChild("Requests"):FindFirstChild("CombatBlock")
local perfectBlockEffectRemote = ReplicatedStorage:FindFirstChild("Requests"):FindFirstChild("PerfectBlockEffect")

local isBlocking = false
local perfectBlockGreyscale = nil

local function createGreyscaleEffect()
	if perfectBlockGreyscale then return end
	
	perfectBlockGreyscale = Instance.new("ColorCorrectionEffect")
	perfectBlockGreyscale.Name = "PerfectBlockGreyscale"
	perfectBlockGreyscale.Saturation = -1
	perfectBlockGreyscale.Contrast = 0.2
	perfectBlockGreyscale.Parent = Lighting
end

local function removeGreyscaleEffect()
	if perfectBlockGreyscale then
		perfectBlockGreyscale:Destroy()
		perfectBlockGreyscale = nil
	end
end

local function onPerfectBlockEffect()
	createGreyscaleEffect()
	
	task.spawn(function()
		task.wait(1.5)
		removeGreyscaleEffect()
	end)
end

local function canPerformAction()
	if not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") then
		return false
	end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not humanoidRootPart then
		return false
	end
	
	if humanoid.Health <= 0 then
		return false
	end
	
	return true
end

local function handleM1()
	print('handle m1 recieved')
	if not canPerformAction() then return end
	print('could perform action')
	combatAttackRemote:FireServer("M1", 1, false)
end

local function handleCrit()
	if not canPerformAction() then return end
	combatAttackRemote:FireServer("Crit", 1, false)
end

local function startBlock()
	if not canPerformAction() then return end
	if isBlocking then return end
	
	isBlocking = true
	combatBlockRemote:FireServer(true)
end

local function endBlock()
	if not isBlocking then return end
	
	isBlocking = false
	combatBlockRemote:FireServer(false)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		handleM1()
	elseif input.KeyCode == Enum.KeyCode.R then
		handleCrit()
	elseif input.KeyCode == Enum.KeyCode.F then
		startBlock()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.F then
		endBlock()
	end
end)

perfectBlockEffectRemote.OnClientEvent:Connect(onPerfectBlockEffect)

player.CharacterAdded:Connect(function()
	isBlocking = false
	removeGreyscaleEffect()
end)
