-- DataPersistence.server.lua
-- Handles all DataStore save/load operations.

local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService       = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local DataManager  = require(Modules.DataManager)
local Constants    = require(Modules.Constants)

local STORE_KEY    = "PlayerData_v1"
local store        = DataStoreService:GetDataStore(STORE_KEY)
local sessionData  = {}   -- [userId] = data table (live, in-memory)

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function key(player)
	return "user_" .. tostring(player.UserId)
end

local function saveData(player)
	local data = sessionData[player.UserId]
	if not data then return end
	data.lastLogin = os.time()
	local success, err = pcall(function()
		store:SetAsync(key(player), data)
	end)
	if not success then
		warn("[DataPersistence] Save failed for", player.Name, err)
	end
end

-- ── Load on join ─────────────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
	local loaded, err = pcall(function()
		local raw = store:GetAsync(key(player))
		if raw then
			sessionData[player.UserId] = DataManager.migrate(raw, player.UserId)
		else
			sessionData[player.UserId] = DataManager.defaultData(player.UserId)
		end
	end)
	if not loaded then
		warn("[DataPersistence] Load failed for", player.Name, err)
		sessionData[player.UserId] = DataManager.defaultData(player.UserId)
	end

	-- Fire event so other scripts know data is ready
	local bindable = Instance.new("BindableEvent")
	bindable.Name  = "DataLoaded_" .. player.UserId
	bindable.Parent = ReplicatedStorage
	bindable:Fire(sessionData[player.UserId])
end)

-- ── Save on leave ─────────────────────────────────────────────────────────────

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	sessionData[player.UserId] = nil
end)

-- ── Auto-save loop ────────────────────────────────────────────────────────────

task.spawn(function()
	while true do
		task.wait(Constants.AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			saveData(player)
		end
	end
end)

-- ── Public API (used by other server scripts) ─────────────────────────────────

local DataPersistence = {}

function DataPersistence.get(player)
	return sessionData[player.UserId]
end

function DataPersistence.save(player)
	saveData(player)
end

-- Expose for other server modules
return DataPersistence
