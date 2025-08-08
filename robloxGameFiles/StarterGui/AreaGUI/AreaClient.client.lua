local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local AreaData = require(ReplicatedStorage:WaitForChild("AreaData"))

local Requests = ReplicatedStorage:WaitForChild("Requests")
local AreaChange = Requests:WaitForChild("AreaChange")

local gui = script.Parent
local areaLabel = gui:FindFirstChild("Area")
local descLabel = gui:FindFirstChild("Description")

local fadeTween, holdConn
local lightingTween

local currentAreaMusic = nil
local currentAreaMusicTween = nil
local currentAreaMusicTargetVolume = nil

local function resetLighting()
    for _, prop in ipairs({
        "Ambient", "Brightness", "ColorShift_Bottom", "ColorShift_Top", "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
        "ExposureCompensation", "FogColor", "FogEnd", "FogStart", "GeographicLatitude", "GlobalShadows", "OutdoorAmbient", "ShadowSoftness"
    }) do
        pcall(function()
            if typeof(Lighting[prop]) == "Color3" then
                Lighting[prop] = Color3.new(0,0,0)
            elseif typeof(Lighting[prop]) == "number" then
                Lighting[prop] = 0
            elseif typeof(Lighting[prop]) == "boolean" then
                Lighting[prop] = false
            end
        end)
    end
    for _, obj in ipairs(Lighting:GetChildren()) do
        obj:Destroy()
    end
end

local function cloneAtmospheresToLighting(atmosphere)
    if atmosphere:IsA("Folder") then
        for _, obj in ipairs(atmosphere:GetChildren()) do
            local clone = obj:Clone()
            clone.Parent = Lighting
        end
    elseif atmosphere:IsA("Instance") then
        local clone = atmosphere:Clone()
        clone.Parent = Lighting
    end
end

local function fadeLabels(label1, text1, label2, text2, fadeInTime, holdTime, fadeOutTime)
    if not label1 or not label2 then return end
    if fadeTween then fadeTween:Cancel() end
    if holdConn then holdConn:Disconnect() end
    label1.Text = text1 or ""
    label2.Text = text2 or ""
    label1.Visible = true
    label2.Visible = true
    label1.TextTransparency = 1
    label2.TextTransparency = 1
    label1.TextStrokeTransparency = 1
    label2.TextStrokeTransparency = 1
    local stroke1 = label1:FindFirstChild("Stroke")
    local stroke2 = label2:FindFirstChild("Stroke")
    if stroke1 then stroke1.Transparency = 1 end
    if stroke2 then stroke2.Transparency = 1 end

    local fadeIn1 = TweenService:Create(label1, TweenInfo.new(fadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0, TextStrokeTransparency = 0})
    local fadeIn2 = TweenService:Create(label2, TweenInfo.new(fadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0, TextStrokeTransparency = 0})
    local fadeInStroke1, fadeInStroke2
    if stroke1 then fadeInStroke1 = TweenService:Create(stroke1, TweenInfo.new(fadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0}) end
    if stroke2 then fadeInStroke2 = TweenService:Create(stroke2, TweenInfo.new(fadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0}) end
    fadeTween = fadeIn1
    fadeIn1:Play()
    fadeIn2:Play()
    if fadeInStroke1 then fadeInStroke1:Play() end
    if fadeInStroke2 then fadeInStroke2:Play() end

    fadeIn1.Completed:Connect(function()
        task.spawn(function()
            task.wait(holdTime)
            local fadeOut1 = TweenService:Create(label1, TweenInfo.new(fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1, TextStrokeTransparency = 1})
            local fadeOut2 = TweenService:Create(label2, TweenInfo.new(fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1, TextStrokeTransparency = 1})
            local fadeOutStroke1, fadeOutStroke2
            if stroke1 then fadeOutStroke1 = TweenService:Create(stroke1, TweenInfo.new(fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}) end
            if stroke2 then fadeOutStroke2 = TweenService:Create(stroke2, TweenInfo.new(fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}) end
            fadeTween = fadeOut1
            fadeOut1:Play()
            fadeOut2:Play()
            if fadeOutStroke1 then fadeOutStroke1:Play() end
            if fadeOutStroke2 then fadeOutStroke2:Play() end
            fadeOut1.Completed:Connect(function()
                label1.Visible = false
                label2.Visible = false
            end)
        end)
    end)
end

local function tweenLightingProperties(targetProps, tweenTime)
    if lightingTween then lightingTween:Cancel() end
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local props = {}
    for prop, value in pairs(targetProps) do
        if prop ~= "Atmosphere" then
            props[prop] = value
        end
    end
    lightingTween = TweenService:Create(Lighting, tweenInfo, props)
    lightingTween:Play()
end

AreaChange.OnClientEvent:Connect(function(areaName)
    print("AreaChange event received on client:", areaName)
    local area = AreaData[areaName]
    if not area or not area.Lighting then
        print("AreaData missing or no Lighting for", areaName)
        return
    end
    resetLighting()
    tweenLightingProperties(area.Lighting, 3)
    if area.Lighting.Atmosphere then
        cloneAtmospheresToLighting(area.Lighting.Atmosphere)
    end
    if areaLabel and descLabel then
        fadeLabels(areaLabel, area.Name or areaName, descLabel, area.Description or "", 3, 3, 3)
    end
    -- area music logic
    if currentAreaMusicTween then
        currentAreaMusicTween:Cancel()
        currentAreaMusicTween = nil
    end
    if currentAreaMusic then
        print("[AreaMusic] Stopping previous area music.")
        currentAreaMusic:Stop()
        if currentAreaMusicTargetVolume then
            currentAreaMusic.Volume = currentAreaMusicTargetVolume
        end
        currentAreaMusic = nil
        currentAreaMusicTargetVolume = nil
    end
    if area.AreaMusic then
        print("[AreaMusic] Attempting to play area music for area:", areaName, "instance:", area.AreaMusic)
        local sound = area.AreaMusic
        if sound and sound:IsA("Sound") then
            print("[AreaMusic] Found sound:", sound.Name, "(Volume:", sound.Volume, ")")
            currentAreaMusic = sound
            currentAreaMusicTargetVolume = sound.Volume
            sound.Volume = 0
            sound:Play()
            print("[AreaMusic] Playing and fading in:", sound.Name)
            currentAreaMusicTween = TweenService:Create(sound, TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Volume = currentAreaMusicTargetVolume})
            currentAreaMusicTween:Play()
        else
            print("[AreaMusic] Failed to find or play sound for area:", areaName, "sound:", sound)
        end
    else
        print("[AreaMusic] No AreaMusic defined for area:", areaName)
    end
end)