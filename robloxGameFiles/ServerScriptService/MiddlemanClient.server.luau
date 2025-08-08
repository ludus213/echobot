local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local PlayerData = require(game.ServerScriptService.PlayerData)

local MIDDLEMAN_URL = "http://127.0.0.1:8000"
local ADMIN_TOKEN = "changeme"

local function request(method, path, body)
	local url = MIDDLEMAN_URL .. path
	local headers = { ["Content-Type"] = "application/json", ["X-Admin-Token"] = ADMIN_TOKEN }
	local payload = body and HttpService:JSONEncode(body) or ""
	local res = HttpService:RequestAsync({ Url = url, Method = method, Headers = headers, Body = payload })
	if not res.Success then return nil end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(res.Body)
	end)
	if ok then return data end
	return nil
end

local function get_profile(player)
	local data = PlayerData.getData(player)
	return data
end

local function update_server_player_state(player)
	local profile = get_profile(player)
	if not profile then return end
	local d = profile.Data
	request("POST", "/player/state", { player = player.Name, strikes = d.strikes or 0, banned = d.banned and 1 or 0, vestige = d.vestige or 0 })
end

local function apply_restore(playerName, amount)
	local player = Players:FindFirstChild(playerName)
	if not player then return end
	local data = PlayerData.GetData(player)
	if not data then return end
	local add = math.clamp(tonumber(amount) or 0, 1, 100)
	local newv = (data.vestige or 0) + add
	PlayerData.UpdateVestige(player, newv)
	update_server_player_state(player)
end

local function apply_strike(playerName)
	local player = Players:FindFirstChild(playerName)
	if not player then return end
	local profile = PlayerData.getData(player)
	if not profile then return end
	profile.Data.strikes = (profile.Data.strikes or 0) + 1
	PlayerData.UpdateExternalData(player)
	update_server_player_state(player)
end

local function apply_ban(playerName)
	local player = Players:FindFirstChild(playerName)
	local profile
	if player then
		profile = PlayerData.getData(player)
		if profile then
			profile.Data.banned = true
			PlayerData.UpdateExternalData(player)
			player:Kick("Banned")
			update_server_player_state(player)
		end
	end
end

local function apply_unban(playerName)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name == playerName then
			local profile = PlayerData.getData(p)
			if profile then
				profile.Data.banned = false
				PlayerData.UpdateExternalData(p)
				update_server_player_state(p)
			end
		end
	end
end

local function apply_kick(playerName)
	local player = Players:FindFirstChild(playerName)
	if player then
		player:Kick("Kicked")
	end
end

spawn(function()
	while true do
		task.wait(2)
		local polled = request("GET", "/commands/poll?limit=25")
		if not polled or not polled.ok then continue end
		local ids = {}
		for _, item in ipairs(polled.results or {}) do
			local command = item.command
			local payload = item.payload or {}
			if command == "restore" then
				apply_restore(payload.player, payload.amount)
			elseif command == "strike" then
				apply_strike(payload.player)
			elseif command == "ban" then
				apply_ban(payload.player)
			elseif command == "unban" then
				apply_unban(payload.player)
			elseif command == "kick" then
				apply_kick(payload.player)
			end
			table.insert(ids, item.id)
		end
		if #ids > 0 then
			request("POST", "/commands/ack", { ids = ids })
		end
	end
end)