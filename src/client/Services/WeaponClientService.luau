local ReplicatedStorage = game:GetService("ReplicatedStorage")

local weaponsSystemModule = ReplicatedStorage.Modules.Weapon.WeaponsSystem

local WeaponClientManager = {}

function WeaponClientManager.OnStart()
	local WeaponsSystem = require(weaponsSystemModule)
	if not WeaponsSystem.isSetupLoading and not WeaponsSystem.isSetup then
		WeaponsSystem.Setup()
	end
end

return WeaponClientManager
