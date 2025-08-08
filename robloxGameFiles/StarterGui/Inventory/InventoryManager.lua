local InventoryManager = {}
InventoryManager.__index = InventoryManager

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

function InventoryManager.new(inventoryGui, clientScript)
	local self = setmetatable({}, InventoryManager)

	self.gui = inventoryGui
	self.inventoryFrame = inventoryGui:WaitForChild("Inventory")
	self.scrollingFrame = self.inventoryFrame:WaitForChild("ScrollingFrame")
	self.hotbar = inventoryGui:WaitForChild("Hotbar")
	self.itemTemplate = clientScript:WaitForChild("ItemTemplate")

	self.player = Players.LocalPlayer
	self.mouse = self.player:GetMouse()
	self.backpack = self.player:WaitForChild("Backpack")
	self.character = self.player.Character or self.player.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")

	self.hotbarSlots = {}
	self.toolFrames = {}
	self.slotMarkers = {}
	self.slotData = {}
	self.cooldowns = {}

	self.isOpen = false
	self.draggingTool = nil
	self.isUpdating = false
	self.lastUpdateTime = 0
	self.updateThrottle = 0.033
	self.isFirstLoad = true

	self.keyMap = {
		[Enum.KeyCode.One] = 1,
		[Enum.KeyCode.Two] = 2,
		[Enum.KeyCode.Three] = 3,
		[Enum.KeyCode.Four] = 4,
		[Enum.KeyCode.Five] = 5,
		[Enum.KeyCode.Six] = 6,
		[Enum.KeyCode.Seven] = 7,
		[Enum.KeyCode.Eight] = 8,
		[Enum.KeyCode.Nine] = 9,
		[Enum.KeyCode.Zero] = 10,
		[Enum.KeyCode.Minus] = 11,
		[Enum.KeyCode.Equals] = 12,
	}

	self.slotKeys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" }

	self:initializeRemotes()
	self:createHotbarSlots()
	self:connectEvents()

	return self
end

function InventoryManager:initializeRemotes()
	self.updateSlotDataRemote = ReplicatedStorage.Requests:FindFirstChild("UpdateSlotData")
	if not self.updateSlotDataRemote then
		self.updateSlotDataRemote = Instance.new("RemoteEvent")
		self.updateSlotDataRemote.Name = "UpdateSlotData"
		self.updateSlotDataRemote.Parent = ReplicatedStorage
	end
end

function InventoryManager:scheduleUpdate()
	local currentTime = tick()
	if currentTime - self.lastUpdateTime < self.updateThrottle then
		return
	end

	if self.isUpdating then
		return
	end

	self.lastUpdateTime = currentTime
	task.spawn(function()
		self:updateDisplay()
	end)
end

function InventoryManager:getVisibleSlotCount()
	local visibleSlots = 0
	for i = 1, 12 do
		if self.hotbarSlots[i] then
			visibleSlots = visibleSlots + 1
		end
	end
	return visibleSlots
end

function InventoryManager:updateDisplay()
	if self.isUpdating then
		return
	end

	self.isUpdating = true

	local visibleSlots = self:getVisibleSlotCount()

	local currentSlot = 0
	for i = 1, 12 do
		local toolName = self.hotbarSlots[i]
		local toolFrame = toolName and self.toolFrames[toolName]

		if toolFrame and toolFrame.frame then
			currentSlot = currentSlot + 1
			self:updateToolFrame(toolFrame, i, currentSlot, visibleSlots)
		else
			self:updateSlotMarker(i)
		end
	end

	self:updateUnslottedTools()
	self:updateHotbarSize(visibleSlots)

	self.isUpdating = false
end

function InventoryManager:updateToolFrame(toolFrame, slotIndex, currentSlot, visibleSlots)
	local frame = toolFrame.frame
	local toolName = toolFrame.tool.Name

	local position = visibleSlots > 1 and (currentSlot - 1) / (visibleSlots - 1) or 0
	if self.isOpen then
		position = (slotIndex - 1) / 11
	end

	frame.SlotNumber.Text = self.slotKeys[slotIndex]
	frame.Position = UDim2.new(position, 0, 0, 0)
	frame.SlotNumber.Visible = true
	frame.Parent = self.hotbar

	local toolCount = self:getToolCount(toolName)
	frame.Amount.Text = string.format("x%i", toolCount)
	frame.Amount.Visible = toolCount > 1

	if self.draggingTool ~= toolName then
		self:updateToolEquipState(frame, toolName)
	end

	self.slotMarkers[slotIndex].Visible = false
end

function InventoryManager:updateSlotMarker(slotIndex)
	local marker = self.slotMarkers[slotIndex]
	if marker then
		marker.Visible = self.isOpen
	end
end

function InventoryManager:updateUnslottedTools()
	for toolName, toolFrame in pairs(self.toolFrames) do
		if not toolFrame.slot then
			local frame = toolFrame.frame
			local toolCount = self:getToolCount(toolName)
			frame.Amount.Text = string.format("x%i", toolCount)
			frame.Amount.Visible = toolCount > 1

			if self.draggingTool ~= toolName then
				self:updateToolEquipState(frame, toolName)
				frame.SlotNumber.Visible = false
				frame.Parent = self.scrollingFrame
			end
		end
	end
end

function InventoryManager:updateToolEquipState(frame, toolName)
	local isEquipped = self.character:FindFirstChild(toolName)
	local isSelected = CollectionService:HasTag(frame, "BPSelected")

	if isEquipped and not isSelected then
		frame.BackgroundColor3 = Color3.new(221 / 255, 227 / 255, 243 / 255)
		frame.TextTransparency = 0
		CollectionService:AddTag(frame, "BPSelected")
		TweenService:Create(frame, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.new(221 / 255, 227 / 255, 243 / 255),
		}):Play()
	elseif not isEquipped and isSelected then
		frame.BackgroundColor3 = Color3.new(181 / 255, 177 / 255, 203 / 255)
		frame.TextTransparency = 0.2
		CollectionService:RemoveTag(frame, "BPSelected")
		TweenService:Create(frame, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.new(181 / 255, 177 / 255, 203 / 255),
		}):Play()
	elseif not isEquipped and not isSelected then
		frame.BackgroundColor3 = Color3.new(181 / 255, 177 / 255, 203 / 255)
		frame.TextTransparency = 0.2
	end
end

function InventoryManager:updateHotbarSize(visibleSlots)
	local hotbarWidth = visibleSlots > 1 and 72 * (visibleSlots - 1) or 0
	if self.isOpen then
		hotbarWidth = 792
	end

	self.hotbar.Size = UDim2.new(0, hotbarWidth, 0, 60)
	self.inventoryFrame.Visible = self.isOpen
end

function InventoryManager:getToolCount(toolName)
	local count = 0
	for _, tool in ipairs(self.backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name == toolName then
			local quantity = tool:FindFirstChild("Quantity")
			count = count + (quantity and quantity.Value or 1)
		end
	end

	local equippedTool = self.character:FindFirstChild(toolName)
	if equippedTool then
		local quantity = equippedTool:FindFirstChild("Quantity")
		count = count + (quantity and quantity.Value or 1)
	end

	return count
end

function InventoryManager:findToolByName(container, toolName)
	for _, tool in ipairs(container:GetChildren()) do
		if tool.Name == toolName and tool:IsA("Tool") then
			return tool
		end
	end
	return nil
end

function InventoryManager:equipTool(toolName)
	local currentTime = tick()
	local lastUse = self.cooldowns[toolName]
	if lastUse and currentTime < lastUse then
		return
	end

	local equippedInCharacter = self.character:FindFirstChild(toolName)
	if equippedInCharacter then
		if equippedInCharacter:FindFirstChild("Handle") then
			self.cooldowns[toolName] = currentTime + 0.1
		end
		self.humanoid:UnequipTools()
		return
	end

	local toolInBackpack = self:findToolByName(self.backpack, toolName)
	if toolInBackpack then
		if toolInBackpack:FindFirstChild("Handle") then
			self.cooldowns[toolName] = currentTime + 0.1
		end
		self.humanoid:EquipTool(toolInBackpack)
	end
end

function InventoryManager:createToolFrame(tool, autoAssign)
	if not tool.Parent then
		return
	end

	local toolName = tool.Name
	if self.toolFrames[toolName] then
		self:scheduleUpdate()
		return
	end

	local frame = self.itemTemplate:Clone()
	frame.Text = toolName
	frame.Name = toolName

	local toolFrame = {
		frame = frame,
		tool = tool,
		slot = nil,
		quantityConnections = {},
	}

	self:setupToolFrameEvents(toolFrame)
	self.toolFrames[toolName] = toolFrame

	self:updateToolQuantityConnections(toolName)

	local assigned = false
	print("Slot Data Loaded!")
	for slotIndex, savedTool in pairs(self.slotData) do
		print(slotIndex .. ". " .. savedTool)
		local slotNum = tonumber(slotIndex)
		if slotNum and savedTool == toolName then
			self:assignToolToSlot(slotNum, toolName, true)
			assigned = true
			break
		end
	end

	if not assigned and autoAssign then
		if self.isFirstLoad then
		else
			for i = 1, 12 do
				if not self.hotbarSlots[i] then
					self:assignToolToSlot(i, toolName, true)
					break
				end
			end
		end
	end

	self:scheduleUpdate()
end

function InventoryManager:updateToolQuantityConnections(toolName)
	local toolFrame = self.toolFrames[toolName]
	if not toolFrame then
		return
	end

	for _, connection in pairs(toolFrame.quantityConnections) do
		connection:Disconnect()
	end
	toolFrame.quantityConnections = {}

	for _, tool in ipairs(self.backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name == toolName then
			local quantity = tool:FindFirstChild("Quantity")
			if quantity then
				table.insert(
					toolFrame.quantityConnections,
					quantity.Changed:Connect(function()
						self:scheduleUpdate()
					end)
				)
			end
		end
	end

	local equippedTool = self.character:FindFirstChild(toolName)
	if equippedTool then
		local quantity = equippedTool:FindFirstChild("Quantity")
		if quantity then
			table.insert(
				toolFrame.quantityConnections,
				quantity.Changed:Connect(function()
					self:scheduleUpdate()
				end)
			)
		end
	end
end

function InventoryManager:removeToolFrame(toolName, onlyClear)
	local toolFrame = self.toolFrames[toolName]
	if not toolFrame then
		return
	end

	if self.character:FindFirstChild(toolName) or self:findToolByName(self.backpack, toolName) then
		return
	end

	if onlyClear then
		toolFrame.frame:Destroy()
		if toolFrame.quantityConnection then
			toolFrame.quantityConnection:Disconnect()
		end
		self.toolFrames[toolName] = nil
		return
	end

	self.toolFrames[toolName] = nil
	toolFrame.frame:Destroy()

	local slot = toolFrame.slot
	if slot and self.hotbarSlots[slot] == toolName then
		self.hotbarSlots[slot] = nil
		self.slotData[tostring(slot)] = nil
		self:saveSlotData()
	end

	for _, connection in pairs(toolFrame.quantityConnections) do
		connection:Disconnect()
	end

	self:scheduleUpdate()
	return true
end

function InventoryManager:setupToolFrameEvents(toolFrame)
	local frame = toolFrame.frame
	local toolName = toolFrame.tool.Name

	frame.MouseButton1Down:Connect(function()
		if self.draggingTool then
			return
		end

		if not self.isOpen then
			self:equipTool(toolName)
			self:scheduleUpdate()
			return
		end

		local startPosition = Vector2.new(self.mouse.X, self.mouse.Y)
		local startTime = tick()
		local connection
		local hasMoved = false

		connection = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				local currentPosition = Vector2.new(self.mouse.X, self.mouse.Y)
				local distance = (currentPosition - startPosition).Magnitude

				if distance > 5 and tick() - startTime > 0.1 then
					connection:Disconnect()
					hasMoved = true
					self:startDragOperation(toolFrame)
				end
			end
		end)

		local releaseConnection
		releaseConnection = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				connection:Disconnect()
				releaseConnection:Disconnect()

				if not hasMoved then
					self:equipTool(toolName)
					self:scheduleUpdate()
				end
			end
		end)
	end)
end

function InventoryManager:startDragOperation(toolFrame)
	local toolName = toolFrame.tool.Name
	local currentSlot = toolFrame.slot
	self.draggingTool = toolName

	toolFrame.frame.BackgroundColor3 = Color3.new(221 / 255, 227 / 255, 243 / 255)
	toolFrame.frame.Parent = self.gui

	for i = 1, 12 do
		local slotTool = self.hotbarSlots[i]
		local slotFrame = slotTool and self.toolFrames[slotTool]
		local marker = self.slotMarkers[i]
		if marker then
			marker.Visible = not slotFrame or not slotFrame.frame or i == currentSlot
		end
	end

	local connection
	connection = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and self.draggingTool == toolName then
			connection:Disconnect()
			self:endDragOperation(toolFrame, currentSlot)
		end
	end)

	self:handleDragMovement(toolFrame)
end

function InventoryManager:handleDragMovement(toolFrame)
	local toolName = toolFrame.tool.Name
	task.spawn(function()
		while self.draggingTool == toolName do
			toolFrame.frame.Position = UDim2.new(0, self.mouse.X, 0, self.mouse.Y)
			RunService.RenderStepped:Wait()
		end
	end)
end

function InventoryManager:endDragOperation(toolFrame, currentSlot)
	local toolName = toolFrame.tool.Name
	local validSlot = self:getDropSlot()
	local inInventoryArea = self:isInInventoryArea()

	self.draggingTool = nil

	if validSlot == currentSlot then
		self:equipTool(toolName)
	elseif validSlot then
		self:assignToolToSlot(validSlot, toolName)
	elseif inInventoryArea then
		self:assignToolToSlot(nil, toolName)
	end

	self:scheduleUpdate()
end

function InventoryManager:getDropSlot()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local hotbarY = viewportSize.Y - 125

	print("=== DRAG DROP DEBUG ===")
	print("Mouse Position:", self.mouse.X, self.mouse.Y)
	print("Viewport Size:", viewportSize.X, viewportSize.Y)
	print("Hotbar Y:", hotbarY)
	print("Y Range:", hotbarY - 50, "to", hotbarY + 120)
	print("Inventory Open:", self.isOpen)

	if self.mouse.Y < hotbarY - 50 or self.mouse.Y > hotbarY + 120 then
		print("Mouse Y outside hotbar range")
		print("======================")
		return nil
	end

	print("Mouse Y in hotbar range")

	local hotbarCenter = viewportSize.X / 2

	if self.isOpen then
		local hotbarWidth = 792
		local hotbarLeft = hotbarCenter - hotbarWidth / 2
		local hotbarRight = hotbarLeft + hotbarWidth
		local slotWidth = hotbarWidth / 12

		print("Open inventory mode:")
		print("Hotbar Center:", hotbarCenter)
		print("Hotbar Width:", hotbarWidth)
		print("Hotbar Left:", hotbarLeft)
		print("Hotbar Right:", hotbarRight)
		print("Slot Width:", slotWidth)
		print("X Range with tolerance:", hotbarLeft - 50, "to", hotbarRight + 50)

		if self.mouse.X >= hotbarLeft - 50 and self.mouse.X <= hotbarRight + 50 then
			local relativeX = math.max(0, self.mouse.X - hotbarLeft)
			local slotIndex = math.floor(relativeX / slotWidth) + 1
			local finalSlot = math.max(1, math.min(12, slotIndex))

			print("Mouse X in range")
			print("Relative X:", relativeX)
			print("Raw slot index:", slotIndex)
			print("Final slot:", finalSlot)
			print("======================")

			return finalSlot
		else
			print("Mouse X outside range")
			print("======================")
		end
	else
		local visibleSlots = self:getVisibleSlotCount()
		if visibleSlots > 0 then
			local compactWidth = visibleSlots > 1 and 72 * (visibleSlots - 1) or 0
			local compactLeft = hotbarCenter - compactWidth / 2
			local compactRight = compactLeft + compactWidth

			if self.mouse.X >= compactLeft - 50 and self.mouse.X <= compactRight + 50 then
				local slots = {}
				for i = 1, 12 do
					if self.hotbarSlots[i] then
						table.insert(slots, i)
					end
				end

				if #slots > 0 then
					if visibleSlots == 1 then
						return slots[1]
					else
						local relativeX = math.max(0, self.mouse.X - compactLeft)
						local slotIndex = math.floor(relativeX / (compactWidth / (visibleSlots - 1))) + 1
						slotIndex = math.max(1, math.min(#slots, slotIndex))
						return slots[slotIndex]
					end
				end
			end
		end
	end

	print("No valid slot found")
	print("======================")
	return nil
end

function InventoryManager:isInInventoryArea()
	if not self.isOpen then
		return false
	end

	local scrollingFramePos = self.scrollingFrame.AbsolutePosition
	local scrollingFrameSize = self.scrollingFrame.AbsoluteSize

	return self.mouse.X >= scrollingFramePos.X
		and self.mouse.X <= scrollingFramePos.X + scrollingFrameSize.X
		and self.mouse.Y >= scrollingFramePos.Y
		and self.mouse.Y <= scrollingFramePos.Y + scrollingFrameSize.Y
end

function InventoryManager:assignToolToSlot(slotIndex, toolName, skipSave)
	local toolFrame = self.toolFrames[toolName]
	if not toolFrame then
		return
	end

	local currentSlot = toolFrame.slot

	if currentSlot then
		self.hotbarSlots[currentSlot] = nil
		self.slotData[tostring(currentSlot)] = nil
	end

	if slotIndex then
		local existingTool = self.hotbarSlots[slotIndex]
		if existingTool and existingTool ~= toolName then
			local existingFrame = self.toolFrames[existingTool]
			if existingFrame then
				if currentSlot then
					self.hotbarSlots[currentSlot] = existingTool
					self.slotData[tostring(currentSlot)] = existingTool
					existingFrame.slot = currentSlot
				else
					existingFrame.slot = nil
				end
			end
		end

		self.hotbarSlots[slotIndex] = toolName
		self.slotData[tostring(slotIndex)] = toolName
		toolFrame.slot = slotIndex
	else
		toolFrame.slot = nil
	end

	if not skipSave then
		self:saveSlotData()
		self:scheduleUpdate()
	end
end

function InventoryManager:saveSlotData()
	local success, jsonString = pcall(function()
		return HttpService:JSONEncode(self.slotData)
	end)

	if success and jsonString then
		local playerData = self.player:FindFirstChild("PlayerData")
		if playerData and playerData:FindFirstChild("SlotData") then
			playerData.SlotData.Value = jsonString
		end

		if self.updateSlotDataRemote then
			task.spawn(function()
				pcall(function()
					self.updateSlotDataRemote:FireServer(self.slotData)
				end)
			end)
		end
	end
end

function InventoryManager:loadSlotData()
	local playerData = self.player:FindFirstChild("PlayerData")
	if playerData and playerData:FindFirstChild("SlotData") then
		local slotDataString = playerData.SlotData.Value
		if slotDataString and slotDataString ~= "" then
			local success, slotData = pcall(function()
				return HttpService:JSONDecode(slotDataString)
			end)
			if success and slotData then
				self.slotData = slotData
				self:scheduleUpdate()
			end
		end
	end
end

function InventoryManager:createHotbarSlots()
	for i = 1, 12 do
		local marker = self.itemTemplate:Clone()
		marker.Visible = false
		marker.Position = UDim2.new((i - 1) / 11, 0, 0, 0)
		marker.Parent = self.hotbar
		marker.Text = ""
		marker.SlotNumber.Text = self.slotKeys[i]
		marker.SlotNumber.Visible = true
		marker.BackgroundTransparency = 0.5
		self.slotMarkers[i] = marker
	end
end

function InventoryManager:toggle()
	if self.draggingTool then
		self.draggingTool = nil
	end

	self.isOpen = not self.isOpen
	self:scheduleUpdate()
end

function InventoryManager:connectEvents()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		local slotIndex = self.keyMap[input.KeyCode]
		local toolName = slotIndex and self.hotbarSlots[slotIndex]
		if toolName then
			self:equipTool(toolName)
			self:scheduleUpdate()
			return
		end

		if input.KeyCode == Enum.KeyCode.Backquote then
			self:toggle()
		end

		if input.KeyCode == Enum.KeyCode.V and self.carryInputRemote then
			self.carryInputRemote:FireServer()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and self.draggingTool then
			self.draggingTool = nil
			self:scheduleUpdate()
		end
	end)

	self.backpack.ChildAdded:Connect(function(tool)
		if not tool:IsA("Tool") then
			return
		end

		if self.toolFrames[tool.Name] then
			self:updateToolQuantityConnections(tool.Name)
			self:scheduleUpdate()
			return
		end

		task.wait()
		self:createToolFrame(tool, not self.isFirstLoad)
		self:scheduleUpdate()
	end)

	self.backpack.ChildRemoved:Connect(function(tool)
		if not tool:IsA("Tool") then
			return
		end

		local toolName = tool.Name
		if not self.toolFrames[toolName] then
			self:scheduleUpdate()
			return
		end

		self:removeToolFrame(toolName)
		self:scheduleUpdate()
	end)

	self.character.ChildAdded:Connect(function(tool)
		if not tool:IsA("Tool") then
			return
		end

		if self.toolFrames[tool.Name] then
			self:updateToolQuantityConnections(tool.Name)
			self:scheduleUpdate()
			return
		end

		task.wait()
		self:createToolFrame(tool, not self.isFirstLoad)
		self:scheduleUpdate()
	end)

	self.character.ChildRemoved:Connect(function(tool)
		if not tool:IsA("Tool") then
			return
		end

		local toolName = tool.Name
		if not self.toolFrames[toolName] then
			self:scheduleUpdate()
			return
		end

		self:removeToolFrame(toolName)
		self:scheduleUpdate()
	end)

	self.player.CharacterAdded:Connect(function(newCharacter)
		self.character = newCharacter
		self.humanoid = newCharacter:WaitForChild("Humanoid")

		for toolName, toolFrame in pairs(self.toolFrames) do
			if toolFrame.frame then
				toolFrame.frame:Destroy()
			end
			if toolFrame.quantityConnection then
				toolFrame.quantityConnection:Disconnect()
			end
		end
		self.toolFrames = {}

		task.wait()

		local allTools = {}
		for _, tool in ipairs(self.backpack:GetChildren()) do
			if tool:IsA("Tool") then
				table.insert(allTools, tool)
			end
		end

		for _, tool in ipairs(allTools) do
			self:createToolFrame(tool, false)
		end

		self:scheduleUpdate()
	end)
end

function InventoryManager:initialize()
	task.spawn(function()
		self:loadSlotData()

		local hasSlotData = next(self.slotData) ~= nil
		local allTools = self.backpack:GetChildren()

		for _, tool in ipairs(allTools) do
			if tool and tool:IsA("Tool") then
				self:createToolFrame(tool, not hasSlotData)
			end
		end

		self.isFirstLoad = false

		task.wait(0.1)
		self:scheduleUpdate()

		task.wait(0.5)
		self:scheduleUpdate()
	end)
end

return InventoryManager
