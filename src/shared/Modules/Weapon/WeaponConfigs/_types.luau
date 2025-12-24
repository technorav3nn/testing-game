export type GunConfig = {
	Type: "BulletWeapon" | "RPGWeapon",
	Damage: number,
	Speed: number,
	MaxSpreadAngle: number,
	MinSpreadAngle: number,
	FireRate: number,
	MaxAmmo: number,
	ReloadTime: number,
	Range: number,

	Sounds: {
		Fire: string?,
		Reload: string?,
		Empty: string?,
		-- Only for RPG weapons
		Flying: string?,
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
	AmmoInMagazine = "AmmoInMagazine",
	TotalAmmo = "TotalAmmo",
	IsReloading = "IsReloading",
}

export type PossibleAttributes = "AmmoInMagazine" | "TotalAmmo" | "IsReloading" | "WeaponGUID"

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
