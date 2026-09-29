-- RestaurantManager.lua (shared)
-- Grid placement helpers, object validation, expansion checks.

local RestaurantManager = {}

local Constants = require(script.Parent.Constants)

-- ── Grid snap ──────────────────────────────────────────────────────────────
function RestaurantManager.snapToGrid(pos)
	local g = Constants.GRID_SIZE
	return Vector3.new(
		math.round(pos.X / g) * g,
		pos.Y,
		math.round(pos.Z / g) * g
	)
end

-- ── Bounds check ──────────────────────────────────────────────────────────
function RestaurantManager.isInBounds(pos, plotOrigin, expansionLevel)
	local size = Constants.EXPANSIONS[expansionLevel].size / 2
	local rel  = pos - plotOrigin
	return math.abs(rel.X) <= size and math.abs(rel.Z) <= size
end

-- ── Object cap check ──────────────────────────────────────────────────────
function RestaurantManager.canPlaceMore(currentCount, expansionLevel)
	return currentCount < Constants.EXPANSIONS[expansionLevel].maxObjects
end

-- ── Build cost ────────────────────────────────────────────────────────────
function RestaurantManager.getBuildCost(furnitureType)
	local entry = Constants.FURNITURE[furnitureType]
	return entry and entry.cost or 0
end

function RestaurantManager.getRefundAmount(furnitureType)
	local entry = Constants.FURNITURE[furnitureType]
	if not entry then return 0 end
	return math.floor(entry.cost * entry.refundRate)
end

-- ── Expansion cost ────────────────────────────────────────────────────────
function RestaurantManager.getExpansionCost(currentLevel)
	local next = Constants.EXPANSIONS[currentLevel + 1]
	return next and next.cost or nil
end

-- ── AABB overlap check (XZ plane) ─────────────────────────────────────────
-- partA, partB are tables {pos: Vector3, size: Vector3}
function RestaurantManager.overlaps(a, b)
	local ax1, ax2 = a.pos.X - a.size.X/2, a.pos.X + a.size.X/2
	local az1, az2 = a.pos.Z - a.size.Z/2, a.pos.Z + a.size.Z/2
	local bx1, bx2 = b.pos.X - b.size.X/2, b.pos.X + b.size.X/2
	local bz1, bz2 = b.pos.Z - b.size.Z/2, b.pos.Z + b.size.Z/2
	return ax1 < bx2 and ax2 > bx1 and az1 < bz2 and az2 > bz1
end

-- Rotate a size vector by 90° increments (n = 0/1/2/3)
function RestaurantManager.rotateSize(size, n)
	if n % 2 == 1 then
		return Vector3.new(size.Z, size.Y, size.X)
	end
	return size
end

return RestaurantManager
