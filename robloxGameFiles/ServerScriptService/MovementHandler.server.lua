local ReplicatedStorage, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local StateManager = require(script.Parent.Modules.StateManager)
local ActionCheck = require(script.Parent.Modules.ActionCheck)
local Remote = ReplicatedStorage.Requests.MovementRemote
local dashCooldown, runState, runCooldown = {}, {}, {}
local BASE_SPEED, MAX_SPEED, DASH_POWER, DASH_TIME = 16, 40, 80, 0.25

local function setSpeed(h, speed)
	if h then h.WalkSpeed = math.clamp(speed, BASE_SPEED, MAX_SPEED) end
end

local function dashDirection(h, dir)
	local root = h.RootPart.CFrame
	return dir == "Left" and -root.RightVector
		or dir == "Right" and root.RightVector
		or dir == "Back" and -root.LookVector
		or root.LookVector
end

Remote.OnServerEvent:Connect(function(p, action, param)
	local c = p.Character
	if not c then return end
	local h, root = c:FindFirstChildOfClass("Humanoid"), c:FindFirstChild("HumanoidRootPart")
	if not h or not root or ActionCheck:check(p) then return end
	
	if action == "Run" then
		if param then
			runState[p] = h.WalkSpeed
			setSpeed(h, h.WalkSpeed + 6)
			StateManager.AddState(p, "Running")
			Remote:FireAllClients("RunAnim", p)
		else
			setSpeed(h, runState[p] or BASE_SPEED)
			runState[p] = nil
			StateManager.RemoveState(p, "Running")
			Remote:FireAllClients("StopRun", p)
		end
	elseif action == "Dash" and (not dashCooldown[p] or tick() - dashCooldown[p] >= 1) then
		dashCooldown[p] = tick()
		StateManager.AddState(p, "Dashing")
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1, 0, 1) * 1e5
		bv.Velocity = dashDirection(h, param or "Front") * DASH_POWER
		bv.Parent = root
		bv.Name = param or "Front"
		if param then
			for i,v in c.Torso:GetChildren() do 
				if v.Name == "Fire" then
					v.Enabled = false
				end
			end
		end
		Remote:FireAllClients("DashAnim", p, param)
		task.delay(DASH_TIME, function()
			bv:Destroy()
			StateManager.RemoveState(p, "Dashing")
		end)
	end
end)

Players.PlayerRemoving:Connect(function(p)
	dashCooldown[p], runState[p] = nil, nil
end)