local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ConfigTypes = require("../../WeaponConfigs/_types")
local WeaponUtils = require("../../WeaponUtils")

local random = Random.new()

local BulletWeapon = {}
BulletWeapon.__index = BulletWeapon

export type BulletWeaponProps = {
	weaponInstance: Tool,
	weaponUtils: typeof(WeaponUtils.new({} :: any, {} :: any)),
}

export type BulletWeaponConstructorProps = {
	weaponInstance: Tool,
}

export type BulletWeapon = typeof(setmetatable({} :: BulletWeaponProps, BulletWeapon))

function BulletWeapon.new(props: BulletWeaponConstructorProps): BulletWeapon
	local self = setmetatable({}, BulletWeapon)
	self.weaponInstance = props.weaponInstance
	self.weaponUtils = WeaponUtils.new(self.weaponInstance, self)

	if RunService:IsClient() then
		self.weaponUtils:SetupWeaponForClient()
	end
	if RunService:IsServer() then
		self.weaponUtils:SetupWeaponForServer()
	end

	return self :: BulletWeapon
end

function BulletWeapon.OnFired(self: BulletWeapon, _player: Player, _instanceGuid: string, mousePos: Vector3)
	if RunService:IsClient() then
		error("OnFireInvoked should only be called on the server")
	end

	local tool = self.weaponInstance
	if not tool then
		return false, "No tool equipped"
	end

	local success, result = self.weaponUtils:CreateShootPreconditions()
	if not success then
		return false, result
	end

	local config = self.weaponUtils.config

	if not config then
		error("No config found for weapon:" .. tool.Name)
		return false, "Invalid weapon config"
	end

	local firePoint = (tool:FindFirstChild("Handle") :: Instance):FindFirstChild("FirePoint") :: Attachment
	local mouseDirection = (mousePos - firePoint.WorldPosition).Unit

	local directionalCframe = CFrame.new(Vector3.new(), mouseDirection)
	local newDirection = (
		directionalCframe
		* CFrame.fromOrientation(0, 0, random:NextNumber(0, math.pi * 2))
		* CFrame.fromOrientation(math.rad(random:NextNumber(config.MinSpreadAngle, config.MaxSpreadAngle)), 0, 0)
	).LookVector

	-- Create the cast
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { tool, tool.Parent :: Model, workspace.Bullets }

	local aimPosition = firePoint.WorldPosition + newDirection * 200
	local newerDirection = (aimPosition - firePoint.WorldPosition).Unit

	local raycastResult = workspace:Raycast(firePoint.WorldPosition, newerDirection * config.Range, raycastParams)

	local _hitPart: BasePart? = nil
	local hitPosition: Vector3? = nil
	local _hitNormal: Vector3? = nil

	if raycastResult then
		_hitPart = raycastResult.Instance
		hitPosition = raycastResult.Position
		_hitNormal = raycastResult.Normal
	else
		_hitPart = nil
		hitPosition = firePoint.WorldPosition
			+ newerDirection * (math.min((mouseDirection - firePoint.WorldPosition).Magnitude, config.Range) * 5.9)
		_hitNormal = nil
	end

	self:CreateBeamTracer(firePoint, hitPosition :: Vector3)
	if raycastResult then
		self:OnRayHit(raycastResult)
	end

	self.weaponUtils:PlaySound({
		name = "Fire",
		source = firePoint,
		volume = 1,
	})
	self.weaponUtils:SetAttribute(
		"AmmoInMagazine",
		math.max(0, (tool:GetAttribute(ConfigTypes.possibleAttributes.AmmoInMagazine) :: number) - 1)
	)

	return true, "Fired"
end

function BulletWeapon.OnReload(self: BulletWeapon, _player: Player, _instanceGuid: string)
	return self.weaponUtils:HandleReload()
end

function BulletWeapon.OnRayHit(self: BulletWeapon, raycastResult: RaycastResult)
	local hitPart: BasePart | nil = raycastResult.Instance
	local config = self.weaponUtils.configs[self.weaponInstance.Name]

	if hitPart ~= nil and hitPart.Parent ~= nil then
		local humanoid = (hitPart.Parent :: Instance):FindFirstChildOfClass("Humanoid")
		if not humanoid then
			-- Check for accessories or nested parts
			if hitPart:FindFirstAncestor("Accessory") then
				local accessory = hitPart:FindFirstAncestor("Accessory")
				if accessory and accessory.Parent then
					humanoid = (accessory.Parent :: Instance):FindFirstChildOfClass("Humanoid")
				end
			end
		end
		if humanoid then
			if hitPart.Name == "Head" then
				humanoid:TakeDamage(config.Damage * 2)
			else
				humanoid:TakeDamage(config.Damage)
			end
		end
	end
end

function BulletWeapon.CreateBeamTracer(_self: BulletWeapon, firePoint: Attachment, hitPosition: Vector3): Part
	local tracer = Instance.new("Part")
	tracer.Name = "Bullet"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.Size = Vector3.new(0.5, 0.5, 0.5)
	tracer.Transparency = 1
	tracer.CFrame = CFrame.new(firePoint.WorldPosition, hitPosition)
	tracer.Material = Enum.Material.SmoothPlastic
	tracer.Parent = workspace.Bullets

	Debris:AddItem(tracer, 1)

	local att0 = Instance.new("Attachment")
	att0.Position = Vector3.new(0, 0, 0)
	att0.Parent = tracer
	local att1 = Instance.new("Attachment")
	att1.Position = Vector3.new(0, 0, -(hitPosition - firePoint.WorldPosition).Magnitude)
	att1.Parent = tracer

	local beam = ReplicatedStorage.Assets.GunAssets.GunBeam:Clone()
	beam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 0)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 0)),
	})
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Parent = tracer

	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 0.5
	pointLight.Range = 15
	pointLight.Shadows = true
	pointLight.Color = Color3.new(1, 1, 1)
	pointLight.Parent = tracer

	-- tweening on the server is okay dont get mad lol
	local tween = TweenService:Create(
		pointLight,
		TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.In, 0, false, 0),
		{
			Range = 0,
		}
	)
	tween:Play()

	task.delay(0.4, function()
		tracer:Destroy()
	end)

	return tracer
end

function BulletWeapon:Fire()
	print("Bullet fired!")
end

function BulletWeapon.OnDestroyed(self: BulletWeapon)
	self.weaponUtils:Destroy()
end

return BulletWeapon
