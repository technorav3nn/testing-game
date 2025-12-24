local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Cooldowns = require(ReplicatedStorage.Modules.Utils.Cooldowns)
local Explosion = require("../Explosion")
local SoundUtils = require(ReplicatedStorage.Modules.Utils.SoundUtils)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require("./GunConfigs/_types")

if RunService:IsClient() then
	error("GunServer should not be required on the client")
end

local GunServer = {}
GunServer.__index = GunServer

export type GunServerProps = {
	_trove: typeof(Trove.new()),
	_cooldown: typeof(Cooldowns.new()),
	_explosion: Explosion.Explosion?,

	config: Types.GunConfig,
	tool: Tool,
	ReloadRemoteFunction: RemoteFunction,
	FireRemoteFunction: RemoteFunction,
}

local random = Random.new()

export type GunServer = typeof(setmetatable({} :: GunServerProps, GunServer))

function GunServer.new(tool: Tool): GunServer
	local configMod = script.Parent.GunConfigs:FindFirstChild(tool.Name) :: ModuleScript?
	if not configMod then
		error("No gun config found for tool: " .. tool.Name)
	end

	local self = setmetatable({}, GunServer) :: GunServer

	-- in roblox, require caches modules, so this is fine
	self.config = require(configMod) :: Types.GunConfig
	self.tool = tool
	self._trove = Trove.new()
	-- NOTE: do NOT add to trove, it's reused across multiple tools and players
	self._cooldown = Cooldowns.new(`GunServer_{tool.Name}`)

	if not tool:FindFirstChild("Sounds") then
		error("Gun tool " .. tool.Name .. " is missing a Sounds folder")
	elseif not (tool:FindFirstChild("Sounds") :: Folder):FindFirstChild("Shoot") then
		error("Gun tool " .. tool.Name .. " is missing a Shoot sound")
	elseif not (tool:FindFirstChild("Sounds") :: Folder):FindFirstChild("Reload") then
		error("Gun tool " .. tool.Name .. " is missing a Reload sound")
	end

	-- Setup attributes on tool
	if self.tool:GetAttribute("AttrsSet") == nil then
		for _, property in ipairs(Types.possibleProperties) do
			if Types.attributeIgnoreProperties[property] then
				continue
			elseif self.tool:GetAttribute(property) == nil and self.config[property] then
				self.tool:SetAttribute(property, self.config[property])
			elseif Types.unconfigurableAttributes[property] then
				self.tool:SetAttribute(property, Types.unconfigurableAttributes[property].DefaultValue)
			else
				warn(`GunServer: No config value for property {property} on tool {tool.Name}`)
			end
		end
		self.tool:SetAttribute("AttrsSet", true)
	end

	-- the reason why i didnt use Red for the functions is because
	-- it would be annoying to do
	if not tool:FindFirstChild("Reload") then
		local ReloadRemoteFunction = Instance.new("RemoteFunction")
		ReloadRemoteFunction.Name = "Reload"
		ReloadRemoteFunction.Parent = tool
		self.ReloadRemoteFunction = ReloadRemoteFunction
	else
		self.ReloadRemoteFunction = tool:FindFirstChild("Reload") :: RemoteFunction
	end

	if not tool:FindFirstChild("Fire") then
		local FireRemoteFunction = Instance.new("RemoteFunction")
		FireRemoteFunction.Name = "Fire"
		FireRemoteFunction.Parent = tool
		self.FireRemoteFunction = FireRemoteFunction
	else
		self.FireRemoteFunction = tool:FindFirstChild("Fire") :: RemoteFunction
	end

	self.FireRemoteFunction.OnServerInvoke = function(player: Player, mousePos: Vector3)
		return self:OnFireInvoke(player, mousePos)
	end
	self.ReloadRemoteFunction.OnServerInvoke = function(_player: Player)
		return self:OnReloadInvoke(_player)
	end

	return self
end

function GunServer.OnFireInvoke(self: GunServer, player: Player, mousePos: Vector3): (boolean, string)
	local check = self._cooldown:Check(`FireRate_{player.UserId}`)

	if not check then
		return false, "FireRateCooldown"
	end
	if self.tool:GetAttribute(Types.possibleAttributes.IsReloading) :: boolean then
		return false, "Reloading"
	end

	local firePoint = (self.tool:FindFirstChild("Handle") :: Instance):FindFirstChild("FirePoint") :: Attachment
	if not firePoint then
		error("Gun tool " .. self.tool.Name .. " is missing a FirePoint attachment in the Handle")
	end
	local mouseDirection = (mousePos - firePoint.WorldPosition).Unit

	if (self.tool :: any).Parent:IsA("Backpack") then
		return false, "NotEquipped"
	end
	if (self.tool:GetAttribute(Types.possibleAttributes.Ammo) :: number) <= 0 then
		SoundUtils:PlaySound({
			SoundToPlay = (self.tool:FindFirstChild("Sounds") :: Folder):FindFirstChild("NoAmmo") :: Sound,
			Parent = firePoint,
		})
		return false, "OutOfAmmo"
	end

	if self.config.Type == "RocketLauncher" then
		assert(self.config.ExplosionConfig, "RocketLauncher must have ExplosionConfig defined")
		local radiusCoef = self.config.ExplosionConfig.RadiusCoefficient
		assert(self.config.ExplosionConfig.Damage, "ExplosionConfig must have Damage defined")
		local damage = self.config.ExplosionConfig.Damage
		assert(self.config.ExplosionConfig.Radius, "ExplosionConfig must have Radius defined")
		local radius = self.config.ExplosionConfig.Radius

		self._explosion = Explosion.new({
			RadiusCoefficient = radiusCoef,
			Damage = damage,
			Radius = radius,
			ExplosionCreator = player,
		})
		local result, message = self:FireRocket(mousePos, mouseDirection)
		self._cooldown:Add(`FireRate_{player.UserId}`, self.config.FireRate)
		return result, message
	end

	local result, message = self:Fire(mouseDirection)
	self._cooldown:Add(`FireRate_{player.UserId}`, self.config.FireRate)
	return result, message
end

function GunServer.OnReloadInvoke(self: GunServer, _player: Player): (boolean, string)
	if (self.tool :: any).Parent:IsA("Backpack") then
		return false, "NotEquipped"
	end
	if (self.tool:GetAttribute(Types.possibleAttributes.Ammo) :: number) >= self.config.MaxAmmo then
		return false, "AmmoFull"
	end
	if self.tool:GetAttribute(Types.possibleAttributes.IsReloading) :: boolean then
		return false, "AlreadyReloading"
	end

	local reloadTime = self.config.ReloadTime
	self.tool:SetAttribute(Types.possibleAttributes.IsReloading, true)
	SoundUtils:PlaySound({
		SoundToPlay = (self.tool:FindFirstChild("Sounds") :: Folder):FindFirstChild("Reload") :: Sound,
		Parent = (self.tool:FindFirstChild("Handle") :: Instance):FindFirstChild("FirePoint") :: Attachment,
	})

	task.wait(reloadTime)
	self.tool:SetAttribute(Types.possibleAttributes.IsReloading, false)
	self.tool:SetAttribute(Types.possibleAttributes.Ammo, self.config.MaxAmmo)
	return true, "Reloaded"
end

function GunServer.Fire(self: GunServer, mousePos: Vector3): (boolean, string)
	local directionalCframe = CFrame.new(Vector3.new(), mousePos)
	local newDirection = (
		directionalCframe
		* CFrame.fromOrientation(0, 0, random:NextNumber(0, math.pi * 2))
		* CFrame.fromOrientation(
			math.rad(random:NextNumber(self.config.MinSpreadAngle, self.config.MaxSpreadAngle)),
			0,
			0
		)
	).LookVector

	self.tool:SetAttribute(
		Types.possibleAttributes.Ammo,
		math.max(0, (self.tool:GetAttribute(Types.possibleAttributes.Ammo) :: number) - 1)
	)

	-- Create the cast
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { self.tool, self.tool.Parent :: Model }

	local firePoint = (self.tool:FindFirstChild("Handle") :: Instance):FindFirstChild("FirePoint") :: Attachment
	local aimPosition = firePoint.WorldPosition + newDirection * 200
	local newerDirection = (aimPosition - firePoint.WorldPosition).Unit

	local result = workspace:Raycast(firePoint.WorldPosition, newerDirection * self.config.Range, raycastParams)

	local _hitPart: BasePart? = nil
	local hitPosition: Vector3? = nil
	local _hitNormal: Vector3? = nil

	if result then
		_hitPart = result.Instance
		hitPosition = result.Position
		_hitNormal = result.Normal
	else
		_hitPart = nil
		hitPosition = firePoint.WorldPosition
			+ newerDirection * (math.min((mousePos - firePoint.WorldPosition).Magnitude, self.config.Range) * 5.9)
		_hitNormal = nil
	end

	self:CreateBeamTracer(firePoint, hitPosition :: Vector3)
	if result then
		self:OnRayHit(result)
	end

	-- Play gunshot sound
	SoundUtils:PlaySound({
		-- already check for sounds
		SoundToPlay = (self.tool:FindFirstChild("Sounds") :: Folder):FindFirstChild("Shoot") :: Sound,
		Parent = firePoint,
	})

	return true, "Fired"
end

function GunServer.FireRocket(self: GunServer, mousePos: Vector3, direction: Vector3)
	assert(self._explosion, "Explosion module not initialized for RocketLauncher")

	local toolRocket = self.tool:FindFirstChild("Rocket") :: Part?
	if not toolRocket then
		error("RocketLauncher tool is missing Rocket part!!")
	end

	self.tool:SetAttribute(
		Types.possibleAttributes.Ammo,
		math.max(0, (self.tool:GetAttribute(Types.possibleAttributes.Ammo) :: number) - 1)
	)

	toolRocket.Transparency = 1

	-- clone rocket and fire it
	local rocket = ReplicatedStorage.Assets.GunAssets.RPG.Rocket:Clone()
	rocket.CFrame = CFrame.lookAt(toolRocket.Position, mousePos)
	rocket.Parent = workspace.Bullets

	local bodyVel = Instance.new("BodyVelocity")
	bodyVel.Velocity = (Vector3.new(mousePos.X, mousePos.Y, mousePos.Z) - rocket.Position).Unit * 50
	bodyVel.Parent = rocket

	SoundUtils:PlaySound({
		SoundToPlay = (self.tool:FindFirstChild("Sounds") :: Folder):FindFirstChild("Shoot") :: Sound,
		Parent = toolRocket,
	})
	SoundUtils:PlaySound({
		SoundToPlay = (self.tool:FindFirstChild("Sounds") :: Folder):FindFirstChild("Flying") :: Sound,
		Parent = rocket,
	})

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances =
		{ self.tool, self.tool.Parent :: Model, rocket, self.tool:FindFirstChild("Handle") :: Instance }

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

function GunServer.OnRayHit(self: GunServer, raycastResult: RaycastResult)
	local hitPart: BasePart | nil = raycastResult.Instance

	if hitPart ~= nil and hitPart.Parent ~= nil then -- Test if we hit something
		local Humanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid") -- Is there a humanoid?

		if Humanoid then
			if hitPart.Name == "Head" then
				Humanoid:TakeDamage(self.config.Damage * 2)
			else
				Humanoid:TakeDamage(self.config.Damage)
			end
		end
	end
end

function GunServer.CreateBeamTracer(_self: GunServer, firePoint: Attachment, hitPosition: Vector3): Part
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
	beam.Color = ColorSequence.new(Color3.new(1, 1, 0))
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Parent = tracer

	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 0.5
	pointLight.Range = 15
	pointLight.Shadows = true
	pointLight.Color = Color3.new(1, 1, 1)
	pointLight.Parent = tracer

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

function GunServer.Destroy(self: GunServer)
	self.ReloadRemoteFunction.OnServerInvoke = nil :: any
	self.FireRemoteFunction.OnServerInvoke = nil :: any
	self._trove:Destroy()
end

return GunServer
