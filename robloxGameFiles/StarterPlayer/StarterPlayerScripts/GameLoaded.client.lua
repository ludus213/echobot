local EchoSystemClient = require(script.Parent.EchoSystemClient)
local system = EchoSystemClient.new() 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local menuRemote = ReplicatedStorage.Requests:WaitForChild("menu")

local playerGui = player:WaitForChild("PlayerGui")
if not playerGui:FindFirstChild("MainMenu") then
    menuRemote:FireServer("menu")
end

local function waitForMenu()
    local menu
    repeat
        menu = playerGui:FindFirstChild("MainMenu")
        if not menu then
            task.wait(0.1)
        end
    until menu
    menu:GetPropertyChangedSignal("Parent"):Connect(function()
        if not menu.Parent then
            ReplicatedStorage.Requests.MenuDone:FireServer()
        end
    end)
end
waitForMenu() 