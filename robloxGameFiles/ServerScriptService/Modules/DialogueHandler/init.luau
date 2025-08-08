local DialogueHandler = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local DialogueModule = require(script.Dialogue)

local activeDialogues = {}

local function showDialogue(player, dialogue, page)
    local remote = ReplicatedStorage.Requests and ReplicatedStorage.Requests:FindFirstChild("Dialogue")
    if remote then
        local data = {}
        for k, v in pairs(dialogue) do data[k] = v end
        data.page = page
        remote:FireClient(player, data)
    end
end

function DialogueHandler.startDialogue(player, npcName)
    local npcKey = npcName
    if not DialogueModule[npcKey] then return end
    local page = "p1"
    local dialogueFunc = DialogueModule[npcKey].v1
    if dialogueFunc then
        local dialogue = dialogueFunc(player, {page = 1})
        if dialogue then
            showDialogue(player, dialogue, page)
            activeDialogues[player] = {npc = npcKey, page = page}
        end
    end
end

function DialogueHandler.choose(player, context)
    local active = activeDialogues[player]
    if not active then return end
    local npcKey = active.npc
    local dialogueFunc = DialogueModule[npcKey].v1
    if not dialogueFunc then return end
    local v = {page = active.page, choice = context.choice}
    local nextDialogue = dialogueFunc(player, v)
    if nextDialogue then
        showDialogue(player, nextDialogue, context.choice or v.page)
        activeDialogues[player].page = context.choice or v.page
    else
        DialogueHandler.endDialogue(player)
    end
end

function DialogueHandler.endDialogue(player)
    activeDialogues[player] = nil
    local remote = ReplicatedStorage.Requests and ReplicatedStorage.Requests:FindFirstChild("Dialogue")
    if remote then
        remote:FireClient(player, {exit = true})
    end
end

local function setupNPCClicks()
    local npcs = Workspace:FindFirstChild("NPCs")
    if not npcs then return end
    for _, npc in ipairs(npcs:GetChildren()) do
        local click = npc:FindFirstChildOfClass("ClickDetector")
        if click then
            click.MouseClick:Connect(function(player)
                DialogueHandler.startDialogue(player, npc.Name)
            end)
        end
    end
end

setupNPCClicks()

local DialogueRemote = ReplicatedStorage:FindFirstChild("Requests") and ReplicatedStorage.Requests:FindFirstChild("Dialogue")
if DialogueRemote then
    DialogueRemote.OnServerEvent:Connect(function(player, data)
        if data then
            if data.exit then
                DialogueHandler.endDialogue(player)
            elseif data.choice and data.page then
                DialogueHandler.choose(player, {page = data.page, choice = data.choice})
            end
        end
    end)
end

return DialogueHandler 