local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

if RunService:IsServer() then
	error("Store UI should not be required on the server")
end

local Charm = require(ReplicatedStorage.Packages.Charm)
local Trove = require(ReplicatedStorage.Packages.Trove)

local atom = Charm.atom

local currentAmmoAtom = atom(nil :: number?)
local totalAmmoAtom = atom(nil :: number?)
local isReloadingAtom = atom(false)
local currentWeaponNameAtom = atom("" :: string)

local trove = Trove.new()

local function setupStore() end

local function cleanupStore()
	trove:Destroy()
end

return {
	currentAmmoAtom = currentAmmoAtom,
	totalAmmoAtom = totalAmmoAtom,
	isReloadingAtom = isReloadingAtom,
	currentWeaponNameAtom = currentWeaponNameAtom,

	setupStore = setupStore,
	cleanupStore = cleanupStore,
}
