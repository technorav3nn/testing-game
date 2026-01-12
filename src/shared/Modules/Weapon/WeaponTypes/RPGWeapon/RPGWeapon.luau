local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Explosion = require("../../../Explosion")
local WeaponUtils = require("../../WeaponUtils")

local RPGWeapon = {}
RPGWeapon.__index = RPGWeapon

export type RPGWeaponProps = {
	weaponInstance: Tool,
	weaponUtils: typeof(WeaponUtils.new({} :: any, {} :: any)),
	_explosion: typeof(Explosion.new({} :: any))?,
}

export type RPGWeaponConstructorProps = {
	weaponInstance: Tool,
}

export type RPGWeapon = typeof(setmetatable({} :: RPGWeaponProps, RPGWeapon))

function RPGWeapon.new(props: RPGWeaponConstructorProps)
	local self = setmetatable({}, RPGWeapon)
	self.weaponInstance = props.weaponInstance
	self.weaponUtils = WeaponUtils.new(self.weaponInstance, self)

	if RunService:IsClient() then
		self.weaponUtils:SetupWeaponForClient()
	end
	if RunService:IsServer() then
		self.weaponUtils:SetupWeaponForServer()
	end

	return self :: RPGWeapon
end

function RPGWeapon.OnFired(self: RPGWeapon, player: Player, instance: Tool, mousePos: Vector3)
	if RunService:IsClient() then
		error("OnFireInvoked should only be called on the server")
	end
	local success, result = self.weaponUtils:CreateShootPreconditions()
	if not success then
		return false, result
	end

	local explosionConfig = self.weaponUtils.config.ExplosionConfig
	if not explosionConfig then
		error("No explosion config found for RPG weapon:" .. instance.Name)
		return false, "Invalid weapon config"
	end

	self._explosion = self.weaponUtils._trove:Add(
		Explosion.new({
			Damage = explosionConfig.Damage,
			Radius = explosionConfig.Radius,
			RadiusCoefficient = explosionConfig.RadiusCoefficient,
			ExplosionCreator = player,
		}),
		"Destroy"
	)
	local firePoint = (self.weaponInstance:FindFirstChild("Handle") :: Instance):FindFirstChild(
			"FirePoint"
		) :: Attachment
	local mouseDirection = (mousePos - firePoint.WorldPosition).Unit

	return self.FireRocket(self, mousePos, mouseDirection)
end

function RPGWeapon.FireRocket(self: RPGWeapon, mousePos: Vector3, direction: Vector3)
	local toolRocket = self.weaponInstance:FindFirstChild("Rocket") :: Part?
	if not toolRocket then
		error("RocketLauncher tool is missing Rocket part!!")
	end

	self.weaponUtils:SetAttribute(
		"AmmoInMagazine",
		math.max(0, (self.weaponUtils:GetAttribute("AmmoInMagazine") :: number) - 1)
	)

	toolRocket.Transparency = 1

	-- clone rocket and fire it
	local rocket = ReplicatedStorage.Assets.GunAssets.RPG.Rocket:Clone()
	rocket.CFrame = CFrame.lookAt(toolRocket.Position, mousePos)
	rocket.Parent = workspace.Bullets

	local bodyVel = Instance.new("BodyVelocity")
	bodyVel.Velocity = (Vector3.new(mousePos.X, mousePos.Y, mousePos.Z) - rocket.Position).Unit * 50
	bodyVel.Parent = rocket

	self.weaponUtils:PlaySound({
		name = "Fire",
		source = toolRocket,
	})
	self.weaponUtils:PlaySound({
		name = "Flying",
		source = rocket,
		looped = true,
		volume = 0.5,
	})

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {
		self.weaponInstance,
		self.weaponInstance.Parent :: Model,
		rocket,
		self.weaponInstance:FindFirstChild("Handle") :: Instance,
	}

	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		-- continously set cframe
		rocket.CFrame = CFrame.lookAt(rocket.Position, mousePos)
		local result = workspace:Raycast(
			rocket.Position,
			(rocket.CFrame.Position + rocket.CFrame.LookVector * 60).Unit * 5,
			raycastParams
		)
		if result or (rocket.Position - direction).Magnitude < 0.2 then
			-- explode, this module automatically cleans the explosion after 4 seconds
			-- so dont need to destroy
			assert(self._explosion, "Explosion module not initialized for RocketLauncher")
			self._explosion:Detonate(rocket.Position)
			rocket:Destroy()
			connection:Disconnect()
		end
	end)

	-- cleanup after 10 seconds if its not already exploded
	task.delay(10, function()
		if connection then
			connection:Disconnect()
		end
	end)
	Debris:AddItem(rocket, 10)
	return true, "FiredRocket"
end

function RPGWeapon.OnReload(self: RPGWeapon)
	return self.weaponUtils:HandleReload()
end

function RPGWeapon:Fire()
	print("Bullet fired!")
end

function RPGWeapon:OnDestroyed()
	self.weaponUtils:Destroy()
end

return RPGWeapon
