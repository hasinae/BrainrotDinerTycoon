-- GameLoop.server.lua
-- Bootstraps remotes and ties together all server systems.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ── Create Remotes folder ─────────────────────────────────────────────────────
local Remotes = Instance.new("Folder")
Remotes.Name  = "Remotes"
Remotes.Parent = ReplicatedStorage

local function makeRemoteEvent(name)
	local r = Instance.new("RemoteEvent")
	r.Name  = name
	r.Parent = Remotes
	return r
end

local function makeRemoteFunction(name)
	local r = Instance.new("RemoteFunction")
	r.Name  = name
	r.Parent = Remotes
	return r
end

makeRemoteEvent("UpdateBalance")
makeRemoteEvent("DeleteObject")
makeRemoteEvent("SpendMoney")
makeRemoteEvent("Notification")
makeRemoteEvent("UpdateLeaderboard")
makeRemoteEvent("HireEmployee")
makeRemoteEvent("FireEmployee")
makeRemoteEvent("EquipCosmetic")

makeRemoteFunction("PlaceObject")
makeRemoteFunction("Expand")
makeRemoteFunction("GetPlayerData")

-- ── Create bridge ModuleScripts so server scripts can cross-require ──────────
-- DataPersistenceBridge wraps DataPersistence so other scripts can require it
local dpBridge = Instance.new("ModuleScript")
dpBridge.Name  = "DataPersistenceBridge"
dpBridge.Parent = game:GetService("ServerScriptService")
dpBridge.Source = [[
	return require(game:GetService("ServerScriptService"):WaitForChild("DataPersistence.server"))
]]

local msBridge = Instance.new("ModuleScript")
msBridge.Name  = "MoneyServerBridge"
msBridge.Parent = game:GetService("ServerScriptService")
msBridge.Source = [[
	return require(game:GetService("ServerScriptService"):WaitForChild("MoneySystem.server"))
]]

-- ── GetPlayerData remote (client requests its own data snapshot) ─────────────
local GetPlayerData = Remotes:WaitForChild("GetPlayerData")
GetPlayerData.OnServerInvoke = function(player)
	-- Wait briefly for data to load
	local dp
	for _ = 1, 10 do
		dp = pcall(function()
			return require(game:GetService("ServerScriptService"):WaitForChild("DataPersistenceBridge")).get(player)
		end)
		if dp then break end
		task.wait(0.5)
	end
	local ok, data = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("DataPersistenceBridge")).get(player)
	end)
	return ok and data or nil
end

-- ── Hire/Fire remotes ──────────────────────────────────────────────────────────
local HireEmployee = Remotes:WaitForChild("HireEmployee")
HireEmployee.OnServerEvent:Connect(function(player, typeKey)
	local ok, data = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("DataPersistenceBridge")).get(player)
	end)
	if not ok or not data then return end

	local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))
	local cfg = Constants.EMPLOYEES[typeKey]
	if not cfg then return end

	-- Count existing of this type
	local count = 0
	for _, e in ipairs(data.employees) do
		if e.type == typeKey then count = count + 1 end
	end
	if count >= cfg.maxPerRestaurant then return end

	-- Charge
	local MS = require(game:GetService("ServerScriptService"):WaitForChild("MoneyServerBridge"))
	if not MS.spend(player, cfg.hireCost, "hire_" .. typeKey) then return end

	local newId = #data.employees + 1
	local emp = { id = newId, type = typeKey, name = cfg.displayName }
	table.insert(data.employees, emp)

	-- Spawn AI
	require(game:GetService("ServerScriptService"):WaitForChild("EmployeeAI.server")).spawnForPlayer(
		player, emp, Vector3.new((player.UserId % 20) * 35, 0, 0), {}
	)
end)

local FireEmployee = Remotes:WaitForChild("FireEmployee")
FireEmployee.OnServerEvent:Connect(function(player, empId)
	local ok, data = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("DataPersistenceBridge")).get(player)
	end)
	if not ok or not data then return end

	for i, emp in ipairs(data.employees) do
		if emp.id == empId then
			local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))
			local cfg = Constants.EMPLOYEES[emp.type]
			if cfg then
				local refund = math.floor(cfg.hireCost * 0.5)
				require(game:GetService("ServerScriptService"):WaitForChild("MoneyServerBridge")).earn(player, refund)
			end
			require(game:GetService("ServerScriptService"):WaitForChild("EmployeeAI.server")).fireEmployee(player, empId)
			table.remove(data.employees, i)
			break
		end
	end
end)

print("[GameLoop] Server initialized")
