-- PurchaseHandler.server.lua
-- Handles MarketplaceService product/pass/subscription purchases.

local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local Modules   = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules.Constants)

local function getDP()
	return require(game:GetService("ServerScriptService"):WaitForChild("DataPersistenceBridge"))
end
local function getMS()
	return require(game:GetService("ServerScriptService"):WaitForChild("MoneyServerBridge"))
end

-- ── Developer Product IDs (replace with real IDs before publishing) ───────────
local DEV_PRODUCT_IDS = {
	[000000001] = "speedup_week",
	[000000002] = "quick_expansion",
	[000000003] = "cash_small",
	[000000004] = "cash_medium",
	[000000005] = "cash_large",
}

-- ── Game Pass IDs ─────────────────────────────────────────────────────────────
local GAMEPASS_IDS = {
	[100000001] = "premium_speedup",
	[100000002] = "exec_chef_outfit",
	[100000003] = "all_themes_pack",
	[100000004] = "premium_dish_pack",
}

-- ── Process developer product ─────────────────────────────────────────────────

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = getDP().get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productKey = DEV_PRODUCT_IDS[receiptInfo.ProductId]
	if not productKey then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local shopEntry = Constants.SHOP[productKey]

	if productKey == "speedup_week" then
		data.weeklySpeedupExpires = os.time() + 7 * 86400
	elseif productKey == "quick_expansion" then
		-- Skip the expansion timer (timers not currently implemented; immediate flag)
		data.quickExpansionReady = true
	elseif shopEntry and shopEntry.igc then
		getMS().earn(player, shopEntry.igc)
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ── Gamepass checks on join ───────────────────────────────────────────────────

local function checkGamePasses(player)
	local data = getDP().get(player)
	if not data then return end

	for passId, passKey in pairs(GAMEPASS_IDS) do
		local owns = false
		pcall(function()
			owns = MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if owns then
			if passKey == "premium_speedup" then
				data.hasPremiumSpeedup = true
			elseif passKey == "exec_chef_outfit" then
				if not data.cosmetics.unlockedOutfits then data.cosmetics.unlockedOutfits = {} end
				local has = false
				for _, o in ipairs(data.cosmetics.unlockedOutfits) do
					if o == "exec_chef" then has = true; break end
				end
				if not has then table.insert(data.cosmetics.unlockedOutfits, "exec_chef") end
			elseif passKey == "all_themes_pack" then
				for themeKey in pairs(Constants.THEMES) do
					local has = false
					for _, t in ipairs(data.cosmetics.unlockedThemes) do
						if t == themeKey then has = true; break end
					end
					if not has then table.insert(data.cosmetics.unlockedThemes, themeKey) end
				end
			elseif passKey == "premium_dish_pack" then
				data.premiumDishPack = true
			end
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	local loadEvent = ReplicatedStorage:WaitForChild("DataLoaded_" .. player.UserId, 30)
	if not loadEvent then return end
	loadEvent.Event:Wait()
	task.delay(2, function() checkGamePasses(player) end)
end)

return {}
