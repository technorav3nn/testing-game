local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TypeUtils = require(ReplicatedStorage.Modules.Utils.TypeUtils)

type keyof<T> = TypeUtils.keyof<T>

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

	Sounds: Sounds,
	ExplosionConfig: ExplosionConfig?,
}

export type ExplosionConfig = {
	RadiusCoefficient: number,
	Damage: number,
	Radius: number,
}

export type Sounds = {
	Fire: string?,
	Reload: string?,
	Empty: string?,
	-- Only for RPG weapons
	Flying: string?,
}

export type SoundTypes = keyof<Sounds>

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
	WeaponGUID = "WeaponGUID",
}

export type PossibleAttributes = keyof<typeof(possibleAttributes)>

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
