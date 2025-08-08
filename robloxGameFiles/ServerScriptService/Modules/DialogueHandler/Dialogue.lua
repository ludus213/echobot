local DevProductHandler = require(script.Parent.Parent.DevProducts)
local PlayerData = require(script.Parent.Parent.Parent.PlayerData)

local Dialogue = {}

Dialogue['Echo Keeper'] = {
        p1 = {
            speaker = "The Echo Keeper",
            msg = "So... you drift here again. What do you seek in this {Hollow}?",
            choices = {
            "Rebirth",
            "More Vestige (1000R)",
            "New form (250R)",
            "New Echo (100R)",
            "Nothing."
        },
        endchoice = "Nothing."
    },

    rebirth = {
            speaker = "The Echo Keeper",
            msg = "Very well... tell me - what shall you become?",
            choices = {
            "A boy",
            "A girl",
            "Nevermind."
        },
        endchoice = "Nevermind."
    },

    waiting_vestige = {
            speaker = "The Echo Keeper",
            msg = "Waiting for purchase...",
        endchoice = ""
        },

    waiting_race = {
            speaker = "The Echo Keeper",
            msg = "Waiting for purchase...",
        endchoice = ""
        },

    waiting_echo = {
            speaker = "The Echo Keeper",
            msg = "Waiting for purchase...",
        endchoice = ""
        },

    boy = {
            speaker = "The Echo Keeper",
            msg = "So be it. May your Echo hum anew in %Sonis%.",
        endchoice = ""
            },

    girl = {
            speaker = "The Echo Keeper",
            msg = "So be it. May your Echo hum anew in %Sonis%.",
        endchoice = ""
            },

    vestige = {
            speaker = "The Echo Keeper",
            msg = "Your vestige is restored. Return anew.",
        endchoice = ""
        },

    race = {
            speaker = "The Echo Keeper",
            msg = "Your form is changed. Return anew.",
        endchoice = ""
        },

    echo = {
            speaker = "The Echo Keeper",
            msg = "Your echo is changed. Return anew.",
        endchoice = ""
        },

        vestige_too_high = {
            speaker = "The Echo Keeper",
            msg = "How did you get in here?",
        endchoice = ""
    }
}

local PRODUCT_KEYS = {
    ["More Vestige (1000R)"] = "Resurrection",
    ["New form (250R)"] = "RerollRace",
    ["New Echo (100R)"] = "RerollEcho"
}

local PURCHASE_TO_NODE = {
    ["Resurrection"] = "vestige",
    ["RerollRace"] = "race",
    ["RerollEcho"] = "echo"
}

local function echoKeeper_v1(p, v)
    local d = Dialogue['Echo Keeper']
    local RunService = game:GetService("RunService")
    local playerData = PlayerData.GetData(p)

    -- check vestige
    if v.page == 1 and playerData and playerData.vestige and playerData.vestige > 0 and not RunService:IsStudio() then
        return d.vestige_too_high
    end

    -- change gender
    if v.choice == "A boy" then
        PlayerData.Wipe(p, "Male")
        return d.boy
    elseif v.choice == "A girl" then
        PlayerData.Wipe(p, "Female")
        return d.girl
    end

    -- purchase options
    if PRODUCT_KEYS[v.choice] then
        local productKey = PRODUCT_KEYS[v.choice]
        local waitingNode = "waiting_" .. productKey:lower():gsub("resurrection", "vestige"):gsub("rerollrace", "race"):gsub("rerollecho", "echo")
        DevProductHandler.promptPurchase(p, productKey, function(player)
            local finalNode = PURCHASE_TO_NODE[productKey]
            local remote = game:GetService("ReplicatedStorage").Requests and game:GetService("ReplicatedStorage").Requests:FindFirstChild("Dialogue")
            if remote then
                local data = {}
                for k, v in pairs(d[finalNode]) do data[k] = v end
                data.page = finalNode
                remote:FireClient(player, data)
            end
			task.spawn(function()
				task.wait(3)
                print("[EchoKeeper] Applying effect for", player.Name, productKey)
                if productKey == "Resurrection" then
                    print("[EchoKeeper] Calling UpdateVestige for", player.Name)
                    PlayerData.UpdateVestige(player, 5)
                elseif productKey == "RerollRace" then
                    print("[EchoKeeper] Calling Wipe and UpdateOrigin for", player.Name)
                    PlayerData.Wipe(player)
                    PlayerData.UpdateOrigin(player, PlayerData.RollOrigin())
                elseif productKey == "RerollEcho" then
                    print("[EchoKeeper] Calling Wipe and UpdateEchoType for", player.Name)
                    PlayerData.Wipe(player)
                    PlayerData.UpdateEchoType(player, "")
                end
            end)
        end)
        return d[waitingNode]
    end

    -- dialogue branching
	if v.page == 1 then
        return d.p1
    elseif v.choice == "Rebirth" then
        return d.rebirth
    elseif v.choice == "More Vestige (1000R)" then
        return d.waiting_vestige
    elseif v.choice == "New form (250R)" then
        return d.waiting_race
    elseif v.choice == "New Echo (100R)" then
        return d.waiting_echo
    elseif v.choice == "Complete Vestige Purchase" then
        return d.vestige
    elseif v.choice == "Complete Race Purchase" then
        return d.race
    elseif v.choice == "Complete Echo Purchase" then
        return d.echo
    end
end

Dialogue['Echo Keeper'].v1 = echoKeeper_v1

return Dialogue 