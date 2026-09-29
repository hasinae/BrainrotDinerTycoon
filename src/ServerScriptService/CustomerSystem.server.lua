-- CustomerSystem.server.lua
-- Spawns and manages customer NPCs server-side.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

local Modules          = ReplicatedStorage:WaitForChild("Modules")
local CustomerSpawner  = require(Modules.CustomerSpawner)
local Constants        = require(Modules.Constants)
local DishSystem       = require(Modules.DishSystem)
local PathfindingHelper= require(Modules.PathfindingHelper)

-- [userId] = { customers = [], orderQueue = [], reputation = 1.0 }
local playerSessions = {}

local function getDP()
	return require(game:GetService("ServerScriptService"):WaitForChild("DataPersistenceBridge"))
end
local function getMS()
	return require(game:GetService("ServerScriptService"):WaitForChild("MoneyServerBridge"))
end

-- ── Customer model ────────────────────────────────────────────────────────────

local CUSTOMER_COLORS = {
	regular = BrickColor.new("Bright blue"),
	sigma   = BrickColor.new("Bright yellow"),
	npc     = BrickColor.new("Medium stone grey"),
	skibidi = BrickColor.new("Bright red"),
}

local function makeCustomerModel(customerType, spawnPos)
	local templates = ServerStorage:FindFirstChild("CustomerModels")
	local template  = templates and templates:FindFirstChild(customerType)
	local model
	if template then
		model = template:Clone()
	else
		model = Instance.new("Model")
		model.Name = "Customer_" .. customerType

		local root = Instance.new("Part")
		root.Name  = "HumanoidRootPart"
		root.Size  = Vector3.new(2, 2, 1)
		root.BrickColor = CUSTOMER_COLORS[customerType] or BrickColor.new("Bright blue")
		root.Anchored = false
		root.Parent   = model

		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = model

		model.PrimaryPart = root
	end

	model.Parent = workspace
	model:PivotTo(CFrame.new(spawnPos))
	return model
end

-- ── Customer AI ────────────────────────────────────────────────────────────────

local function runCustomer(player, session, customerType, entryPos, tablePos)
	local model    = makeCustomerModel(customerType, entryPos)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root     = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then model:Destroy(); return end

	table.insert(session.customers, model)

	-- Check if restaurant is too full
	if #session.customers > Constants.MAX_CONCURRENT_CUSTOMERS then
		-- Remove oldest
		local oldest = table.remove(session.customers, 1)
		if oldest then oldest:Destroy() end
	end

	-- Estimate wait and decide whether to stay
	local queueDepth = 0
	for _, o in ipairs(session.orderQueue) do
		if o.status == "pending" then queueDepth = queueDepth + 1 end
	end
	local estimatedWait = queueDepth * 4   -- rough seconds per pending order
	if CustomerSpawner.decideLeave(estimatedWait, customerType) then
		model:Destroy()
		return
	end

	-- Walk to table
	humanoid.WalkSpeed = 14
	PathfindingHelper.moveToSimple(humanoid, tablePos + Vector3.new(0, 3, 0), function(reached)
		if not reached then model:Destroy(); return end

		-- Pick a random dish
		local data = getDP().get(player)
		if not data then model:Destroy(); return end
		local available = DishSystem.getAvailableDishes(data)
		if #available == 0 then model:Destroy(); return end
		local dishKey = available[math.random(1, #available)]

		-- Place order
		local order = {
			id          = math.random(100000, 999999),
			dishKey     = dishKey,
			cookTime    = Constants.DISHES[dishKey].cookTime,
			status      = "pending",
			orderedAt   = os.clock(),
			assignedTo  = nil,
			readyAt     = nil,
			customerType= customerType,
			customer    = model,
		}
		table.insert(session.orderQueue, order)

		-- Wait for dish
		local waited = false
		local startWait = os.clock()

		while os.clock() - startWait < Constants.ORDER_EXPIRE_SEC do
			task.wait(0.5)
			if order.status == "ready" then
				waited = true
				break
			end
			if order.status == "error" then
				-- Employee messed up; order counts as expired
				break
			end
		end

		local waitSeconds = os.clock() - startWait

		if waited and order.status == "ready" then
			-- Eat briefly
			task.wait(2)
			-- Determine satisfaction
			local state
			if waitSeconds <= Constants.HAPPY_THRESHOLD_SEC then
				state = "happy"
			elseif waitSeconds <= Constants.NEUTRAL_THRESHOLD_SEC then
				state = "neutral"
			else
				state = "angry"
			end
			-- Earn money
			getMS().onDishServed(player, dishKey, waitSeconds, customerType)
			-- Reputation
			local delta = CustomerSpawner.reputationDelta(state)
			session.reputation = math.max(0.1, math.min(2.0, (session.reputation or 1) + delta))
		else
			-- Angry leave: get half pay for expired
			if order.status == "ready" or order.status == "pending" then
				-- No money on true expire
				session.reputation = math.max(0.1, (session.reputation or 1) - 0.15)
			end
		end

		-- Remove order from queue
		for i, o in ipairs(session.orderQueue) do
			if o.id == order.id then table.remove(session.orderQueue, i); break end
		end

		-- Remove customer from list and despawn
		for i, c in ipairs(session.customers) do
			if c == model then table.remove(session.customers, i); break end
		end
		model:Destroy()
	end)
end

-- ── Spawn loop per player ─────────────────────────────────────────────────────

local function startSpawnLoop(player, session, plotOrigin)
	task.spawn(function()
		while player and player.Parent do
			local data = getDP().get(player)
			if not data then task.wait(5); continue end

			local interval = CustomerSpawner.spawnInterval(data.level, session.reputation or 1)
			task.wait(interval)

			local customerType = CustomerSpawner.randomType()

			-- Entry at plot edge; table somewhere inside
			local entryPos = plotOrigin + Vector3.new(-12, 3, 0)
			local tablePos = plotOrigin + Vector3.new(
				math.random(-3, 3),
				0,
				math.random(-3, 3)
			)

			task.spawn(function()
				runCustomer(player, session, customerType, entryPos, tablePos)
			end)
		end
	end)
end

-- ── Player join/leave ──────────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
	local loadEvent = ReplicatedStorage:WaitForChild("DataLoaded_" .. player.UserId, 30)
	if not loadEvent then return end
	loadEvent.Event:Wait()

	local session = {
		customers   = {},
		orderQueue  = {},
		reputation  = 1.0,
	}
	playerSessions[player.UserId] = session

	-- Approximate plot origin (matches RestaurantManager.server.lua logic)
	local slot = (player.UserId % 20) * 35
	local plotOrigin = Vector3.new(slot, 0, 0)

	startSpawnLoop(player, session, plotOrigin)
end)

Players.PlayerRemoving:Connect(function(player)
	local session = playerSessions[player.UserId]
	if session then
		for _, c in ipairs(session.customers) do
			if c then c:Destroy() end
		end
	end
	playerSessions[player.UserId] = nil
end)

-- Expose queue so EmployeeAI can reference it
return {
	getSession = function(userId) return playerSessions[userId] end,
}
