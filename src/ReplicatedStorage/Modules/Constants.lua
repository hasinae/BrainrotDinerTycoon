-- Constants.lua
-- All game-wide config values, prices, and stats

local Constants = {}

-- ─── Currency ───────────────────────────────────────────────────────────────
Constants.STARTING_IGC = 500

-- ─── Plot / Expansion ────────────────────────────────────────────────────────
Constants.EXPANSIONS = {
	{ size = 10, maxObjects = 25,  cost = 0    },
	{ size = 15, maxObjects = 50,  cost = 500  },
	{ size = 20, maxObjects = 80,  cost = 1500 },
	{ size = 25, maxObjects = 120, cost = 3000 },
}

-- ─── Furniture Costs (IGC) ───────────────────────────────────────────────────
Constants.FURNITURE = {
	KitchenCounter  = { cost = 50,  refundRate = 0.5 },
	DiningTable     = { cost = 30,  refundRate = 0.5 },
	CashierStation  = { cost = 40,  refundRate = 0.5 },
	TrashBin        = { cost = 20,  refundRate = 0.5 },
	Door            = { cost = 25,  refundRate = 0.5 },
	Wall            = { cost = 5,   refundRate = 0.5 },
	FloorTile       = { cost = 2,   refundRate = 0.5 },
}

-- ─── Restaurant Themes ───────────────────────────────────────────────────────
Constants.THEMES = {
	default    = { name = "Default",                   robux = 0,   color = Color3.fromRGB(220,210,200) },
	skibidi    = { name = "Skibidi Sewer Diner",       robux = 250, color = Color3.fromRGB(60, 100, 70) },
	sigma      = { name = "Sigma Corporate Steakhouse",robux = 300, color = Color3.fromRGB(180,180,190) },
	npc        = { name = "NPC Strip Mall Café",       robux = 250, color = Color3.fromRGB(210,200,180) },
	gyatt      = { name = "Gyatt Pink Velvet",         robux = 300, color = Color3.fromRGB(255,105,180) },
	y2k        = { name = "Y2K Internet Café",         robux = 350, color = Color3.fromRGB(0,  200,255) },
}

-- ─── Employees ───────────────────────────────────────────────────────────────
Constants.EMPLOYEES = {
	tung_tung_sahur = {
		displayName  = "Tung Tung Sahur",
		hireCost     = 100,
		salary       = 5,        -- IGC/minute
		speedMult    = 1.2,
		errorChance  = 0.20,     -- 20% per task
		maxPerRestaurant = 8,
		freezeChance = 0,
		quotes = {
			"just grinding", "alpha move", "that's cap",
			"no cap fr fr", "sigma mindset",
		},
	},
	tralalero_tralala = {
		displayName  = "Tralalero Tralala",
		hireCost     = 75,
		salary       = 3,
		speedMult    = 0.8,
		errorChance  = 0,
		maxPerRestaurant = 10,
		freezeChance = 0.10,     -- 10% chance to freeze each tick
		quotes = { "huh?", "okay", "yeah" },
	},
	ballerina_cappuccina = {
		displayName  = "Ballerina Cappuccina",
		hireCost     = 80,
		salary       = 4,
		speedMult    = 1.1,
		errorChance  = 0,
		maxPerRestaurant = 6,
		freezeChance = 0,
		varianceMin  = 0.5,      -- can be 0.5x to 2x speed randomly
		varianceMax  = 2.0,
		quotes = {},
	},
}

-- ─── Dishes ──────────────────────────────────────────────────────────────────
Constants.DISHES = {
	-- Free dishes
	pizza           = { name = "Pizza",             cookTime = 3,  price = 15, premium = false },
	hamburger       = { name = "Hamburger",         cookTime = 2,  price = 12, premium = false },
	spaghetti       = { name = "Spaghetti",         cookTime = 4,  price = 18, premium = false },
	skibidi_soup    = { name = "Skibidi Soup",      cookTime = 5,  price = 20, premium = false },
	sigma_steak     = { name = "Sigma Steak",       cookTime = 6,  price = 25, premium = false },
	npc_noodles     = { name = "NPC Noodles",       cookTime = 3,  price = 14, premium = false },
	gyatt_chicken   = { name = "Gyatt Chicken",     cookTime = 4,  price = 19, premium = false },
	rizz_ramen      = { name = "Rizz Ramen",        cookTime = 5,  price = 22, premium = false },
	brainrot_salad  = { name = "Brain Rot Salad",   cookTime = 2,  price = 11, premium = false },
	glitch_tacos    = { name = "Glitch Tacos",      cookTime = 3,  price = 16, premium = false },
	-- Premium dishes (Premium Dish Pack, 150 R$)
	sigma_caviar      = { name = "Sigma Caviar",          cookTime = 10, price = 50, premium = true },
	ancient_npc_gruel = { name = "Ancient NPC Gruel",     cookTime = 7,  price = 28, premium = true },
	blessed_sushi     = { name = "Blessed Skibidi Sushi", cookTime = 8,  price = 35, premium = true },
	gyatt_parfait     = { name = "Gyatt Parfait",         cookTime = 4,  price = 24, premium = true },
	cursed_boba       = { name = "Cursed Boba Tea",       cookTime = 3,  price = 20, premium = true },
}

-- ─── Customers ───────────────────────────────────────────────────────────────
Constants.CUSTOMER_TYPES = {
	regular  = { tipMult = 1.0,  impatience = 1.0 },
	sigma    = { tipMult = 1.5,  impatience = 2.0 },
	npc      = { tipMult = 0.0,  impatience = 0.5 },
	skibidi  = { tipMult = math.random, impatience = 0.5 }, -- tipMult resolved at runtime 0-2
}

Constants.CUSTOMER_HAPPY_TIP    = 0.25   -- +25% dish value
Constants.CUSTOMER_ANGRY_REDUCE = 0.50   -- pay 50% only
Constants.HAPPY_THRESHOLD_SEC   = 8
Constants.NEUTRAL_THRESHOLD_SEC = 20
Constants.ORDER_EXPIRE_SEC      = 30

Constants.SPAWN_BASE_INTERVAL   = 8   -- seconds between spawns
Constants.SPAWN_MIN_INTERVAL    = 3
Constants.MAX_CONCURRENT_CUSTOMERS = 20

-- ─── Leveling ────────────────────────────────────────────────────────────────
Constants.DISHES_PER_LEVEL = 10

Constants.MILESTONES = {
	{ dishes = 100,  igcReward = 500   },
	{ dishes = 500,  igcReward = 2000  },
	{ dishes = 1000, igcReward = 5000  },
	{ dishes = 5000, igcReward = 15000 },
}

-- ─── Shop / Monetization ─────────────────────────────────────────────────────
Constants.SHOP = {
	speedup_week       = { name = "Speedup Pass (1 wk)",    robux = 250,  type = "devproduct" },
	quick_expansion    = { name = "Quick Expansion",         robux = 75,   type = "devproduct" },
	cash_small         = { name = "500 IGC",                 robux = 35,   type = "devproduct", igc = 500   },
	cash_medium        = { name = "1,500 IGC",               robux = 75,   type = "devproduct", igc = 1500  },
	cash_large         = { name = "4,000 IGC",               robux = 150,  type = "devproduct", igc = 4000  },
	premium_speedup    = { name = "Premium Speedup",         robux = 399,  type = "gamepass"   },
	exec_chef_outfit   = { name = "Executive Chef Outfit",   robux = 299,  type = "gamepass"   },
	all_themes_pack    = { name = "All Themes Pack",         robux = 999,  type = "gamepass"   },
	vip                = { name = "VIP Membership",          robux = 300,  type = "subscription"},
	battle_pass        = { name = "Battle Pass",             robux = 350,  type = "battlepass" },
	premium_dish_pack  = { name = "Premium Dish Pack",       robux = 150,  type = "gamepass"   },
}

-- ─── Leaderboard Keys ────────────────────────────────────────────────────────
Constants.LEADERBOARD_KEYS = {
	"TopEarners",
	"WeeklyEarners",
	"FastestProgression",
	"Efficiency",
}

-- ─── Auto-save interval ──────────────────────────────────────────────────────
Constants.AUTOSAVE_INTERVAL = 30  -- seconds

-- ─── Grid snap ───────────────────────────────────────────────────────────────
Constants.GRID_SIZE = 0.5  -- studs

return Constants
