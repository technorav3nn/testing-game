local Types = require("./_types")

local config: Types.GunConfig = {
	Type = "RPGWeapon",
	Damage = 80,
	Speed = 20,
	MaxSpreadAngle = 2,
	MinSpreadAngle = 0,
	FireRate = 1.5,
	ReloadTime = 3.5,
	MaxAmmo = 1,
	Ammo = 1,
	Range = 1500,
	Sounds = {
		Empty = "rbxassetid://72489278445121",
		Reload = "rbxassetid://132456167",
		Fire = "rbxassetid://132456187",
		-- Played on the rocket projectile while its flying
		Flying = "rbxassetid://3802262531",
	},
	ExplosionConfig = {
		RadiusCoefficient = 2.2,
		Radius = 12,
		Damage = 80,
	},
}

return config
