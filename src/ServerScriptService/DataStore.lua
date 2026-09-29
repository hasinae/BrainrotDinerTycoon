-- DataStore.lua  (ModuleScript — can be required by any server script)
-- Single source of truth for all player session data.

local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules      = ReplicatedStorage:WaitForChild("Modules")
local DataManager  = require(Modules.DataManager)
local Constants    = require(Modules.Constants)

local STORE_KEY   = "PlayerData_v2"
local sessionData = {}   -- [userId] -> live data table

local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_KEY)
	end)
	store = ok and result or nil
	if not store then
		warn("[DataStore] DataStore unavailable — using in-memory data only (enable Studio API access in Game Settings → Security)")
	end
end

local DataStore = {}

function DataStore.key(player)
	return "u_" .. tostring(player.UserId)
end

function DataStore.get(player)
	return sessionData[player.UserId]
end

function DataStore.set(player, data)
	sessionData[player.UserId] = data
end

function DataStore.load(player)
	local data
	if store then
		local success, result = pcall(function()
			return store:GetAsync(DataStore.key(player))
		end)
		if success and result then
			data = DataManager.migrate(result, player.UserId)
		else
			if not success then warn("[DataStore] Load failed for", player.Name, result) end
			data = DataManager.defaultData(player.UserId)
		end
	else
		data = DataManager.defaultData(player.UserId)
	end

	-- Ensure starter employee exists
	if not data.employees or #data.employees == 0 then
		local types = { "tung_tung_sahur", "tralalero_tralala", "ballerina_cappuccina" }
		local picked = types[math.random(1, #types)]
		local cfg    = Constants.EMPLOYEES[picked]
		data.employees = {{
			id     = 1,
			type   = picked,
			name   = cfg and cfg.displayName or picked,
			salary = cfg and cfg.salary or 3,
		}}
	end

	sessionData[player.UserId] = data

	return data
end

function DataStore.save(player)
	if not store then return end
	local data = sessionData[player.UserId]
	if not data then return end
	data.lastLogin = os.time()
	local success, err = pcall(function()
		store:SetAsync(DataStore.key(player), data)
	end)
	if not success then
		warn("[DataStore] Save failed for", player.Name, err)
	end
end

function DataStore.unload(player)
	DataStore.save(player)
	sessionData[player.UserId] = nil
end

function DataStore.waitForData(player, timeout)
	timeout = timeout or 10
	local deadline = tick() + timeout
	while tick() < deadline do
		if sessionData[player.UserId] then
			return sessionData[player.UserId]
		end
		task.wait(0.05)
	end
	return sessionData[player.UserId]
end

return DataStore
