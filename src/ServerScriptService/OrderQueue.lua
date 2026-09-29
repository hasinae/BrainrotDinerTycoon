-- OrderQueue.lua (ModuleScript)
-- Shared order queue and customer session state; required by CustomerSystem and EmpAI.

local OrderQueue = {}
local sessions = {}   -- [userId] = { orders, customers, reputation }

local function ensureSession(userId)
	if not sessions[userId] then
		sessions[userId] = { orders = {}, customers = {}, reputation = 1.0 }
	end
	return sessions[userId]
end

function OrderQueue.getSession(userId)
	return ensureSession(userId)
end

function OrderQueue.addOrder(userId, order)
	table.insert(ensureSession(userId).orders, order)
end

function OrderQueue.removeOrder(userId, orderId)
	local s = sessions[userId]
	if not s then return end
	for i, o in ipairs(s.orders) do
		if o.id == orderId then table.remove(s.orders, i); return end
	end
end

-- Returns the next unclaimed pending order for a player's restaurant
function OrderQueue.getNextPending(userId)
	local s = sessions[userId]
	if not s then return nil end
	for _, o in ipairs(s.orders) do
		if o.status == "pending" and not o.assignedTo then
			return o
		end
	end
	return nil
end

function OrderQueue.addCustomer(userId, model)
	table.insert(ensureSession(userId).customers, model)
end

function OrderQueue.removeCustomer(userId, model)
	local s = sessions[userId]
	if not s then return end
	for i, c in ipairs(s.customers) do
		if c == model then table.remove(s.customers, i); return end
	end
end

function OrderQueue.cleanup(userId)
	local s = sessions[userId]
	if s then
		for _, c in ipairs(s.customers) do
			pcall(function() if c then c:Destroy() end end)
		end
	end
	sessions[userId] = nil
end

return OrderQueue
