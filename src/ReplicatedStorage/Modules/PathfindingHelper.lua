-- PathfindingHelper.lua
-- Thin wrapper around Roblox PathfindingService.

local PathfindingHelper = {}

local PathfindingService = game:GetService("PathfindingService")
local RunService        = game:GetService("RunService")

local AGENT_PARAMS = {
	AgentHeight    = 5,
	AgentRadius    = 2,
	AgentCanJump   = false,
	AgentCanClimb  = false,
}

-- Move humanoid to target position.
-- onComplete(success) called when done or stuck.
function PathfindingHelper.moveTo(humanoid, rootPart, target, onComplete)
	local path = PathfindingService:CreatePath(AGENT_PARAMS)

	local ok, err = pcall(function()
		path:ComputeAsync(rootPart.Position, target)
	end)

	if not ok or path.Status ~= Enum.PathStatus.Success then
		if onComplete then onComplete(false) end
		return
	end

	local waypoints = path:GetWaypoints()
	local index = 2   -- skip start

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if index > #waypoints then
			conn:Disconnect()
			if onComplete then onComplete(true) end
			return
		end
		local wp = waypoints[index]
		humanoid:MoveTo(wp.Position)
		if (rootPart.Position - wp.Position).Magnitude < 3 then
			index = index + 1
		end
	end)

	-- Recompute if blocked
	path.Blocked:Connect(function(blockedIdx)
		if blockedIdx >= index then
			conn:Disconnect()
			PathfindingHelper.moveTo(humanoid, rootPart, target, onComplete)
		end
	end)

	return conn
end

-- Simple direct MoveTo for short distances (no pathfinding overhead)
function PathfindingHelper.moveToSimple(humanoid, target, onComplete)
	humanoid:MoveTo(target)
	local conn
	conn = humanoid.MoveToFinished:Connect(function(reached)
		conn:Disconnect()
		if onComplete then onComplete(reached) end
	end)
end

return PathfindingHelper
