-- CosmeticsSystem.lua (shared)
-- Unlock checks and equip helpers. Mutations go via server remotes.

local CosmeticsSystem = {}

local Constants = require(script.Parent.Constants)

function CosmeticsSystem.ownsTheme(playerData, themeKey)
	for _, t in ipairs(playerData.cosmetics.unlockedThemes) do
		if t == themeKey then return true end
	end
	return false
end

function CosmeticsSystem.equipTheme(playerData, themeKey)
	if CosmeticsSystem.ownsTheme(playerData, themeKey) then
		playerData.cosmetics.equippedTheme = themeKey
		return true
	end
	return false
end

function CosmeticsSystem.getThemeData(themeKey)
	return Constants.THEMES[themeKey] or Constants.THEMES["default"]
end

function CosmeticsSystem.ownsOutfit(playerData, outfitKey)
	for _, o in ipairs(playerData.cosmetics.unlockedOutfits) do
		if o == outfitKey then return true end
	end
	return false
end

function CosmeticsSystem.ownsSkin(playerData, skinKey)
	for _, s in ipairs(playerData.cosmetics.unlockedSkins) do
		if s == skinKey then return true end
	end
	return false
end

return CosmeticsSystem
