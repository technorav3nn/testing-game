local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Guard = require(ReplicatedStorage.Packages._Index["red-blox_guard@1.0.1"].guard)
local Red = require(ReplicatedStorage.Packages.Red)
local Trove = require(ReplicatedStorage.Packages.Trove)

type WeaponsNetworkProps = {
	-- FUCKING "CIRCULAR DEPENDENCY" EVEN THOUGH THIS IS JUST A TYPE REFERENCE WHAT THE HELL LUAU
	-- THIS IS SO FUCKING STUPID >:(
	WeaponsSystem: any,
	FireWeapon: typeof(Red.Event({} :: any, {} :: any)),
	ReloadWeapon: typeof(Red.Event({} :: any, {} :: any)),
	_trove: typeof(Trove.new()),
	hasSetListeners: boolean,
}

local WeaponNetwork = {} :: WeaponsNetworkProps
WeaponNetwork.WeaponsSystem = nil
WeaponNetwork._trove = Trove.new()
WeaponNetwork.hasSetListeners = false

WeaponNetwork.FireWeapon = Red.Event("FireWeapon", function(instanceGuid, mousePos)
	return Guard.String(instanceGuid), Guard.Vector3(mousePos)
end)
do
	if RunService:IsServer() and not WeaponNetwork.hasSetListeners then
		WeaponNetwork.FireWeapon:Server():On(function(player: Player, guid: string, mousePos: Vector3)
			local WeaponsSystem = WeaponNetwork.WeaponsSystem
			if not WeaponsSystem then
				return
			end
			local weapon = WeaponsSystem.knownWeapons[guid]
			if weapon then
				weapon:OnFired(player, guid, mousePos)
			end
		end)
	end
end

WeaponNetwork.ReloadWeapon = Red.Event("ReloadWeapon", function(instanceGuid)
	return Guard.String(instanceGuid)
end)
do
	if RunService:IsServer() and not WeaponNetwork.hasSetListeners then
		WeaponNetwork.ReloadWeapon:Server():On(function(player: Player, guid: string)
			local WeaponsSystem = WeaponNetwork.WeaponsSystem
			if not WeaponsSystem then
				return
			end
			local weapon = WeaponsSystem.knownWeapons[guid]
			if weapon then
				print(weapon)
				weapon:OnReload(player, guid)
			end
		end)
	end
end

WeaponNetwork.hasSetListeners = true
return WeaponNetwork
