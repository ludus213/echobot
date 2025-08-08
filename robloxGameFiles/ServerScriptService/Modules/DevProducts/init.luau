local Products = require(script.products)
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DevProductHandler = {}

local pendingGrants = {} -- [userId][productKey] = callback

function DevProductHandler.promptPurchase(player, productKey, onGrant)
    local product = Products[productKey]
    if product then
        if RunService:IsStudio() then
            if onGrant then
                task.delay(5, function()
                    onGrant(player)
                end)
            end
            return true
        end
        if onGrant then
            pendingGrants[player.UserId] = pendingGrants[player.UserId] or {}
            pendingGrants[player.UserId][productKey] = onGrant
        end
        MarketplaceService:PromptProductPurchase(player, product.Id)
    end
end

function DevProductHandler.handleReceipt(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
    for key, product in pairs(Products) do
        if product.Id == receiptInfo.ProductId then
            print("[DevProductHandler] Granting product:", key, "to", player.Name)
            if pendingGrants[receiptInfo.PlayerId] and pendingGrants[receiptInfo.PlayerId][key] then
                local callback = pendingGrants[receiptInfo.PlayerId][key]
                pendingGrants[receiptInfo.PlayerId][key] = nil
                callback(player)
                return Enum.ProductPurchaseDecision.PurchaseGranted
            end
            -- If no callback, grant by default (for safety)
            return Enum.ProductPurchaseDecision.PurchaseGranted
        end
    end
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.ProcessReceipt = DevProductHandler.handleReceipt

return DevProductHandler 