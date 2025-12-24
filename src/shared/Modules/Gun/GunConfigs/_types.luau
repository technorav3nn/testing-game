export type GunConfig = {
	Type: "Normal" | "Shotgun" | "RocketLauncher",
	Damage: number,
	Speed: number,
	MaxSpreadAngle: number,
	MinSpreadAngle: number,
	FireRate: number,
	MaxAmmo: number,
	Ammo: number,
	ReloadTime: number,
	Range: number,

	Sounds: {
		Fire: string?,
		Reload: string?,
		Empty: string?,
	},
	ExplosionConfig: ExplosionConfig?,
}

export type ExplosionConfig = {
	RadiusCoefficient: number,
	Damage: number,
	Radius: number,
}

local possibleProperties = {
	"Type",
	"Damage",
	"Speed",
	"MaxSpreadAngle",
	"MinSpreadAngle",
	"FireRate",
	"ReloadTime",
	"Ammo",
	"MaxAmmo",
	"Range",
	"IsReloading",
	"ExplosionConfig",
}

local possibleAttributes = {
	Damage = "Damage",
	Speed = "Speed",
	MaxSpreadAngle = "MaxSpreadAngle",
	MinSpreadAngle = "MinSpreadAngle",
	FireRate = "FireRate",
	ReloadTime = "ReloadTime",
	Ammo = "Ammo",
	MaxAmmo = "MaxAmmo",
	Range = "Range",
	-- Properties that arent to be configured:
	IsReloading = "IsReloading",
}

local unconfigurableAttributes = {
	IsReloading = {
		DefaultValue = false,
	},
}

local attributeIgnoreProperties = { ExplosionConfig = true }

return {
	possibleProperties = possibleProperties,
	possibleAttributes = possibleAttributes,
	unconfigurableAttributes = unconfigurableAttributes,
	attributeIgnoreProperties = attributeIgnoreProperties,
}
