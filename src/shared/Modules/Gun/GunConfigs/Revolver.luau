local Types = require("./_types")

local config: Types.GunConfig = {
	Type = "Normal",
	Damage = 25,
	Speed = 1000,
	MaxSpreadAngle = 1,
	MinSpreadAngle = 0,
	FireRate = 0.5,
	ReloadTime = 2.6,
	MaxAmmo = 6,
	Ammo = 6,
	Range = 800,
	Sounds = {
		Fire = "",
		Empty = "rbxassetid://72489278445121",
		Reload = "rbxassetid://131821069882936",
	},
}

return config
