local players = game:GetService("Players")
local dangerremote = game.ServerStorage.AddDanger
local gimme = game.ServerStorage.GimmeDanger
local apology = script.Apology

danger = {}

players.PlayerAdded:Connect(function(player: Player)  
	danger[player.Name] = {indanger = false, time = 0, damagetable = {}}
end)


local function clearDangerTag(damagerName, targetName)
    if not danger[targetName] then return end
    
    danger[targetName].damagetable[damagerName] = nil
    
    if next(danger[targetName].damagetable) == nil then
        danger[targetName].time = 0
        danger[targetName].indanger = false
        if danger[targetName].dangerCoroutine then
            coroutine.close(danger[targetName].dangerCoroutine)
            danger[targetName].dangerCoroutine = nil
        end
        local targetPlayer = players:FindFirstChild(targetName)
        if targetPlayer and targetPlayer:FindFirstChild("DangerTime") then
            targetPlayer.DangerTime.Value = 0
        end
    else
        local maxTime = 0
        for _, damageData in pairs(danger[targetName].damagetable) do
            if damageData.time and damageData.time > maxTime then
                maxTime = damageData.time
            end
        end
        danger[targetName].time = maxTime
        local targetPlayer = players:FindFirstChild(targetName)
        if targetPlayer and targetPlayer:FindFirstChild("DangerTime") then
            targetPlayer.DangerTime.Value = maxTime
        end
    end
end

local function clearAllDangerTags(damagerName)
    for targetName, _ in pairs(danger) do
        clearDangerTag(damagerName, targetName)
    end
end

players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		humanoid.Died:Connect(function()
			task.wait(1)
			clearAllDangerTags(player.Name)
			if danger[player.Name] then
				for damagerName, _ in pairs(danger[player.Name].damagetable) do
					clearDangerTag(damagerName, player.Name)
				end
			end
		end)
	end)
end)


players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        local damagerName = player.Name
        
        local apologyResult = apology.checkApology(message, damagerName, "")
        if apologyResult == "all" then
            clearAllDangerTags(damagerName)
            return
        end
        
        for targetName, _ in pairs(danger) do
            if danger[targetName].damagetable[damagerName] then
                local apologyResult = apology.checkApology(message, damagerName, targetName)
                if apologyResult then
                    clearDangerTag(damagerName, targetName)
                end
            end
        end
    end)
end)

dangerremote.OnInvoke = function(player : Player, damagetable, dangertime)
	if not dangertime then dangertime = 30 end
	local playerdanger = danger[player.Name]
	if playerdanger.dangerCoroutine then
		coroutine.close(playerdanger.dangerCoroutine)
	end
	
	for damagerName, damageData in pairs(damagetable) do
		playerdanger.damagetable[damagerName] = {damage = damageData, time = dangertime}
	end
	
	local maxTime = 0
	for _, damageData in pairs(playerdanger.damagetable) do
		if damageData.time and damageData.time > maxTime then
			maxTime = damageData.time
		end
	end
	
	playerdanger.time = maxTime
	playerdanger.time = math.min(playerdanger.time, 120)
	
	if not player:FindFirstChild("DangerTime") then
		local number = Instance.new("NumberValue")
		number.Parent = player
		number.Name = "DangerTime"
	end
	
	local dangertimeValue = player:FindFirstChild("DangerTime")
	local dangerCoroutine = coroutine.create(function()
		while playerdanger.time > 0 do
			playerdanger.indanger = true
			playerdanger.time = playerdanger.time - 1
			playerdanger.time = math.max(playerdanger.time, 0)
			dangertimeValue.Value = playerdanger.time
			if playerdanger.time <= 0 then
				playerdanger.indanger = false
				break
			end
			task.wait(1)
		end
		playerdanger.indanger = false
		playerdanger.dangerCoroutine = nil
	end)
	playerdanger.dangerCoroutine = dangerCoroutine
	coroutine.resume(dangerCoroutine)
end

gimme.OnInvoke = function()
	return danger								
end

