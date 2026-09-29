-- EmployeeAI.server.lua
-- Spawns employee NPCs and drives their task AI loop.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

local Modules          = ReplicatedStorage:WaitForChild("Modules")
local EmployeeManager  = require(Modules.EmployeeManager)
local PathfindingHelper= require(Modules.PathfindingHelper)
local Constants        = require(Modules.Constants)

-- Table: [player.UserId] = { [empId] = { model, taskState, ... } }
local activeEmployees = {}

-- Tasks a character cycles through in priority order
local TASK_PRIORITY = { "cook", "serve", "clean", "restock", "idle" }

-- ── Spawn an employee model ───────────────────────────────────────────────────

local function spawnEmployee(player, empData, plotOrigin)
	local templateName = empData.type  -- e.g. "tung_tung_sahur"
	local templates = ServerStorage:FindFirstChild("EmployeeModels")
	local template  = templates and templates:FindFirstChild(templateName)

	local model
	if template then
		model = template:Clone()
	else
		-- Fallback: plain humanoid rig
		model          = Instance.new("Model")
		local root     = Instance.new("Part")
		root.Name      = "HumanoidRootPart"
		root.Size      = Vector3.new(2, 2, 1)
		root.Anchored  = false
		root.Parent    = model
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent= model
		model.PrimaryPart = root
	end

	model.Name   = empData.name or empData.type
	model.Parent = workspace

	-- Place at break room (near plot origin, slightly offset)
	local spawnPos = plotOrigin + Vector3.new(0, 3, -8)
	model:PivotTo(CFrame.new(spawnPos))

	return model
end

-- ── Per-employee AI loop ──────────────────────────────────────────────────────

local function runEmployeeLoop(player, empId, model, empData, plotOrigin, orderQueue, readyZonePos)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root     = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end

	local cfg = Constants.EMPLOYEES[empData.type]

	while model and model.Parent do
		-- Salary deducted by GameLoop per minute; AI just runs tasks

		-- Check freeze (Tralalero)
		if EmployeeManager.rollFreeze(empData.type) then
			task.wait(math.random(3, 8))
			continue
		end

		-- Random break
		if math.random() < 0.05 then
			humanoid.WalkSpeed = 0
			task.wait(math.random(5, 15))
			humanoid.WalkSpeed = 16
		end

		-- Grab next order from queue
		local order = nil
		for i, o in ipairs(orderQueue) do
			if not o.assignedTo then
				o.assignedTo = empId
				order = o
				break
			end
		end

		if order then
			-- Walk to kitchen counter
			local hasVIP  = false  -- simplified; full check in MoneySystem
			local speed   = EmployeeManager.effectiveSpeed(empData.type, hasVIP, false, false)
			humanoid.WalkSpeed = 16 * speed

			PathfindingHelper.moveToSimple(humanoid, plotOrigin + Vector3.new(0, 3, 0), function()
				-- Simulate cooking
				local cookTime = (order.cookTime or 3) / speed
				task.wait(cookTime)

				-- Error roll
				if EmployeeManager.rollError(empData.type) then
					-- Dish burned: remove order without reward
					order.status = "error"
					-- Occasional voice line
					local quote = EmployeeManager.getQuote(empData.type)
					if quote then
						-- Could display in a BillboardGui here
					end
				else
					order.status = "ready"
					order.readyAt = os.clock()
				end
				order.assignedTo = nil
			end)
		else
			-- Return to break room idle
			humanoid.WalkSpeed = 10
			PathfindingHelper.moveToSimple(humanoid, plotOrigin + Vector3.new(0, 3, -8), function() end)
			task.wait(2)
		end

		task.wait(0.5)
	end
end

-- ── Public API ────────────────────────────────────────────────────────────────

local EmployeeAI = {}

function EmployeeAI.spawnForPlayer(player, empData, plotOrigin, orderQueue)
	if not activeEmployees[player.UserId] then
		activeEmployees[player.UserId] = {}
	end
	local model = spawnEmployee(player, empData, plotOrigin)
	activeEmployees[player.UserId][empData.id] = { model = model, data = empData }

	task.spawn(function()
		runEmployeeLoop(player, empData.id, model, empData, plotOrigin, orderQueue, plotOrigin + Vector3.new(4, 3, 0))
	end)

	return model
end

function EmployeeAI.fireEmployee(player, empId)
	local table = activeEmployees[player.UserId]
	if not table or not table[empId] then return end
	local entry = table[empId]
	if entry.model then entry.model:Destroy() end
	table[empId] = nil
end

function EmployeeAI.despawnAll(player)
	local tbl = activeEmployees[player.UserId]
	if not tbl then return end
	for _, entry in pairs(tbl) do
		if entry.model then entry.model:Destroy() end
	end
	activeEmployees[player.UserId] = nil
end

Players.PlayerRemoving:Connect(function(player)
	EmployeeAI.despawnAll(player)
end)

return EmployeeAI
