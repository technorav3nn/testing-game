local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ConfigTypes = require("./WeaponConfigs/_types")
local Trove = require(ReplicatedStorage.Packages.Trove)

local WeaponNetwork = require("./WeaponsNetwork")

local configs = {}
do
	for _, configModule in ipairs(script.Parent.WeaponConfigs:GetChildren()) do
		if configModule:IsA("ModuleScript") then
			local config = require(configModule) :: ConfigTypes.GunConfig
			configs[configModule.Name] = config
		end
	end
end

type WeaponUtilsProps = {
	weaponInstance: Tool,
	configs: { [string]: ConfigTypes.GunConfig },
	config: ConfigTypes.GunConfig,
	_trove: typeof(Trove.new()),
	weapon: any,
}

local WeaponUtils = {}
WeaponUtils.__index = WeaponUtils

type WeaponUtils = typeof(setmetatable({} :: WeaponUtilsProps, WeaponUtils))

function WeaponUtils.new(weaponInstance: Tool, weapon: any): WeaponUtils
	local self = setmetatable({}, WeaponUtils)
	self.weaponInstance = weaponInstance
	self.configs = configs
	print(weaponInstance, weapon)
	self.config = configs[weaponInstance.Name]
	self._trove = Trove.new()
	self.weapon = weapon

	if not self.config then
		error("WeaponUtils: No config found for weapon: " .. weaponInstance.Name)
	end

	return self
end

function WeaponUtils.SetupWeaponForServer(self: WeaponUtils)
	if RunService:IsClient() then
		return
	end

	local instance = self.weaponInstance
	local config = self.config

	if not instance:GetAttribute("AmmoInMagazine") then
		instance:SetAttribute("AmmoInMagazine", config.MaxAmmo)
	end

	if not instance:GetAttribute("IsReloading") then
		instance:SetAttribute("IsReloading", false)
	end

	if not instance:GetAttribute("TotalAmmo") then
		instance:SetAttribute("TotalAmmo", config.MaxAmmo * 2)
	end
end

function WeaponUtils.GetCASContextName(self: WeaponUtils): string
	return `WeaponSystem_Reload_{self.weaponInstance:GetAttribute("WeaponGUID")}`
end

function WeaponUtils.SetupWeaponForClient(self: WeaponUtils)
	-- print("WeaponUtils: SetupWeaponForClient for", self.weaponInstance.Name)
	if RunService:IsServer() then
		return
	end

	self._trove:Add(self.weaponInstance.Activated:Connect(function()
		local mouse = Players.LocalPlayer:GetMouse()
		local guid = self.weaponInstance:GetAttribute("WeaponGUID") :: string
		if not guid then
			warn("WeaponUtils:SetupWeaponForClient: Weapon instance does not have a WeaponGUID attribute.")
			return
		end
		WeaponNetwork.remotes.FireWeapon:fire(guid, mouse.Hit.Position)
	end))

	local WeaponsSystem = require("./WeaponsSystem") :: any

	self._trove:Add(self.weaponInstance.Equipped:Connect(function()
		local ctx = self:GetCASContextName()
		ContextActionService:BindAction(
			ctx,
			function(_name: string, inputState: Enum.UserInputState, _inputObject: InputObject)
				-- print(self.weaponInstance.Name)
				if inputState == Enum.UserInputState.Begin then
					local guid = self.weaponInstance:GetAttribute("WeaponGUID") :: string
					WeaponNetwork.remotes.ReloadWeapon:fire(guid)

					return Enum.ContextActionResult.Pass
				else
					return Enum.ContextActionResult.Sink
				end
			end,
			true,
			Enum.KeyCode.R,
			Enum.KeyCode.ButtonX
		)
		ContextActionService:SetTitle(ctx, "Reload")
		ContextActionService:SetPosition(ctx, UDim2.fromScale(0.4, 0.2))
		WeaponsSystem.SetWeaponEquipped(self.weapon, true)
	end))
	self._trove:Add(self.weaponInstance.Unequipped:Connect(function()
		WeaponsSystem.SetWeaponEquipped(self.weapon, false)
		ContextActionService:UnbindAction(self:GetCASContextName())
	end))
end

function WeaponUtils.PlaySound(
	self: WeaponUtils,
	config: {
		source: Instance,
		name: ConfigTypes.SoundTypes,
		volume: number?,
		looped: boolean?,
	}
)
	local soundId = (self.config.Sounds :: { [string]: string? })[config.name]
	if not soundId then
		error("WeaponUtils:PlaySound: No soundId found for sound name: " .. config.name)
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = config.volume or 1
	sound.Parent = config.source
	sound.Looped = config.looped or false

	sound:Play()
	if not sound.Looped then
		local conn
		conn = sound.Ended:Connect(function()
			sound:Destroy()
			if conn then
				conn:Disconnect()
			end
		end)
	end
	return sound
end

function WeaponUtils.CreateShootPreconditions(self: WeaponUtils): (boolean, string)
	local tool = self.weaponInstance
	if not tool then
		return false, "No tool equipped"
	end

	if self:GetAttribute("IsReloading") then
		return false, "Weapon is reloading"
	end

	if self:GetAttribute("AmmoInMagazine") == 0 then
		self:PlaySound({
			name = "Empty",
			source = tool:FindFirstChild("Handle") :: Instance,
			volume = 1,
		})
		return false, "No ammo in magazine"
	end

	return true, "Can shoot"
end

function WeaponUtils.HandleReload(self: WeaponUtils)
	if RunService:IsClient() then
		error("OnReload should only be called on the server")
	end

	local tool = self.weaponInstance
	if not tool then
		return false, "No tool equipped"
	end

	if self:GetAttribute("TotalAmmo") == 0 then
		self:PlaySound({
			name = "Empty",
			source = tool:FindFirstChild("Handle") :: Instance,
			volume = 1,
		})
		return false, "No ammo left"
	end

	if self:GetAttribute("IsReloading") then
		return false, "Already reloading"
	end

	local config = self.config
	self:PlaySound({
		name = "Reload",
		source = tool:FindFirstChild("Handle") :: Instance,
		volume = 1,
	})
	task.defer(function()
		self:SetAttribute("IsReloading", true)
		task.wait(config.ReloadTime)

		local totalAmmo = self:GetAttribute("TotalAmmo") :: number
		local ammoInMagazine = self:GetAttribute("AmmoInMagazine") :: number

		self:SetAttribute("AmmoInMagazine", math.min(config.MaxAmmo, ammoInMagazine + totalAmmo))
		local usedAmmo = math.max(0, totalAmmo - (config.MaxAmmo - ammoInMagazine))

		self:SetAttribute("TotalAmmo", usedAmmo)
		self:SetAttribute("IsReloading", false)
	end)

	return true, "Reloaded"
end

function WeaponUtils.SetAttribute(self: WeaponUtils, attributeName: ConfigTypes.PossibleAttributes, value: any)
	self.weaponInstance:SetAttribute(attributeName, value)
end

function WeaponUtils.GetAttribute(self: WeaponUtils, attributeName: ConfigTypes.PossibleAttributes): any
	return self.weaponInstance:GetAttribute(attributeName)
end

function WeaponUtils.Destroy(self: WeaponUtils)
	-- print("WeaponUtils: Destroying weapon utils for", self.weaponInstance.Name)
	ContextActionService:UnbindAction(self:GetCASContextName())
	self._trove:Destroy()
end

return WeaponUtils
