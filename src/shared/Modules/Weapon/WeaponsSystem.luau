local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPack = game:GetService("StarterPack")

local _BulletWeapon = require("./WeaponTypes/BulletWeapon/BulletWeapon")
local _RPGWeapon = require("./WeaponTypes/RPGWeapon/RPGWeapon")

type Weapon = _BulletWeapon.BulletWeapon

local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local vide = require(ReplicatedStorage.Packages.Vide)

local isServer = RunService:IsServer()

local WEAPON_TAG = "WEAPON_SYSTEM_WEAPON"

local WEAPON_TYPES = {} :: { [string]: any }
do
	local weaponTypesModulePath = script.Parent.WeaponTypes
	for _, weaponType in weaponTypesModulePath:GetChildren() do
		WEAPON_TYPES[weaponType.Name] = require(weaponType:FindFirstChild(weaponType.Name)) :: any
	end
end

type WeaponsSystemProps = {
	knownWeapons: { [string]: Weapon },
	isSetup: boolean,
	isSetupLoading: boolean,
	currentWeapon: Weapon?,
	cleanupVide: (() -> ())?,
	_trove: typeof(Trove.new()),

	CurrentWeaponChanged: Signal.Signal<Instance?, Instance?>,

	Setup: () -> (),

	Shutdown: () -> (),
	GetTypeFromTags: (instance: Instance) -> Weapon?,
	CreateWeaponForInstance: (weaponInstance: Instance) -> (),
	GetWeaponForInstance: (weaponInstance: Instance) -> Weapon | nil,
	SetWeaponEquipped: (weapon: Weapon?, equipped: boolean) -> (),

	OnCharacterAdded: (character: Model) -> (),
	OnWeaponAdded: (weaponInstance: Instance) -> (),
	OnWeaponRemoved: (weaponInstance: Instance) -> (),
	OnFireWeaponInvoke: (player: Player, mousePos: Vector3) -> (),
}

local WeaponsSystem = {} :: WeaponsSystemProps

WeaponsSystem.knownWeapons = {} :: { [string]: Weapon }
WeaponsSystem.isSetup = false
WeaponsSystem.isSetupLoading = false
WeaponsSystem.currentWeapon = nil
WeaponsSystem.cleanupVide = nil
WeaponsSystem._trove = Trove.new()

WeaponsSystem.CurrentWeaponChanged = Signal.new() :: Signal.Signal<Instance?, Instance?>

local WeaponsNetwork = require(script.Parent:FindFirstChild("WeaponsNetwork"))
WeaponsNetwork.WeaponsSystem = WeaponsSystem

function WeaponsSystem.Setup()
	if WeaponsSystem.isSetup then
		warn("Warning: trying to run WeaponsSystem setup twice on the same module.")
		return
	end

	WeaponsSystem.isSetupLoading = true

	if isServer then
		require("./WeaponsNetwork")
	else
		Players.LocalPlayer.CharacterAdded:Connect(WeaponsSystem.OnCharacterAdded)
		if Players.LocalPlayer.Character then
			WeaponsSystem.OnCharacterAdded(Players.LocalPlayer.Character :: Model)
		end
		local App = require("./UI/App")
		WeaponsSystem.cleanupVide = vide.mount(App, Players.LocalPlayer:WaitForChild("PlayerGui"))
	end

	WeaponsSystem._trove:Add(CollectionService:GetInstanceAddedSignal(WEAPON_TAG):Connect(WeaponsSystem.OnWeaponAdded))
	WeaponsSystem._trove:Add(
		CollectionService:GetInstanceRemovedSignal(WEAPON_TAG):Connect(WeaponsSystem.OnWeaponRemoved)
	)

	for _, instance in pairs(CollectionService:GetTagged(WEAPON_TAG)) do
		WeaponsSystem.OnWeaponAdded(instance)
	end

	WeaponsSystem.isSetupLoading = false
	WeaponsSystem.isSetup = true
end

function WeaponsSystem.Shutdown()
	print("Shutting down WeaponsSystem...")
	if not WeaponsSystem.isSetup then
		return
	end

	-- TODO: typecheck weapons
	for _, weapon in pairs(WeaponsSystem.knownWeapons) do
		(weapon :: _BulletWeapon.BulletWeapon):OnDestroyed()
	end
	if RunService:IsClient() then
		if WeaponsSystem.cleanupVide then
			WeaponsSystem.cleanupVide()
			WeaponsSystem.cleanupVide = nil
			Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("WeaponsSystemDisplay"):Destroy()
		end
	end
	WeaponsSystem.knownWeapons = {}
	WeaponsSystem._trove:Destroy()
end

function WeaponsSystem.GetTypeFromTags(instance: Instance)
	for _, tag in pairs(CollectionService:GetTags(instance)) do
		local weaponTypeFound = WEAPON_TYPES[tag]
		if weaponTypeFound then
			return weaponTypeFound
		end
	end

	return nil
end

function WeaponsSystem.CreateWeaponForInstance(weaponInstance)
	if weaponInstance:FindFirstAncestor("Assets") then
		-- Don't create weapons for assets in the Assets folder
		return
	end

	task.spawn(function()
		local weaponType = WeaponsSystem.GetTypeFromTags(weaponInstance)
		if not weaponType then
			local weaponTypeName = weaponInstance:GetAttribute("WeaponType") :: string

			if weaponTypeName then
				local weaponTypeFound = WEAPON_TYPES[weaponTypeName]
				if not weaponTypeFound then
					warn(
						string.format(
							'Cannot find the weapon type "%s" for the instance %s!',
							weaponTypeName,
							weaponInstance:GetFullName()
						)
					)
					return
				end

				weaponType = weaponTypeFound
			else
				warn("Could not find a WeaponType tag or StringValue for the instance ", weaponInstance:GetFullName())
				return
			end
		end

		-- Since we might have yielded while trying to get the WeaponType, we need to make sure not to continue
		-- making a new weapon if something else beat this iteration.
		if WeaponsSystem.GetWeaponForInstance(weaponInstance) then
			warn("Already got ", weaponInstance:GetFullName())
			warn(debug.traceback())
			return
		end

		-- We should be pretty sure we got a valid weaponType by now
		assert(weaponType, "Got invalid weaponType")
		local player = weaponInstance:FindFirstAncestorWhichIsA("Player")
		if not player then
			warn(
				"WeaponsSystem.createWeaponForInstance: Could not find player for weapon instance ",
				weaponInstance:GetFullName()
			)
			return
		end

		if isServer then
			local guid = HttpService:GenerateGUID(false)
			weaponInstance:SetAttribute("WeaponGUID", guid)
		end
		local guid = weaponInstance:GetAttribute("WeaponGUID") :: string

		local castWeaponType = weaponType :: _BulletWeapon.BulletWeapon
		local weapon = castWeaponType.new({
			weaponInstance = weaponInstance :: Tool,
		})
		WeaponsSystem.knownWeapons[guid] = (weapon :: any) :: Weapon
	end)
end

function WeaponsSystem.SetWeaponEquipped(weapon: Weapon?, equipped: boolean)
	assert(not isServer, "WeaponsSystem.setWeaponEquipped should only be called on the client.")
	if not weapon then
		return
	end

	local lastWeapon = WeaponsSystem.currentWeapon
	-- local hasWeapon = false
	local weaponChanged = false

	if lastWeapon == weapon then
		if not equipped then
			WeaponsSystem.currentWeapon = nil
			-- hasWeapon = false
			weaponChanged = true
		else
			weaponChanged = false
		end
	else
		if equipped then
			WeaponsSystem.currentWeapon = weapon
			-- hasWeapon = true
			weaponChanged = true
		end
	end

	if weaponChanged then
		local gui = Players.LocalPlayer.PlayerGui:FindFirstChild("WeaponsSystemDisplay") :: ScreenGui

		local tool = (Players.LocalPlayer.Character :: Model):FindFirstChildOfClass("Tool")
		if not tool or not tool:GetAttribute("WeaponType") then
			assert(gui, "WeaponsSystem.setWeaponEquipped: Could not find WeaponsSystemDisplay GUI.")
			gui.Enabled = false
		else
			assert(gui, "WeaponsSystem.setWeaponEquipped: Could not find WeaponsSystemDisplay GUI.")
			gui.Enabled = true
		end
		WeaponsSystem.CurrentWeaponChanged:Fire(weapon.weaponInstance, lastWeapon and lastWeapon.weaponInstance)
	end
end

function WeaponsSystem.GetWeaponForInstance(weaponInstance): Weapon?
	if not (typeof(weaponInstance) == "Instance") then
		warn("WeaponsSystem.getWeaponForInstance(weaponInstance): 'weaponInstance' was not an instance.")
		return nil
	end
	local guid = (weaponInstance:GetAttribute("WeaponGUID") or "") :: string

	return WeaponsSystem.knownWeapons[guid]
end

function WeaponsSystem.OnCharacterAdded(_character: Model)
	local gui = Players.LocalPlayer.PlayerGui:FindFirstChild("WeaponsSystemDisplay") :: ScreenGui
	if gui then
		gui.Enabled = false
	end
end

function WeaponsSystem.OnWeaponAdded(weaponInstance: Instance)
	if weaponInstance.Parent == StarterPack then
		return
	end
	local weapon = WeaponsSystem.GetWeaponForInstance(weaponInstance)

	if not weapon then
		WeaponsSystem.CreateWeaponForInstance(weaponInstance)
	end
end

function WeaponsSystem.OnWeaponRemoved(weaponInstance: Instance)
	local weapon = WeaponsSystem.GetWeaponForInstance(weaponInstance)
	if weapon then
		weapon:OnDestroyed()
	end
	local guid = weaponInstance:GetAttribute("WeaponGUID") :: string
	if not guid then
		return
	end
	WeaponsSystem.knownWeapons[guid] = nil
end

function WeaponsSystem.OnFireWeaponInvoke(_player: Player, _mousePos: Vector3) end

return WeaponsSystem
