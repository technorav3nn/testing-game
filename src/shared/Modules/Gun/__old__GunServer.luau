local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ActiveClassStatic = require(ReplicatedStorage.Packages._Index["megamonsta2_fastcast@1.0.0"].fastcast.ActiveCast)
local Config = require(ReplicatedStorage.Packages._Index["megamonsta2_fastcast@1.0.0"].fastcast.Config)
local FastCast = require(ReplicatedStorage.Packages.FastCast)
local PartCache = require(ReplicatedStorage.Packages._Index["megamonsta2_fastcast@1.0.0"].PartCache)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Cooldowns = require(ReplicatedStorage.Modules.Utils.Cooldowns)
local SoundUtils = require(ReplicatedStorage.Modules.Utils.SoundUtils)
local Types = require("./GunConfigs/_types")

if RunService:IsClient() then
	error("GunServer should not be required on the client")
end

local BulletsFolder = workspace.Bullets

Config.VisualizeCasts = false
Config.DebugLogging = false

local GunServer = {}
GunServer.__index = GunServer

export type GunServerProps = {
	_trove: typeof(Trove.new()),
	config: Types.GunConfig,
	Caster: typeof(FastCast.new()),
	Cache: PartCache.Class,
	Cooldown: typeof(Cooldowns.new()),
	CastBehavior: typeof(FastCast.newBehavior()),
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
	self.Cooldown = self._trove:Add(Cooldowns.new(`GunServer_{tool.Name}`), "Destroy")

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
			if self.tool:GetAttribute(property) == nil and self.config[property] then
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

	self.Cache = PartCache.new(ReplicatedStorage.Assets.GunAssets.Bullet, 30, BulletsFolder)
	self.Caster = FastCast.new()

	local castParams = RaycastParams.new()
	castParams.IgnoreWater = true
	castParams.FilterDescendantsInstances = { tool.Parent :: Instance, BulletsFolder }
	castParams.FilterType = Enum.RaycastFilterType.Exclude

	local castBehavior = self.Caster.newBehavior()
	castBehavior.RaycastParams = castParams
	castBehavior.MaxDistance = 600
	castBehavior.HighFidelityBehavior = Config.HighFidelityBehavior.Default
	castBehavior.CosmeticBulletProvider = self.Cache

	castBehavior.AutoIgnoreContainer = true
	self.CastBehavior = castBehavior

	self.FireRemoteFunction.OnServerInvoke = function(player: Player, mousePos: Vector3)
		return self:OnFireInvoke(player, mousePos)
	end
	self.ReloadRemoteFunction.OnServerInvoke = function(_player: Player)
		return self:OnReloadInvoke(_player)
	end

	self._trove:Add(
		self.Caster.Events.RayHit:Connect(function(...)
			self:OnRayHit(...)
		end),
		"Disconnect"
	)
	self._trove:Add(
		self.Caster.Events.LengthChanged:Connect(function(...)
			self:OnLengthChanged(...)
		end),
		"Disconnect"
	)
	self._trove:Add(
		self.Caster.Events.CastTerminating:Connect(function(...)
			self:OnRayTerminated(...)
		end),
		"Disconnect"
	)

	return self
end

function GunServer.OnFireInvoke(self: GunServer, player: Player, mousePos: Vector3): (boolean, string)
	local check, remaining = self.Cooldown:Check(`FireRate_{player.UserId}`)
	print(check, remaining)
	if check then
		return false, "FireRateCooldown"
	end
	if self.tool:GetAttribute(Types.possibleAttributes.IsReloading) :: boolean then
		return false, "Reloading"
	end

	-- just a test
	local firePoint = (self.tool:FindFirstChild("Handle") :: Instance):FindFirstChild("FirePoint") :: Attachment
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

	local result, message = self:Fire(mouseDirection)
	self.Cooldown:Add(`FireRate_{player.UserId}`, self.config.FireRate)
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

function GunServer.Fire(self: GunServer, direction: Vector3): (boolean, string)
	local directionalCframe = CFrame.new(Vector3.new(), direction)
	local newDirection = (
		directionalCframe
		* CFrame.fromOrientation(0, 0, random:NextNumber(0, math.pi * 2))
		* CFrame.fromOrientation(
			math.rad(random:NextNumber(self.config.MinSpreadAngle, self.config.MaxSpreadAngle)),
			0,
			0
		)
	).LookVector
	-- local myRootPart = (self.tool.Parent :: Model):WaitForChild("HumanoidRootPart", 1)
	-- TODO: may be better to get this from client, bc of ping, but for now this is fine
	-- local myMovementSpeed = (myRootPart :: any).Velocity :: number
	local modifiedBulletSpeed = (newDirection * self.config.Speed)

	self.tool:SetAttribute(
		Types.possibleAttributes.Ammo,
		math.max(0, (self.tool:GetAttribute(Types.possibleAttributes.Ammo) :: number) - 1)
	)

	local firePoint = (self.tool:FindFirstChild("Handle") :: Instance):FindFirstChild("FirePoint") :: Attachment
	self.Caster:Fire(firePoint.WorldPosition, newDirection, modifiedBulletSpeed, self.CastBehavior)
	-- Play gunshot sound
	SoundUtils:PlaySound({
		-- already check for sounds
		SoundToPlay = (self.tool:FindFirstChild("Sounds") :: Folder):FindFirstChild("Shoot") :: Sound,
		Parent = firePoint,
	})

	return true, "Fired"
end

function GunServer.OnRayHit(
	self: GunServer,
	_activeCast: ActiveClassStatic.Class,
	raycastResult: RaycastResult,
	_segmentVelocity: Vector3,
	_cosmeticBulletObject: Instance
)
	local hitPart: BasePart | nil = raycastResult.Instance
	-- local hitPoint = raycastResult.Position
	-- local normal = raycastResult.Normal

	if hitPart ~= nil and hitPart.Parent ~= nil then -- Test if we hit something
		local Humanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid") -- Is there a humanoid?

		if Humanoid then
			if hitPart.Name == "Head" then
				Humanoid:TakeDamage(self.config.Damage * 2)
			else
				Humanoid:TakeDamage(self.config.Damage)
			end
		end

		-- self:MakeParticleFX(hitPoint, normal) -- TODO: Particle FX
	end
end

function GunServer.OnLengthChanged(
	_self: GunServer,
	_activeCast: ActiveClassStatic.Class,
	segmentOrigin: Vector3,
	segmentDirection: Vector3,
	length: number,
	_segmentVelocity: Vector3,
	cosmeticBulletObject: BasePart?
)
	if cosmeticBulletObject == nil then
		return
	end
	local bulletLength = cosmeticBulletObject.Size.Z / 2 -- This is used to move the bullet to the right spot based on a CFrame offset
	local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)
	cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))
end

function GunServer.OnRayTerminated(self: GunServer, activeCast: ActiveClassStatic.Class)
	local cosmeticBullet = activeCast.RayInfo.CosmeticBulletObject
	if cosmeticBullet ~= nil then
		-- This code here is using an if statement on CastBehavior.CosmeticBulletProvider so that the example GunServer works out of the box.
		-- In your implementation, you should only handle what you're doing (if you use a PartCache, ALWAYS use ReturnPart. If not, ALWAYS use Destroy.
		if self.CastBehavior.CosmeticBulletProvider ~= nil then
			print("Returning bullet to cache")
			self.Cache:ReturnPart(cosmeticBullet)
		else
			cosmeticBullet:Destroy()
		end
	end
end

function GunServer.Destroy(self: GunServer)
	self.ReloadRemoteFunction.OnServerInvoke = nil :: any
	self.FireRemoteFunction.OnServerInvoke = nil :: any
	self._trove:Destroy()
end

return GunServer
