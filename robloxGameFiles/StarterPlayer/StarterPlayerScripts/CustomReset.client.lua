local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local resetBindable = Instance.new("BindableEvent")

resetBindable.Event:Connect(function()
    local remote = ReplicatedStorage:FindFirstChild("CustomResetRequest")
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = "CustomResetRequest"
        remote.Parent = ReplicatedStorage
    end
    remote:FireServer()
end)

local function setResetCallback()
    local success = false
    repeat
        success = pcall(function()
            StarterGui:SetCore("ResetButtonCallback", resetBindable)
        end)
        if not success then
            task.wait(0.2)
        end
    until success
end

setResetCallback() 