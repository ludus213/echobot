local StarterGui = game:GetService("StarterGui")
local InventoryManager = require(script.Parent.InventoryManager)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local inventoryGui = script.Parent
local inventoryManager = InventoryManager.new(inventoryGui, script)
inventoryManager:initialize()
