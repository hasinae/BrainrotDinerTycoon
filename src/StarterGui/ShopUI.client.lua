-- ShopUI.client.lua
-- Shop modal: Themes, Employees, Passes, Battle Pass, Subscribe.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Modules   = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules.Constants)

local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local HireEmployee  = Remotes:WaitForChild("HireEmployee")

-- ── Root GUI ──────────────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name  = "ShopUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent  = playerGui

local overlay = Instance.new("Frame")
overlay.Size  = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.BorderSizePixel = 0
overlay.Parent = screenGui

local panel = Instance.new("Frame")
panel.Size  = UDim2.new(0, 580, 0, 480)
panel.Position = UDim2.new(0.5, -290, 0.5, -240)
panel.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
panel.BorderSizePixel  = 0
panel.Parent = screenGui
do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = panel
end

local titleLabel = Instance.new("TextLabel")
titleLabel.Size  = UDim2.new(1, 0, 0, 44)
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
titleLabel.BorderSizePixel  = 0
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextSize   = 22
titleLabel.Font       = Enum.Font.GothamBold
titleLabel.Text       = "Shop"
titleLabel.Parent     = panel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,14); c.Parent = titleLabel end

local closeBtn = Instance.new("TextButton")
closeBtn.Size  = UDim2.new(0, 34, 0, 34)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel  = 0
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextSize   = 20
closeBtn.Font       = Enum.Font.GothamBold
closeBtn.Text       = "×"
closeBtn.Parent     = panel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = closeBtn end
closeBtn.MouseButton1Click:Connect(function() screenGui.Enabled = false end)

-- ── Tab bar ───────────────────────────────────────────────────────────────────

local TABS = { "Themes", "Employees", "Passes", "Battle Pass", "Subscribe" }
local tabBar = Instance.new("Frame")
tabBar.Size  = UDim2.new(1, -10, 0, 36)
tabBar.Position = UDim2.new(0, 5, 0, 48)
tabBar.BackgroundTransparency = 1
tabBar.BorderSizePixel = 0
tabBar.Parent = panel
do
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 4)
	layout.Parent  = tabBar
end

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size  = UDim2.new(1, -10, 1, -100)
contentFrame.Position = UDim2.new(0, 5, 0, 92)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 4
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.Parent = panel

local tabButtons = {}
local activeTab  = nil

local function clearContent()
	for _, child in ipairs(contentFrame:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

-- ── Content builders ──────────────────────────────────────────────────────────

local function addCard(parent, labelText, subText, btnText, btnColor, onClick)
	local card = Instance.new("Frame")
	card.Size  = UDim2.new(1, -8, 0, 72)
	card.BackgroundColor3 = Color3.fromRGB(38, 38, 58)
	card.BorderSizePixel  = 0
	card.Parent = parent
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = card end

	local lbl = Instance.new("TextLabel")
	lbl.Size  = UDim2.new(0.65, 0, 0.55, 0)
	lbl.Position = UDim2.new(0, 8, 0, 4)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(255,255,255)
	lbl.TextSize   = 15
	lbl.Font       = Enum.Font.GothamBold
	lbl.Text       = labelText
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = card

	local sub = Instance.new("TextLabel")
	sub.Size  = UDim2.new(0.65, 0, 0.38, 0)
	sub.Position = UDim2.new(0, 8, 0.6, 0)
	sub.BackgroundTransparency = 1
	sub.TextColor3 = Color3.fromRGB(160,160,180)
	sub.TextSize   = 12
	sub.Font       = Enum.Font.Gotham
	sub.Text       = subText
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Parent = card

	local btn = Instance.new("TextButton")
	btn.Size  = UDim2.new(0, 90, 0, 36)
	btn.Position = UDim2.new(1, -98, 0.5, -18)
	btn.BackgroundColor3 = btnColor or Color3.fromRGB(60, 120, 220)
	btn.BorderSizePixel  = 0
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.TextSize   = 14
	btn.Font       = Enum.Font.GothamBold
	btn.Text       = btnText
	btn.Parent = card
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = btn end
	btn.MouseButton1Click:Connect(onClick)

	return card
end

local function buildThemes()
	clearContent()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent  = contentFrame

	for key, theme in pairs(Constants.THEMES) do
		local priceText = theme.robux == 0 and "Free" or (theme.robux .. " R$")
		addCard(contentFrame, theme.name, priceText, "Buy", nil, function()
			-- In production: prompt MarketplaceService purchase
			-- MarketplaceService:PromptProductPurchase(player, PRODUCT_ID)
			print("[Shop] Theme purchase:", key, priceText)
		end)
	end

	contentFrame.CanvasSize = UDim2.new(0, 0, 0, #Constants.THEMES * 78 + 10)
end

local function buildEmployees()
	clearContent()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent  = contentFrame

	for key, emp in pairs(Constants.EMPLOYEES) do
		addCard(
			contentFrame,
			emp.displayName,
			emp.hireCost .. " IGC  •  " .. emp.salary .. " IGC/min",
			"Hire",
			Color3.fromRGB(60, 180, 80),
			function()
				HireEmployee:FireServer(key)
			end
		)
	end

	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 3 * 78 + 10)
end

local function buildPasses()
	clearContent()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent  = contentFrame

	local passes = {
		{ name = "Speedup Pass (1 wk)",  price = "250 R$", key = "speedup_week" },
		{ name = "Quick Expansion",       price = "75 R$",  key = "quick_expansion" },
		{ name = "500 IGC",               price = "35 R$",  key = "cash_small" },
		{ name = "1,500 IGC",             price = "75 R$",  key = "cash_medium" },
		{ name = "4,000 IGC",             price = "150 R$", key = "cash_large" },
		{ name = "Premium Speedup (perm)",price = "399 R$", key = "premium_speedup" },
		{ name = "Exec Chef Outfit",      price = "299 R$", key = "exec_chef_outfit" },
		{ name = "All Themes Pack",       price = "999 R$", key = "all_themes_pack" },
		{ name = "Premium Dish Pack",     price = "150 R$", key = "premium_dish_pack" },
	}

	for _, p in ipairs(passes) do
		local pk = p.key
		addCard(contentFrame, p.name, p.price, "Buy", nil, function()
			print("[Shop] Purchase:", pk)
		end)
	end

	contentFrame.CanvasSize = UDim2.new(0, 0, 0, #passes * 78 + 10)
end

local function buildBattlePass()
	clearContent()
	addCard(contentFrame, "Battle Pass", "350 R$ — Season 1  •  10 tiers of cosmetics", "Buy", nil, function()
		print("[Shop] Battle pass purchase")
	end)
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 82)
end

local function buildSubscribe()
	clearContent()
	addCard(
		contentFrame,
		"VIP Membership",
		"300 R$/month — 2× profit, speedup, exclusive cosmetics",
		"Subscribe",
		Color3.fromRGB(180, 130, 0),
		function()
			print("[Shop] VIP subscribe")
		end
	)
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 82)
end

local TAB_BUILDERS = {
	Themes      = buildThemes,
	Employees   = buildEmployees,
	Passes      = buildPasses,
	["Battle Pass"] = buildBattlePass,
	Subscribe   = buildSubscribe,
}

-- ── Create tab buttons ────────────────────────────────────────────────────────

local function selectTab(tabName)
	activeTab = tabName
	for name, btn in pairs(tabButtons) do
		if name == tabName then
			btn.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
		else
			btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		end
	end
	TAB_BUILDERS[tabName]()
end

for _, tabName in ipairs(TABS) do
	local btn = Instance.new("TextButton")
	btn.Size  = UDim2.new(0, 90, 1, 0)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	btn.BorderSizePixel  = 0
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.TextSize   = 13
	btn.Font       = Enum.Font.GothamBold
	btn.Text       = tabName
	btn.Parent     = tabBar
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = btn end

	tabButtons[tabName] = btn
	local tn = tabName
	btn.MouseButton1Click:Connect(function() selectTab(tn) end)
end

-- Select first tab by default
screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if screenGui.Enabled then
		selectTab("Employees")
	end
end)
