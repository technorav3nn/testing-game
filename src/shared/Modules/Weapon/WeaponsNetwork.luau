local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Network = require(ReplicatedStorage.Network)
local Trove = require(ReplicatedStorage.Packages.Trove)

type WeaponsNetworkProps = {
	-- FUCKING "CIRCULAR DEPENDENCY" EVEN THOUGH THIS IS JUST A TYPE REFERENCE WHAT THE HELL LUAU
	-- THIS IS SO FUCKING STUPID >:(
	WeaponsSystem: any,
	_trove: typeof(Trove.new()),
	hasSetListeners: boolean,
	remotes: typeof(Network.weaponSystem),
}

local WeaponNetwork = {
	WeaponsSystem = nil,
	_trove = Trove.new(),
	hasSetListeners = false,
	remotes = Network.weaponSystem,
} :: WeaponsNetworkProps

do
	if RunService:IsServer() and not WeaponNetwork.hasSetListeners then
		Network.weaponSystem.FireWeapon:connect(function(player: Player, guid: string, mousePos: Vector3)
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

do
	if RunService:IsServer() and not WeaponNetwork.hasSetListeners then
		Network.weaponSystem.ReloadWeapon:connect(function(player: Player, guid: string)
			local WeaponsSystem = WeaponNetwork.WeaponsSystem
			if not WeaponsSystem then
				return
			end
			local weapon = WeaponsSystem.knownWeapons[guid]
			if weapon then
				weapon:OnReload(player, guid)
			end
		end)
	end
end

WeaponNetwork.hasSetListeners = true
return WeaponNetwork
