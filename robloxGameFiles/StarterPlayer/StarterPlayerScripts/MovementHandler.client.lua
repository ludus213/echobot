local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local moveanims = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("MoveAnims")
local RUN_ANIMATION = moveanims:WaitForChild("Run")
local DASH_ANIMATIONS = {
	Left = moveanims:WaitForChild("LDash"),
	Right = moveanims:WaitForChild("RDash"),
	Back = moveanims:WaitForChild("BDash"),
	Front = moveanims:WaitForChild("FDash"),
}
type CharacterR6 = Model & {
	Humanoid: Humanoid & {
		Animator: Animator?
	},
	HumanoidRootPart: BasePart,
	Head: BasePart,
	Torso: BasePart,
	LeftArm: BasePart,
	RightArm: BasePart,
	LeftLeg: BasePart,
	RightLeg: BasePart,
}
local playerTracks = {}

local function playAnimation(character, animObj, looped)
	if not character or not animObj then return end
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end

	local track = animator:LoadAnimation(animObj)
	track.Looped = looped or false
	track:Play()
	return track
end

local function setupMovementHandler(character : CharacterR6)
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local MovementRemote = ReplicatedStorage.Requests:WaitForChild("MovementRemote")
	local DropItemRemote = ReplicatedStorage.Requests:WaitForChild("DropItem")
	local lastW, runActive, dashDebounce = 0, false, false
	local isblocking = false
	if character == player.Character then
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.KeyCode == Enum.KeyCode.F then 
				isblocking = true
			end
			if input.KeyCode == Enum.KeyCode.W then
				local now = tick()
				if now - lastW < 0.25 and not runActive and not isblocking then
					runActive = true
					MovementRemote:FireServer("Run", true)
				end
				lastW = now
			elseif input.KeyCode == Enum.KeyCode.Q and not dashDebounce then
				dashDebounce = true
				if runActive then
					runActive = false
					MovementRemote:FireServer("Run", false)
				end
				local dir = "Back"
				local moveDir = humanoid.MoveDirection
				if moveDir.Magnitude > 0 then
					local localMove = root.CFrame:VectorToObjectSpace(moveDir)
					if math.abs(localMove.X) > math.abs(localMove.Z) then
						dir = localMove.X > 0 and "Right" or "Left"
					else
						dir = localMove.Z > 0 and "Back" or "Front"
					end
				end
				MovementRemote:FireServer("Dash", dir)
				task.delay(0.5, function()
					dashDebounce = false
				end)
			elseif input.KeyCode == Enum.KeyCode.Backspace then
				local tool = character:FindFirstChildOfClass("Tool")
				if tool and not tool:FindFirstChild("Undroppable") then
					DropItemRemote:FireServer(tool.Name)
				end
			end
			local root = character:FindFirstChild("HumanoidRootPart")
			character.HumanoidRootPart.ChildAdded:Connect(function(child: Instance) 
				if child.ClassName == "BodyVelocity" then
					while child do
						if	child.Name == "Left" then child.Velocity = -root.CFrame.RightVector * 80 
						elseif child.Name == "Right" then child.Velocity = root.CFrame.RightVector * 80 
						elseif child.Name == "Back" then child.Velocity = -root.CFrame.LookVector * 80 
						elseif child.Name == "Front" then child.Velocity = root.CFrame.LookVector * 80 
						end
						if child.Parent == nil then 
							break
						end
						wait()
					end
				end
			end)
		end)

		UserInputService.InputEnded:Connect(function(input, processed)
			if input.KeyCode == Enum.KeyCode.W and runActive then
				runActive = false
				MovementRemote:FireServer("Run", false)
			end
			if input.KeyCode == Enum.KeyCode.F then
				isblocking = false
			end
		end)
	end
end

local MovementRemote = ReplicatedStorage.Requests:WaitForChild("MovementRemote")
MovementRemote.OnClientEvent:Connect(function(action, targetPlayer, dir)
	if not targetPlayer or not targetPlayer.Character then return end
	local character = targetPlayer.Character

	if action == "RunAnim" then
		if playerTracks[targetPlayer] and playerTracks[targetPlayer].run then
			playerTracks[targetPlayer].run:Stop()
		end
		if not playerTracks[targetPlayer] then
			playerTracks[targetPlayer] = {}
		end
		playerTracks[targetPlayer].run = playAnimation(character, RUN_ANIMATION, true)
	elseif action == "StopRun" then
		if playerTracks[targetPlayer] and playerTracks[targetPlayer].run then
			playerTracks[targetPlayer].run:Stop()
			playerTracks[targetPlayer].run = nil
		end
	elseif action == "DashAnim" and DASH_ANIMATIONS[dir] then
		playAnimation(character, DASH_ANIMATIONS[dir], false)
	end
end)

if player.Character then setupMovementHandler(player.Character) end
player.CharacterAdded:Connect(setupMovementHandler)

Players.PlayerRemoving:Connect(function(removedPlayer)
	playerTracks[removedPlayer] = nil
end)