local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TreeSway = {}
TreeSway.__index = TreeSway

local DEFAULT_SETTINGS = {
	BaseWindSpeed = 1.2,
	WindVariation = 0.8,
	MaxAngle = 8,
	GustIntensityRange = {2.5, 5.0},
	BranchStiffness = 0.75,
	HeightInfluence = 1.5,
	GustRadius = 60,
	WindBounds = {
		MinX = -800,
		MaxX = 800,
		MinZ = -800,
		MaxZ = 800,
	},
	TreeFolderName = "trees",
	BranchPartRange = {2, 13},
	TrunkPartName = "1",
	GustEffectParticleCount = 8,
	GustEffectSpeed = 20,
	GustEffectLifetime = 2.5,
}

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function smoothStep(t)
	return t * t * (3 - 2 * t)
end

function TreeSway.new(settings)
	local self = setmetatable({}, TreeSway)
	self.settings = settings or DEFAULT_SETTINGS
	self.gustRadiusSquared = self.settings.GustRadius * self.settings.GustRadius
	self.maxAngleRad = math.rad(self.settings.MaxAngle)
	self.branches = {}
	self.gusts = {}
	self.gustEffects = {}
	self.globalTime = 0
	self.windPhase = 0
	self.rng = Random.new()
	
	local success = self:_setupTrees()
	if not success then
		return nil
	end
	
	self._connection = RunService.Heartbeat:Connect(function(dt)
		self:_onHeartbeat(dt)
	end)
	
	return self
end

function TreeSway:_setupTrees()
	local treesFolder = Workspace:FindFirstChild(self.settings.TreeFolderName)
	if not treesFolder then return false end
	
	local children = treesFolder:GetChildren()
	for _, tree in pairs(children) do
		if tree:IsA("Model") then
			local trunk = tree:FindFirstChild(self.settings.TrunkPartName)
			if trunk and trunk:IsA("BasePart") then
				local treePos = trunk.Position
				
				if not self:_isWithinBounds(treePos) then
					print("Tree at position " .. tostring(treePos) .. " is outside wind bounds - no effects will be applied")
					continue
				end
				
				trunk.Anchored = true
				local treeHeight = self:_calculateTreeHeight(tree)
				
				for i = self.settings.BranchPartRange[1], self.settings.BranchPartRange[2] do
					local branch = tree:FindFirstChild(tostring(i))
					if branch and branch:IsA("BasePart") then
						branch.Anchored = true
						
						local relativeHeight = (branch.Position.Y - trunk.Position.Y) / treeHeight
						local branchLength = math.max(branch.Size.X, branch.Size.Z)
						local windSensitivity = math.min(1.0, branchLength / 10)
						
						table.insert(self.branches, {
							part = branch,
							trunk = trunk,
							restCFrame = branch.CFrame,
							treePos = treePos,
							heightFactor = math.pow(relativeHeight + 0.1, self.settings.HeightInfluence),
							windSensitivity = windSensitivity,
							baseOffset = Vector3.new(
								treePos.X * 0.01 + i * 0.1,
								0,
								treePos.Z * 0.01 + i * 0.15
							),
							swayState = {
								currentAngle = Vector3.new(0, 0, 0),
								velocity = Vector3.new(0, 0, 0),
								targetAngle = Vector3.new(0, 0, 0),
							},
							branchIndex = i,
						})
					end
				end
			end
		end
	end
	
	return #self.branches > 0
end

function TreeSway:_isWithinBounds(position)
	local bounds = self.settings.WindBounds
	return position.X >= bounds.MinX and position.X <= bounds.MaxX and
		   position.Z >= bounds.MinZ and position.Z <= bounds.MaxZ
end

function TreeSway:_calculateTreeHeight(tree)
	local minY, maxY = math.huge, -math.huge
	for _, part in pairs(tree:GetChildren()) do
		if part:IsA("BasePart") then
			local pos = part.Position
			minY = math.min(minY, pos.Y - part.Size.Y/2)
			maxY = math.max(maxY, pos.Y + part.Size.Y/2)
		end
	end
	return math.max(1, maxY - minY)
end


function TreeSway:CreateManualGust(position, direction, intensity, duration)
	if not self:_isWithinBounds(position) then
		return false
	end
	
	local gust = {
		position = position,
		startTime = self.globalTime,
		duration = duration or 4.0,
		intensity = intensity or 3.5,
		direction = direction.Unit,
	}
	
	table.insert(self.gusts, gust)
	return true
end

function TreeSway:_calculateBaseWind(branchData, time)
	local offset = branchData.baseOffset
	local heightFactor = branchData.heightFactor
	
	local primaryWave = math.sin(time * self.settings.BaseWindSpeed + offset.X) * 0.7
	local secondaryWave = math.sin(time * self.settings.BaseWindSpeed * 1.7 + offset.Z) * 0.3
	local microWind = math.sin(time * 4.5 + offset.X * 3) * 0.15
	
	local windStrength = (primaryWave + secondaryWave + microWind) * heightFactor * self.settings.WindVariation
	
	local windX = windStrength * 0.8
	local windZ = math.sin(time * self.settings.BaseWindSpeed * 0.8 + offset.Z) * heightFactor * self.settings.WindVariation * 0.6
	
	return Vector3.new(windX, 0, windZ)
end

function TreeSway:_calculateGustEffect(branchData, time)
	local totalGustForce = Vector3.new(0, 0, 0)
	local treePos = branchData.treePos
	
	for _, gust in ipairs(self.gusts) do
		local distance = (Vector3.new(treePos.X, 0, treePos.Z) - Vector3.new(gust.position.X, 0, gust.position.Z)).Magnitude
		
		if distance <= self.settings.GustRadius then
			local elapsed = time - gust.startTime
			local progress = elapsed / gust.duration
			
			if progress >= 0 and progress <= 1 then
				local envelope = math.sin(progress * math.pi)
				local falloff = 1 - (distance / self.settings.GustRadius)
				falloff = falloff * falloff
				
				local gustStrength = gust.intensity * envelope * falloff * branchData.heightFactor
				local gustDirection = gust.direction + Vector3.new(
					math.sin(elapsed * 3) * 0.2,
					0,
					math.cos(elapsed * 2.5) * 0.2
				)
				
				totalGustForce = totalGustForce + gustDirection * gustStrength
			end
		end
	end
	
	return totalGustForce
end

function TreeSway:_updateGustEffects(dt)
	for i = #self.gustEffects, 1, -1 do
		local effectGroup = self.gustEffects[i]
		local elapsed = self.globalTime - effectGroup.startTime
		
		if elapsed > effectGroup.lifetime then
			for _, effectData in ipairs(effectGroup.parts) do
				if effectData.part and effectData.part.Parent then
					effectData.part:Destroy()
				end
			end
			table.remove(self.gustEffects, i)
		else
			for _, effectData in ipairs(effectGroup.parts) do
				if effectData.part and effectData.part.Parent then
					local effectElapsed = elapsed
					local alpha = effectElapsed / effectGroup.lifetime
					
					local forward = effectData.direction * effectData.speed * effectElapsed
					local wave = Vector3.new(0, math.sin(effectElapsed * 4 + effectData.waveOffset) * 2, 0)
					local drift = effectData.perpendicular * math.sin(effectElapsed * 2) * 1.5
					
					effectData.part.Position = effectData.initialPos + forward + wave + drift
					effectData.part.Transparency = lerp(0.4, 0.95, alpha)
					
					local scale = lerp(0.8, 0.3, alpha)
					effectData.part.Size = Vector3.new(scale, scale, scale)
				end
			end
		end
	end
end

function TreeSway:_applyBranchMovement(branchData, windForce, dt)
	local swayState = branchData.swayState
	local stiffness = self.settings.BranchStiffness
	local damping = 0.85
	
	local maxAngle = self.maxAngleRad * branchData.windSensitivity
	swayState.targetAngle = Vector3.new(
		math.clamp(windForce.X * maxAngle, -maxAngle, maxAngle),
		0,
		math.clamp(windForce.Z * maxAngle, -maxAngle, maxAngle)
	)
	
	local angleDiff = swayState.targetAngle - swayState.currentAngle
	local force = angleDiff * stiffness - swayState.velocity * damping
	
	swayState.velocity = swayState.velocity + force * dt
	swayState.currentAngle = swayState.currentAngle + swayState.velocity * dt
	
	local pivotPoint = branchData.trunk.Position + Vector3.new(0, branchData.trunk.Size.Y/2, 0)
	local offset = branchData.restCFrame.Position - pivotPoint
	
	local rotationCFrame = CFrame.Angles(swayState.currentAngle.X, 0, swayState.currentAngle.Z)
	local newPosition = pivotPoint + rotationCFrame:VectorToWorldSpace(offset)
	
	branchData.part.CFrame = CFrame.lookAt(newPosition, newPosition + rotationCFrame.LookVector) * 
							 (branchData.restCFrame - branchData.restCFrame.Position)
end

function TreeSway:_onHeartbeat(dt)
	self.globalTime = self.globalTime + dt
	self.windPhase = self.windPhase + dt * self.settings.BaseWindSpeed
	
	self:_updateGustEffects(dt)
	
	for i = #self.gusts, 1, -1 do
		if self.globalTime - self.gusts[i].startTime > self.gusts[i].duration then
			table.remove(self.gusts, i)
		end
	end
	
	for _, branchData in ipairs(self.branches) do
		local baseWind = self:_calculateBaseWind(branchData, self.globalTime)
		local gustWind = self:_calculateGustEffect(branchData, self.globalTime)
		local totalWind = baseWind + gustWind
		
		self:_applyBranchMovement(branchData, totalWind, dt)
	end
end

function TreeSway.Create(settings)
	return TreeSway.new(settings)
end

function TreeSway:Destroy()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
	
	for _, branchData in ipairs(self.branches) do
		branchData.part.CFrame = branchData.restCFrame
	end
	
	for _, effectGroup in ipairs(self.gustEffects) do
		for _, effectData in ipairs(effectGroup.parts) do
			if effectData.part and effectData.part.Parent then
				effectData.part:Destroy()
			end
		end
	end
	
	self.branches = {}
	self.gusts = {}
	self.gustEffects = {}
end

return TreeSway