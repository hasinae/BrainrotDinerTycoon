-- AntiCheat.server.lua
-- Sanity-checks incoming remote calls and flags suspicious patterns.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Track recent money-gain events per player to detect spam
local gainLog = {}   -- [userId] = { total = n, windowStart = t }

local WINDOW_SECONDS  = 10
local MAX_GAIN_WINDOW = 5000  -- max IGC earnable in 10 sec legitimately

local AntiCheat = {}

function AntiCheat.validateMoneyGain(player, amount)
	local now = os.time()
	local uid = player.UserId

	if not gainLog[uid] then
		gainLog[uid] = { total = 0, windowStart = now }
	end

	local log = gainLog[uid]
	if now - log.windowStart > WINDOW_SECONDS then
		log.total       = 0
		log.windowStart = now
	end

	log.total = log.total + amount

	if log.total > MAX_GAIN_WINDOW then
		warn("[AntiCheat] Suspicious gain from", player.Name, "total:", log.total, "in window")
		return false
	end

	return true
end

function AntiCheat.validateSpend(player, amount)
	if type(amount) ~= "number" then return false end
	if amount <= 0 or amount > 100000 then return false end
	if amount ~= math.floor(amount) then return false end  -- must be integer
	return true
end

function AntiCheat.validatePlacement(player, furnitureType, pos)
	if type(furnitureType) ~= "string" then return false end
	if typeof(pos) ~= "Vector3" then return false end
	-- Positions must be sane world coords
	if pos.Magnitude > 10000 then return false end
	return true
end

Players.PlayerRemoving:Connect(function(player)
	gainLog[player.UserId] = nil
end)

return AntiCheat
