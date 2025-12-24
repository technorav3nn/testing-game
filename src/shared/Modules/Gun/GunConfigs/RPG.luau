local Types = require("./_types")

local config: Types.GunConfig = {
	Type = "RocketLauncher",
	Damage = 80,
	Speed = 20,
	MaxSpreadAngle = 2,
	MinSpreadAngle = 0,
	FireRate = 1.5,
	ReloadTime = 3.5,
	MaxAmmo = 1,
	Ammo = 1,
	Range = 1500,
	ExplosionConfig = {
		RadiusCoefficient = 2.2,
		Radius = 12,
		Damage = 80,
	},
}

return config
