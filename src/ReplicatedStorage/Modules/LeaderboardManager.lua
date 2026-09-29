-- LeaderboardManager.lua (shared)
-- Types and display helpers. DataStore writes live server-side.

local LeaderboardManager = {}

local Constants = require(script.Parent.Constants)

LeaderboardManager.BOARDS = {
	TopEarners         = { label = "Top Earners (All-Time)",    stat = "totalEarned"   },
	WeeklyEarners      = { label = "Weekly Earners",            stat = "weeklyEarned"  },
	FastestProgression = { label = "Fastest Progression",       stat = "level"         },
	Efficiency         = { label = "Efficiency (profit/emp)",   stat = "efficiency"    },
}

-- Format a leaderboard row for UI display
function LeaderboardManager.formatRow(rank, username, value)
	return string.format("#%d  %-20s  %d", rank, username, value)
end

-- Badge thresholds
function LeaderboardManager.getBadge(rank)
	if rank == 1  then return "Champion" end
	if rank <= 10 then return "Elite"    end
	if rank <= 50 then return "Rising"   end
	return nil
end

return LeaderboardManager
