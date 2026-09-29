-- LeaderboardManager.server.lua
-- Writes and reads OrderedDataStore leaderboards, refreshes every 60 seconds.

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules          = ReplicatedStorage:WaitForChild("Modules")
local LBManager        = require(Modules.LeaderboardManager)
local Constants        = require(Modules.Constants)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpdateLeaderboard = Remotes:WaitForChild("UpdateLeaderboard")

local stores = {}
for _, key in ipairs(Constants.LEADERBOARD_KEYS) do
	stores[key] = DataStoreService:GetOrderedDataStore("LB_" .. key)
end

local function getDP()
	return require(game:GetService("ServerScriptService"):WaitForChild("DataPersistenceBridge"))
end

-- ── Post a player's stats ─────────────────────────────────────────────────────

local function postStats(player)
	local data = getDP().get(player)
	if not data then return end

	pcall(function()
		stores["TopEarners"]:SetAsync(tostring(player.UserId), data.money.totalEarned or 0)
	end)
	pcall(function()
		stores["WeeklyEarners"]:SetAsync(tostring(player.UserId), data.money.weeklyEarned or 0)
	end)
	pcall(function()
		stores["FastestProgression"]:SetAsync(tostring(player.UserId), data.level or 1)
	end)

	-- Efficiency: total earned / number of employees (avoid /0)
	local empCount = math.max(1, #(data.employees or {}))
	local efficiency = math.floor((data.money.totalEarned or 0) / empCount)
	pcall(function()
		stores["Efficiency"]:SetAsync(tostring(player.UserId), efficiency)
	end)
end

-- ── Fetch top 100 for a board ─────────────────────────────────────────────────

local function fetchTop(boardKey)
	local results = {}
	local ok, data = pcall(function()
		local pages = stores[boardKey]:GetSortedAsync(false, 100)
		local page = pages:GetCurrentPage()
		for rank, entry in ipairs(page) do
			table.insert(results, {
				rank  = rank,
				userId= entry.key,
				value = entry.value,
			})
		end
	end)
	if not ok then warn("[Leaderboard] fetch failed:", data) end
	return results
end

-- ── Broadcast to all clients ──────────────────────────────────────────────────

local function broadcastAll()
	local allData = {}
	for _, key in ipairs(Constants.LEADERBOARD_KEYS) do
		allData[key] = fetchTop(key)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		UpdateLeaderboard:FireClient(player, allData)
	end
end

-- ── Refresh loop (60 sec) ─────────────────────────────────────────────────────

task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			postStats(player)
		end
		broadcastAll()
	end
end)

Players.PlayerAdded:Connect(function(player)
	-- Post after data loads and send current board
	task.delay(5, function()
		postStats(player)
		local allData = {}
		for _, key in ipairs(Constants.LEADERBOARD_KEYS) do
			allData[key] = fetchTop(key)
		end
		UpdateLeaderboard:FireClient(player, allData)
	end)
end)

return {}
