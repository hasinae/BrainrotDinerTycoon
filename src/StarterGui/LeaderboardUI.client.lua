-- LeaderboardUI.client.lua  (LocalScript)
-- Shows top earners in this session.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GOLD    = Color3.fromRGB(255, 200, 0)
local DARK_BG = Color3.fromRGB(12, 8, 22)
local CARD_BG = Color3.fromRGB(28, 16, 46)
local HOT_PINK= Color3.fromRGB(255, 20, 147)

local function corner(p, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = p
end
local function stroke(p, col, t)
	local s = Instance.new("UIStroke"); s.Color = col or GOLD; s.Thickness = t or 2; s.Parent = p
end

local screen = Instance.new("ScreenGui")
screen.Name           = "LeaderboardUI"
screen.ResetOnSpawn   = false
screen.IgnoreGuiInset = true
screen.Enabled        = false
screen.Parent         = playerGui

local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1,0,1,0)
overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = 0.55
overlay.BorderSizePixel = 0
overlay.ZIndex = 1
overlay.Parent = screen
overlay.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		screen.Enabled = false
	end
end)

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0,400,0,440)
panel.Position = UDim2.new(0.5,-200,0.5,-220)
panel.BackgroundColor3 = DARK_BG
panel.BorderSizePixel = 0
panel.ZIndex = 2
panel.Parent = screen
corner(panel, 16)
stroke(panel, GOLD, 2)

local hdr = Instance.new("Frame")
hdr.Size = UDim2.new(1,0,0,52)
hdr.BackgroundColor3 = GOLD
hdr.BorderSizePixel = 0
hdr.ZIndex = 3
hdr.Parent = panel
corner(hdr, 14)
local hdrFix = Instance.new("Frame")
hdrFix.Size = UDim2.new(1,0,0.5,0)
hdrFix.Position = UDim2.new(0,0,0.5,0)
hdrFix.BackgroundColor3 = GOLD
hdrFix.BorderSizePixel = 0
hdrFix.ZIndex = 3
hdrFix.Parent = hdr

local hdrL = Instance.new("TextLabel")
hdrL.Size = UDim2.new(1,-60,1,0)
hdrL.Position = UDim2.new(0,16,0,0)
hdrL.BackgroundTransparency = 1
hdrL.Text = "🏆  LEADERBOARD"
hdrL.TextSize = 22
hdrL.TextColor3 = Color3.fromRGB(20,10,0)
hdrL.Font = Enum.Font.GothamBlack
hdrL.TextXAlignment = Enum.TextXAlignment.Left
hdrL.ZIndex = 4
hdrL.Parent = hdr

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,40,0,40)
closeBtn.Position = UDim2.new(1,-48,0,6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200,40,40)
closeBtn.BorderSizePixel = 0
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.Text = "✕"
closeBtn.ZIndex = 5
closeBtn.Parent = hdr
corner(closeBtn, 8)
closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)

local content = Instance.new("Frame")
content.Size = UDim2.new(1,-16,1,-68)
content.Position = UDim2.new(0,8,0,60)
content.BackgroundTransparency = 1
content.ZIndex = 3
content.Parent = panel

local listL = Instance.new("UIListLayout")
listL.Padding = UDim.new(0,6)
listL.Parent = content

-- Populate with current session players
local medals = {"🥇","🥈","🥉","4.","5."}
local allPlayers = Players:GetPlayers()
table.sort(allPlayers, function(a, b) return a.Name < b.Name end) -- placeholder sort

for i, p in ipairs(allPlayers) do
	if i > 5 then break end
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1,0,0,56)
	row.BackgroundColor3 = CARD_BG
	row.BorderSizePixel = 0
	row.ZIndex = 4
	row.Parent = content
	corner(row, 10)
	if i == 1 then stroke(row, GOLD, 2) end

	local rank = Instance.new("TextLabel")
	rank.Size = UDim2.new(0,44,1,0)
	rank.Position = UDim2.new(0,8,0,0)
	rank.BackgroundTransparency = 1
	rank.Text = medals[i] or tostring(i).."."
	rank.TextSize = 22
	rank.TextColor3 = i==1 and GOLD or Color3.new(1,1,1)
	rank.Font = Enum.Font.GothamBlack
	rank.ZIndex = 5
	rank.Parent = row

	local nameL = Instance.new("TextLabel")
	nameL.Size = UDim2.new(0.6,0,1,0)
	nameL.Position = UDim2.new(0,56,0,0)
	nameL.BackgroundTransparency = 1
	nameL.Text = p.Name
	nameL.TextSize = 16
	nameL.TextColor3 = Color3.new(1,1,1)
	nameL.Font = Enum.Font.GothamBold
	nameL.TextXAlignment = Enum.TextXAlignment.Left
	nameL.ZIndex = 5
	nameL.Parent = row
end

if #allPlayers == 0 then
	local emptyL = Instance.new("TextLabel")
	emptyL.Size = UDim2.new(1,0,0,60)
	emptyL.BackgroundTransparency = 1
	emptyL.Text = "No other players online.\nBe the first diner tycoon! 🍔"
	emptyL.TextSize = 14
	emptyL.TextColor3 = Color3.fromRGB(160,140,190)
	emptyL.Font = Enum.Font.Gotham
	emptyL.TextWrapped = true
	emptyL.ZIndex = 4
	emptyL.Parent = content
end
