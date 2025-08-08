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

local module = {}
local PlayerData = game.ServerScriptService.PlayerData
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local StateManager = require(script.Parent.StateManager)

local Ragdoll_Constraints = script:WaitForChild("Ragdoll_Constraints")
game:GetService("PhysicsService"):RegisterCollisionGroup("Bones")
game:GetService("PhysicsService"):RegisterCollisionGroup("Self")
game:GetService("PhysicsService"):CollisionGroupSetCollidable("Bones", "Self", false)
game:GetService("PhysicsService"):CollisionGroupSetCollidable("Self", "Self", false)
local knockedPlayers = {}
local carryingPlayers = {}
local carriedPlayers = {}
local grippingPlayers = {}
local grippedPlayers = {}
local lastDropTimes = {}

local carryRemote = ReplicatedStorage.Requests:FindFirstChild("CarryPlayer")

local gripRemote = ReplicatedStorage.Requests:FindFirstChild("GripPlayer")

local Socket_Neck = Instance.new("BallSocketConstraint")
Socket_Neck.Name = "SocketNeck"
Socket_Neck.LimitsEnabled = true
Socket_Neck.Restitution = 0
Socket_Neck.TwistLimitsEnabled = true
Socket_Neck.UpperAngle = 60
Socket_Neck.TwistLowerAngle = -40
Socket_Neck.TwistUpperAngle = 40
Socket_Neck.Parent = Ragdoll_Constraints

local Socket_LeftHip = Instance.new("BallSocketConstraint")
Socket_LeftHip.Name = "SocketLeft Hip"
Socket_LeftHip.LimitsEnabled = true
Socket_LeftHip.Restitution = 0
Socket_LeftHip.TwistLimitsEnabled = true
Socket_LeftHip.UpperAngle = 70
Socket_LeftHip.TwistLowerAngle = -5
Socket_LeftHip.TwistUpperAngle = 80
Socket_LeftHip.Parent = Ragdoll_Constraints

local Socket_LeftShoulder = Instance.new("BallSocketConstraint")
Socket_LeftShoulder.Name = "SocketLeft Shoulder"
Socket_LeftShoulder.LimitsEnabled = true
Socket_LeftShoulder.Restitution = 0
Socket_LeftShoulder.TwistLimitsEnabled = true
Socket_LeftShoulder.UpperAngle = 140
Socket_LeftShoulder.TwistLowerAngle = -85
Socket_LeftShoulder.TwistUpperAngle = 80
Socket_LeftShoulder.Parent = Ragdoll_Constraints

local Socket_RightHip = Instance.new("BallSocketConstraint")
Socket_RightHip.Name = "SocketRight Hip"
Socket_RightHip.LimitsEnabled = true
Socket_RightHip.Restitution = 0
Socket_RightHip.TwistLimitsEnabled = true
Socket_RightHip.UpperAngle = 70
Socket_RightHip.TwistLowerAngle = -5
Socket_RightHip.TwistUpperAngle = 80
Socket_RightHip.Parent = Ragdoll_Constraints

local Socket_RightShoulder = Instance.new("BallSocketConstraint")
Socket_RightShoulder.Name = "SocketRight Shoulder"
Socket_RightShoulder.LimitsEnabled = true
Socket_RightShoulder.Restitution = 0
Socket_RightShoulder.TwistLimitsEnabled = true
Socket_RightShoulder.UpperAngle = 140
Socket_RightShoulder.TwistLowerAngle = -85
Socket_RightShoulder.TwistUpperAngle = 80
Socket_RightShoulder.Parent = Ragdoll_Constraints

local Create = {
	Neck = function(Character)
		if not Character:FindFirstChild("Torso") then
			return
		end
		if not Character.Torso:FindFirstChild("Neck") then
			return
		end
		if not Character:FindFirstChild("Head") then
			return
		end

		Character.Torso.Neck.Part0 = nil
		local TorsoAttach = Instance.new("Attachment")
		TorsoAttach.Name = "RagdollAttach"
		TorsoAttach.Position = Vector3.new(0, 1, 0)
		TorsoAttach.Orientation = Vector3.new(-90, -180, 0)
		TorsoAttach.Parent = Character.Torso
		local RagdollAttach = Instance.new("Attachment")
		RagdollAttach.Name = "RagdollAttach"
		RagdollAttach.Position = Vector3.new(0, -0.5, 0)
		RagdollAttach.Orientation = Vector3.new(-90, -180, 0)
		RagdollAttach.Parent = Character.Head
		local Constraint = Socket_Neck:Clone()
		Constraint.Attachment0 = TorsoAttach
		Constraint.Attachment1 = RagdollAttach
		Constraint.Parent = Character.Torso
	end,
	["Left Hip"] = function(Character)
		if not Character:FindFirstChild("Torso") then
			return
		end
		if not Character.Torso:FindFirstChild("Left Hip") then
			return
		end
		if not Character:FindFirstChild("Left Leg") then
			return
		end

		Character.Torso["Left Hip"].Part0 = nil
		local TorsoAttach = Instance.new("Attachment")
		TorsoAttach.Name = "RagdollAttach"
		TorsoAttach.Position = Vector3.new(-1, -1, 0)
		TorsoAttach.Orientation = Vector3.new(0, -90, 0)
		TorsoAttach.Parent = Character.Torso
		local RagdollAttach = Instance.new("Attachment")
		RagdollAttach.Name = "RagdollAttach"
		RagdollAttach.Position = Vector3.new(-0.5, 1, 0)
		RagdollAttach.Orientation = Vector3.new(0, -90, 0)
		RagdollAttach.Parent = Character["Left Leg"]
		local Constraint = Socket_LeftHip:Clone()
		Constraint.Attachment0 = TorsoAttach
		Constraint.Attachment1 = RagdollAttach
		Constraint.Parent = Character.Torso
	end,
	["Left Shoulder"] = function(Character)
		if not Character:FindFirstChild("Torso") then
			return
		end
		if not Character.Torso:FindFirstChild("Left Shoulder") then
			return
		end
		if not Character:FindFirstChild("Left Arm") then
			return
		end

		Character.Torso["Left Shoulder"].Part0 = nil
		local TorsoAttach = Instance.new("Attachment")
		TorsoAttach.Name = "RagdollAttach"
		TorsoAttach.Position = Vector3.new(-1, 0.5, 0)
		TorsoAttach.Orientation = Vector3.new(0, -90, 0)
		TorsoAttach.Parent = Character.Torso
		local RagdollAttach = Instance.new("Attachment")
		RagdollAttach.Name = "RagdollAttach"
		RagdollAttach.Position = Vector3.new(0.5, 0.5, 0)
		RagdollAttach.Orientation = Vector3.new(0, -90, 0)
		RagdollAttach.Parent = Character["Left Arm"]
		local Constraint = Socket_LeftShoulder:Clone()
		Constraint.Attachment0 = TorsoAttach
		Constraint.Attachment1 = RagdollAttach
		Constraint.Parent = Character.Torso
	end,
	["Right Hip"] = function(Character)
		if not Character:FindFirstChild("Torso") then
			return
		end
		if not Character.Torso:FindFirstChild("Right Hip") then
			return
		end
		if not Character:FindFirstChild("Right Leg") then
			return
		end

		Character.Torso["Right Hip"].Part0 = nil
		local TorsoAttach = Instance.new("Attachment")
		TorsoAttach.Name = "RagdollAttach"
		TorsoAttach.Position = Vector3.new(1, -1, 0)
		TorsoAttach.Orientation = Vector3.new(0, 90, 0)
		TorsoAttach.Parent = Character.Torso
		local RagdollAttach = Instance.new("Attachment")
		RagdollAttach.Name = "RagdollAttach"
		RagdollAttach.Position = Vector3.new(0.5, 1, 0)
		RagdollAttach.Orientation = Vector3.new(0, 90, 0)
		RagdollAttach.Parent = Character["Right Leg"]
		local Constraint = Socket_RightHip:Clone()
		Constraint.Attachment0 = TorsoAttach
		Constraint.Attachment1 = RagdollAttach
		Constraint.Parent = Character.Torso
	end,
	["Right Shoulder"] = function(Character)
		if not Character:FindFirstChild("Torso") then
			return
		end
		if not Character.Torso:FindFirstChild("Right Shoulder") then
			return
		end
		if not Character:FindFirstChild("Right Arm") then
			return
		end

		Character.Torso["Right Shoulder"].Part0 = nil
		local TorsoAttach = Instance.new("Attachment")
		TorsoAttach.Name = "RagdollAttach"
		TorsoAttach.Position = Vector3.new(1, 0.5, 0)
		TorsoAttach.Orientation = Vector3.new(0, 90, 0)
		TorsoAttach.Parent = Character.Torso
		local RagdollAttach = Instance.new("Attachment")
		RagdollAttach.Name = "RagdollAttach"
		RagdollAttach.Position = Vector3.new(-0.5, 0.5, 0)
		RagdollAttach.Orientation = Vector3.new(0, 90, 0)
		RagdollAttach.Parent = Character["Right Arm"]
		local Constraint = Socket_RightShoulder:Clone()
		Constraint.Attachment0 = TorsoAttach
		Constraint.Attachment1 = RagdollAttach
		Constraint.Parent = Character.Torso
	end,
}
local whitelist = {
	"Left Arm",
	"Right Arm",
	"Head",
	"Right Leg",
	"Left Leg",
	"Torso",
	"HumanoidRootPart",
}
local function clampHealth(humanoid, damage)
	if humanoid.Health - damage <= 0 then
		humanoid.Health = 5
		return true
	end
	return false
end

local function resetKnockedTimer(player)
	if knockedPlayers[player] then
		knockedPlayers[player].timeLeft = 20
	end
end

local function createKnockedFolder(character)
	local knockedFolder = character:FindFirstChild("Knocked")
	if not knockedFolder then
		knockedFolder = Instance.new("Folder")
		knockedFolder.Name = "Knocked"
		knockedFolder.Parent = character
	end
	return knockedFolder
end

local function removeKnockedFolder(character)
	local knockedFolder = character:FindFirstChild("Knocked")
	if knockedFolder then
		CollectionService:AddTag(knockedFolder, "Removing")
		task.wait(0.1)
		if knockedFolder and knockedFolder.Parent then
			knockedFolder:Destroy()
		end
	end
end

local function stopCarrying(carrier, shouldThrow)
	local carried = carryingPlayers[carrier]
	if not carried then
		return
	end

	carryingPlayers[carrier] = nil
	carriedPlayers[carried] = nil
	lastDropTimes[carrier] = os.clock()

	StateManager.RemoveState(carrier, "carrying")
	StateManager.RemoveState(carried, "carried")

	local carrierCharacter = carrier.Character
	local carriedCharacter = carried.Character

	if carrierCharacter then
		local carrierHumanoid = carrierCharacter:FindFirstChildOfClass("Humanoid")
		if carrierHumanoid then
			for _, track in pairs(carrierHumanoid:GetPlayingAnimationTracks()) do
				if track.Animation.Name == "Carry" or track.Animation.Name == "PickUp" then
					track:Stop()
				end
			end

			if shouldThrow then
				local throwAnim = carrierHumanoid:LoadAnimation(ReplicatedStorage.Animations.StateAnimations.Throw)
				throwAnim.Looped = false
				throwAnim:Play()
			end
		end
	end

	if carriedCharacter then
		local carriedHumanoid = carriedCharacter:FindFirstChildOfClass("Humanoid")
		if carriedHumanoid then
			for _, track in pairs(carriedHumanoid:GetPlayingAnimationTracks()) do
				if track.Animation.Name == "Carried" then
					track:Stop()
				end
			end
		end

		for _, part in pairs(carriedCharacter:GetChildren()) do
			if part:IsA("BasePart") and table.find(whitelist, part.Name) then
				part.CanCollide = true
			end
		end

		local carriedTorso = carriedCharacter:FindFirstChild("Torso")
		if carriedTorso then
			for _, obj in pairs(carriedTorso:GetChildren()) do
				if obj.Name == "CarryWeld" or obj:IsA("WeldConstraint") then
					obj:Destroy()
				end
			end

			for _, obj in pairs(carrierCharacter:GetDescendants()) do
				if obj.Name == "CarryWeld" or (obj:IsA("WeldConstraint") and obj.Part1 == carriedTorso) then
					obj:Destroy()
				end
			end

			local grabbed = carriedCharacter:FindFirstChild("Grabbed")
			if grabbed then
				grabbed:Destroy()
			end

			carriedTorso:SetNetworkOwner(nil)

			if shouldThrow and carrierCharacter then
				local carrierTorso = carrierCharacter:FindFirstChild("Torso")
				if carrierTorso then
					local throwDirection = carrierTorso.CFrame.LookVector
					local throwForce = throwDirection * 50 + Vector3.new(0, 10, 0)
					task.wait(0.1)
					carriedTorso.AssemblyLinearVelocity = throwForce
				end
			end
		end

		if knockedPlayers[carried] then
			module.Ragdoll(carriedCharacter, true)
			resetKnockedTimer(carried)
		end
	end
end

local function stopGripping(gripper, shouldGetUp)
	local gripped = grippingPlayers[gripper]
	if not gripped then
		return
	end

	grippingPlayers[gripper] = nil
	grippedPlayers[gripped] = nil

	StateManager.RemoveState(gripper, "Gripping")
	StateManager.RemoveState(gripped, "Gripped")

	local gripperCharacter : CharacterR6 = gripper.Character
	local grippedCharacter : CharacterR6 = gripped.Character

	if gripperCharacter then
		local gripperHumanoid : Humanoid = gripperCharacter:FindFirstChildOfClass("Humanoid")
		if gripperHumanoid then
			for _, track in pairs(gripperHumanoid.Animator:GetPlayingAnimationTracks()) do
				if track.Animation.Name:find("Grip") then
					track:Stop()
				end
			end
		end
		gripperCharacter.Torso.Anchored = false
		local gripweld : Weld = gripperCharacter.GripWeld
		if gripweld  then
			gripweld:Destroy()
		end
	end

	if grippedCharacter then
		local grippedHumanoid = grippedCharacter:FindFirstChildOfClass("Humanoid")
		if grippedHumanoid then
			for _, track in pairs(grippedHumanoid.Animator:GetPlayingAnimationTracks()) do
				if track.Animation.Name == "Gripped" then
					track:Stop()
				end
			end
		end
		grippedCharacter.Torso.Anchored = false

		if shouldGetUp then
			module.setKnockedState(grippedCharacter, false)
		elseif knockedPlayers[gripped] then
			module.Ragdoll(grippedCharacter, true)
			resetKnockedTimer(gripped)
		end
	end
end

function module.setKnockedState(character, knocked)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	if knocked then
		StateManager.AddState(player, "knocked")
		StateManager.AddState(player, "ragdolled")
		StateManager.AddState(player, "Stunned")
		knockedPlayers[player] = {
			timeLeft = 20,
			character = character,
		}

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
				track:Stop()
			end
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
		end

		if carryingPlayers[player] then
			stopCarrying(player, false)
		end

		if grippingPlayers[player] then
			stopGripping(player, false)
		end

		createKnockedFolder(character)
		module.Ragdoll(character, true)
	else
		StateManager.RemoveState(player, "knocked")
		StateManager.RemoveState(player, "ragdolled")
		StateManager.AddState(player, "Stunned")
		knockedPlayers[player] = nil

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and not carriedPlayers[player] and not grippedPlayers[player] then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.JumpHeight = 7.2
		end
		removeKnockedFolder(character)
		module.Ragdoll(character, false)
	end
end

local function updateKnockedTimer()
	for player, data in pairs(knockedPlayers) do
		if data.timeLeft > 0 then
			data.timeLeft = data.timeLeft - 1
			if data.timeLeft <= 0 then
				module.setKnockedState(data.character, false)
			end
		end
	end
end

local function isPlayerNearKnocked(carrier, knocked)
	local carrierCharacter = carrier.Character
	local knockedCharacter = knocked.Character

	if not carrierCharacter or not knockedCharacter then
		return false
	end

	local carrierParts = {
		carrierCharacter:FindFirstChild("HumanoidRootPart"),
	}

	local knockedParts = {
		knockedCharacter:FindFirstChild("Head"),
		knockedCharacter:FindFirstChild("Torso"),
		knockedCharacter:FindFirstChild("Left Arm"),
		knockedCharacter:FindFirstChild("Right Arm"),
		knockedCharacter:FindFirstChild("Left Leg"),
		knockedCharacter:FindFirstChild("Right Leg"),
	}

	for _, carrierPart in pairs(carrierParts) do
		if carrierPart then
			for _, knockedPart in pairs(knockedParts) do
				if knockedPart then
					local distance = (carrierPart.Position - knockedPart.Position).Magnitude
					if distance <= 6 then
						return true
					end
				end
			end
		end
	end

	return false
end

local function startCarrying(carrier : Player, carried : Player)
	local carrierCharacter = carrier.Character
	local carriedCharacter = carried.Character

	if not carrierCharacter or not carriedCharacter then
		return
	end
	if carryingPlayers[carrier] or carriedPlayers[carried] then
		return
	end

	carryingPlayers[carrier] = carried
	carriedPlayers[carried] = carrier

	StateManager.AddState(carrier, "carrying")
	StateManager.AddState(carried, "carried")

	local carrierHumanoid = carrierCharacter:FindFirstChildOfClass("Humanoid")
	local carriedHumanoid = carriedCharacter:FindFirstChildOfClass("Humanoid")

	if carrierHumanoid then
		local carrierAnimator = carrierHumanoid:FindFirstChildOfClass("Animator")
		local pickUpAnim = carrierAnimator:LoadAnimation(ReplicatedStorage.Animations.StateAnimations.PickUp)
		pickUpAnim.Looped = false
		pickUpAnim:Play()

		pickUpAnim.Ended:Connect(function()
			if carryingPlayers[carrier] == carried then
				local animator = carrierHumanoid:FindFirstChildOfClass("Animator")
				local carryAnim = carrierAnimator:LoadAnimation(ReplicatedStorage.Animations.StateAnimations.Carry)
				carryAnim.Looped = true
				carryAnim:Play()
			end
		end)
	end

	if carriedHumanoid then
		carriedHumanoid.WalkSpeed = 0
		carriedHumanoid.JumpPower = 0
		carriedHumanoid.JumpHeight = 0
		local animator = carriedHumanoid:FindFirstChildOfClass("Animator")
		local carriedAnim = animator:LoadAnimation(ReplicatedStorage.Animations.StateAnimations.Carried)
		carriedAnim.Looped = true
		carriedAnim:Play()
	end

	module.Ragdoll(carriedCharacter, false, carrier)

	for _, part in pairs(carriedCharacter:GetChildren()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

	local carriedTorso = carriedCharacter:FindFirstChild("Torso")
	local carrierTorso = carrierCharacter:FindFirstChild("Torso")

	if carriedTorso and carrierTorso then
		local grabbed = Instance.new("ObjectValue")
		grabbed.Name = "Grabbed"
		grabbed.Value = carrierCharacter
		grabbed.Parent = carriedCharacter

		carriedTorso.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		carriedTorso.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

		local offsetCFrame = carrierTorso.CFrame + Vector3.new(3,2.25,0.2)
		carriedCharacter.WorldPivot = carrierCharacter.WorldPivot
		carriedTorso.CFrame = offsetCFrame
		carriedTorso:SetNetworkOwner(carrier)

		local Weld = Instance.new('Weld', carrierCharacter)
		Weld.Name = 'CarryWeld'
		Weld.Part0 = carrierCharacter.Torso
		Weld.Part1 = carriedCharacter.Torso
		Weld.C0 = CFrame.new(2, 1, 0)
		for _, track in carriedCharacter.Humanoid.Animator:GetPlayingAnimationTracks() do 
			if track.Name ~= "Carried" then
				track:Stop()
			end
		end
	end

	resetKnockedTimer(carried)
end

carryRemote.OnServerEvent:Connect(function(player)
	if carryingPlayers[player] then
		stopCarrying(player, true)
		return
	end

	local lastDropTime = lastDropTimes[player] or 0
	if os.clock() - lastDropTime < 0.5 then
		return 
	end

	for knockedPlayer, _ in pairs(knockedPlayers) do
		if isPlayerNearKnocked(player, knockedPlayer) then
			startCarrying(player, knockedPlayer)
			break
		end
	end
end)

local function grip(gripper : CharacterR6, gripped : CharacterR6, cancel : boolean)
	local weaponinfo = require(game.ServerScriptService.Modules.weaponInfo)
	local gripperPlayer = Players:GetPlayerFromCharacter(gripper)
	local grippedPlayer = Players:GetPlayerFromCharacter(gripped)

	if not gripperPlayer or not grippedPlayer then
		return
	end

	resetKnockedTimer(grippedPlayer)

	local heldTool = gripper:FindFirstChildOfClass("Tool")
	if not heldTool then
		return
	end

	local weapon = weaponinfo[tostring(heldTool)]
	if not weapon or not weapon.gripAnimation then
		return
	end

	local grippedAnimation = ReplicatedStorage.Animations.StateAnimations.Gripped
	local gripAnimation : Animation = weapon.gripAnimation

	if cancel then
		StateManager.RemoveState(gripperPlayer, "Gripping")
		StateManager.RemoveState(grippedPlayer, "Gripped")

		gripper.Torso.Anchored = false
		gripped.Torso.Anchored = false

		local gripperHumanoid : Humanoid = gripper:FindFirstChildOfClass("Humanoid")
		local grippedHumanoid : Humanoid = gripped:FindFirstChildOfClass("Humanoid")

		if gripperHumanoid then
			for _, track in pairs(gripperHumanoid.Animator:GetPlayingAnimationTracks()) do
				if track.Animation.Name:find("Grip") then
					track:Stop()
				end
			end
		end

		if grippedHumanoid then
			for _, track in pairs(grippedHumanoid.Animator:GetPlayingAnimationTracks()) do
				if track.Animation.Name == "Gripped" then
					track:Stop()
				end
			end
		end

		grippingPlayers[gripperPlayer] = nil
		grippedPlayers[grippedPlayer] = nil

		if knockedPlayers[grippedPlayer] then
			module.Ragdoll(gripped, true)
		end
	else
		if grippingPlayers[gripperPlayer] or grippedPlayers[grippedPlayer] then
			return
		end

		grippingPlayers[gripperPlayer] = grippedPlayer
		grippedPlayers[grippedPlayer] = gripperPlayer

		StateManager.AddState(gripperPlayer, "Gripping")
		StateManager.AddState(grippedPlayer, "Gripped")

		module.Ragdoll(gripped, false)

		local gripperHumanoid : Humanoid = gripper:FindFirstChildOfClass("Humanoid")
		local grippedHumanoid : Humanoid = gripped:FindFirstChildOfClass("Humanoid")

		local Params = RaycastParams.new()
		Params.FilterType = Enum.RaycastFilterType.Exclude
		Params.FilterDescendantsInstances = { gripper, gripped }
		Params.IgnoreWater = true
		local FloorResult : RaycastResult = workspace:Raycast(gripped.HumanoidRootPart.Position+Vector3.new(0,2,0), Vector3.new(0, -8, 0), Params)

		if FloorResult then
			local TP = gripped.HumanoidRootPart.Position
			local X, Y, Z = gripped.HumanoidRootPart.CFrame:ToOrientation()
		end

		local Weld : Weld = Instance.new('Weld', gripper)
		Weld.Name = 'GripWeld'
		Weld.Part0 = gripper.HumanoidRootPart
		Weld.Part1 = gripped.HumanoidRootPart
		Weld.C0 = CFrame.new(0, 0, -2.75) * CFrame.Angles(0, math.pi, 0)

		gripper.Humanoid.AutoRotate = true
		gripper.HumanoidRootPart.Anchored = true

		if gripperHumanoid then
			local animator : Animator = gripperHumanoid:FindFirstChildOfClass("Animator")
			if animator then
				local gripAnim : Animation = animator:LoadAnimation(gripAnimation)
				gripAnim:Play()
				gripAnim.Stopped:Connect(function() 
					StateManager.TempState(grippedPlayer,"Dead",0.4)
					gripper.HumanoidRootPart.Anchored = false
					Weld:Destroy()
					grippedHumanoid:TakeDamage(1000)
					StateManager.RemoveState(gripperPlayer,"Gripping")
					StateManager.RemoveState(grippedPlayer, "Gripped")
				end)
			end
		end

		if grippedHumanoid then
			local animator = grippedHumanoid:FindFirstChildOfClass("Animator")
			if animator then
				local grippedAnim = animator:LoadAnimation(grippedAnimation)
				grippedAnim:Play()

			end

			grippedHumanoid.WalkSpeed = 0
			grippedHumanoid.JumpPower = 0
			grippedHumanoid.JumpHeight = 0
		end
	end
end

gripRemote.OnServerEvent:Connect(function(player)
	for knockedPlayer, _ in pairs(knockedPlayers) do
		if isPlayerNearKnocked(player, knockedPlayer) then
			local targetCharacter : CharacterR6 = knockedPlayer.Character
			local character : CharacterR6 = player.Character

			if not character or not targetCharacter then
				return
			end

			local cancel = StateManager.HasState(player, "Gripping")
			grip(character, targetCharacter, cancel)
			break
		end
	end
end)

spawn(function()
	while true do
		updateKnockedTimer()

		for carrier, carried in pairs(carryingPlayers) do
			if knockedPlayers[carried] then
				resetKnockedTimer(carried)
			end
		end

		for gripper, gripped in pairs(grippingPlayers) do
			if knockedPlayers[gripped] then
				resetKnockedTimer(gripped)
			end
		end

		wait(1)
	end
end)

function module.Ragdoll(Character, Set, carry)
	local KnockFold = Character:FindFirstChild("Knocked")
	local Torso = Character:FindFirstChild("Torso")
	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	local Player = Players:GetPlayerFromCharacter(Character)

	if not Torso then
		return warn(tostring(Character), "did not have an existing torso when attempting to ragdoll them")
	end
	if not Humanoid then
		return warn(tostring(Character), "did not have an existing humanoid when attempting to ragdoll them")
	end
	if not HumanoidRootPart then
		return warn(tostring(Character), "did not have an existing humanoidrootpart when attempting to ragdoll them")
	end

	if Player and carryingPlayers[Player] and Set then
		stopCarrying(Player, false)
	end

	if Player and grippingPlayers[Player] and Set then
		stopGripping(Player, false)
	end

	if Set then
		if CollectionService:HasTag(Character, "Ragdolleda") then
			return
		end
		CollectionService:AddTag(Character, "Ragdolleda")

		if Player then
			StateManager.AddState(Player, "ragdolled")
		end

		Humanoid.WalkSpeed = 0
		Humanoid.JumpPower = 0
		Humanoid.JumpHeight = 0
		for _, track in pairs(Humanoid:GetPlayingAnimationTracks()) do
			track:Stop()
		end

		Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		Humanoid.RequiresNeck = false
		Humanoid.AutoRotate = false
		local Character_Descendants = Character:GetDescendants()
		for Index = 1, #Character_Descendants do
			local Object = Character_Descendants[Index]
			if
				Object:IsA("BasePart")
				and table.find(whitelist, Object.Name)
				and Object.Name ~= "AimAssist"
				and not Object:FindFirstChild("Bone")
				and Object.Name ~= "Bone"
				and Object.Name ~= "Hilt"
				and not Object:FindFirstChild("Stats")
			then
				local Bone = Object:Clone()
				Bone:ClearAllChildren()
				Bone.Name = "Bone"
				Bone.Size = Bone.Size / 2
				Bone.CollisionGroup = "Bones"
				Object.CollisionGroup = "Self"
				Bone.CanCollide = true
				Bone.Massless = true
				Bone.Transparency = 1
				Bone.Parent = Object
				task.spawn(function()
					if Bone.Anchored == false then
						Bone:SetNetworkOwner(nil)
					end
				end)

				local Weld = Instance.new("Weld")
				Weld.Part0 = Bone
				Weld.Part1 = Object
				Weld.Parent = Bone
				task.spawn(function()
					if Object.Anchored == false then
						Object:SetNetworkOwner(nil)
					end
				end)
			end
			if Object:IsA("Motor6D") and (Object.Name == "Neck" or Object.Name == "Left Hip" or Object.Name == "Left Shoulder" or Object.Name == "Right Hip" or Object.Name == "Right Shoulder") then
				Create[Object.Name](Character)
			end
		end
	else
		repeat
			wait()
		until not Character:FindFirstChild("Unconscious")
		if not CollectionService:HasTag(Character, "Ragdolleda") then
			return
		end
		if KnockFold then
			CollectionService:AddTag(KnockFold, "Removing")
		end
		Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		Humanoid.AutoRotate = true
		local BodyGyro = script.BodyGyro:Clone()
		BodyGyro.Parent = Character.HumanoidRootPart
		local Character_Descendants = Character:GetDescendants()
		for Index = 1, #Character_Descendants do
			local Object : BasePart = Character_Descendants[Index]
			if
				Object:IsA("BasePart")
				and table.find(whitelist, Object.Name)
				and Object:IsDescendantOf(game.Workspace)
			then
				Object.CollisionGroup = "Default"
				task.spawn(function()
					local grabbed = Character:FindFirstChild("Grabbed")
					if grabbed then
						carry = Players:GetPlayerFromCharacter(grabbed.Value)
					end
					if not Object.Anchored then
						if not carry then	
							Object:SetNetworkOwner(Player)
						else
							Object:SetNetworkOwner(carry)
						end
					end
				end)
			end
			if
				Object:IsA("Motor6D")
				and (
					Object.Name == "Neck"
						or Object.Name == "Left Hip"
						or Object.Name == "Left Shoulder"
						or Object.Name == "Right Hip"
						or Object.Name == "Right Shoulder"
				)
			then
				Object.Part0 = Torso
			end
			if Object.Name == "Bone" or Object.Name == "RagdollAttach" or Object:IsA("BallSocketConstraint") then
				Object:Destroy()
			end
		end
		CollectionService:RemoveTag(Character, "Ragdolleda")
		if KnockFold and KnockFold.Parent and CollectionService:HasTag(KnockFold, "Removing") then
			wait(0.1)
			if KnockFold and KnockFold.Parent then
				KnockFold:Destroy()
			end
		end
		Humanoid.RequiresNeck = true

		if not carriedPlayers[Player] and not knockedPlayers[Player] and not grippedPlayers[Player] then
			Humanoid.WalkSpeed = 16
			Humanoid.JumpPower = 50
			Humanoid.JumpHeight = 7.2
		end

		for _, part in pairs(Character:GetChildren()) do
			if part:IsA("BasePart") and table.find(whitelist, part.Name) then
				part.CanCollide = true
			end
		end

		if BodyGyro then
			BodyGyro:Destroy()
		end
	end
end

function module.ragdollWithTime(Character : CharacterR6, seconds : Number)
	module.Ragdoll(Character, true)
	task.delay(seconds, function()
		module.Ragdoll(Character, false)
	end)
end

function module.handleHealthDamage(humanoid, damage)
	local character = humanoid.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local wasKnocked = clampHealth(humanoid, damage)

	if player and grippingPlayers[player] then
		stopGripping(player, true)
	end

	if wasKnocked then
		module.setKnockedState(character, true)
	end
end

function module.setupHealthMonitoring(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.HealthChanged:Connect(function(health)

		if health <= 0 and not (StateManager.HasState(game.Players:GetPlayerFromCharacter(humanoid.Parent),"Dead")) then
			humanoid.Health = math.clamp(humanoid.Health,0.1,5)
			module.setKnockedState(character, true)
		end
	end)
end 

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		module.setupHealthMonitoring(character)
	end)
end)

for _, player in pairs(Players:GetPlayers()) do
	if player.Character then
		module.setupHealthMonitoring(player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		module.setupHealthMonitoring(character)
	end)
end

return module