local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ragdoll = require(ReplicatedStorage.Modules.Ragdoll)
local SoundUtils = require(ReplicatedStorage.Modules.Utils.SoundUtils)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(ReplicatedStorage.Modules.Weapon.WeaponConfigs._types)

local explosionSound = ReplicatedStorage.Assets.GunAssets.RPG.Explosion

export type ExplosionProps = {
	_trove: typeof(Trove.new()),

	RadiusCoefficient: number,
	Damage: number,
	Radius: number,
	-- the player who created the explosion
	ExplosionCreator: Player,
}

local Explosion = {}
Explosion.__index = Explosion

export type Explosion = typeof(setmetatable({} :: ExplosionProps, Explosion))

function Explosion.new(props: Types.ExplosionConfig & { ExplosionCreator: Player }): Explosion
	local self = setmetatable({}, Explosion) :: Explosion

	self._trove = Trove.new()

	self.ExplosionCreator = props.ExplosionCreator
	self.RadiusCoefficient = props.RadiusCoefficient
	self.Damage = props.Damage
	self.Radius = props.Radius

	return self
end

function Explosion.Detonate(self: Explosion, position: Vector3)
	local explosion = ReplicatedStorage.Assets.GunAssets.RPG.ExplosionAttachment:Clone()
	explosion.Position = position
	explosion.Parent = workspace.Bullets
	self._trove:Add(explosion)

	for _, emitter in ipairs(explosion:GetChildren()) do
		if not emitter:IsA("ParticleEmitter") then
			continue
		end

		local radiusCoef = self.RadiusCoefficient
		local keypoints = {}
		for i, v in ipairs(emitter.Size.Keypoints) do
			local newSize = v.Value / radiusCoef
			local keypoint = emitter.Size.Keypoints[i]
			table.insert(keypoints, NumberSequenceKeypoint.new(keypoint.Time, newSize, keypoint.Envelope))
		end
		emitter.Size = NumberSequence.new(keypoints)
		emitter.Drag = emitter.Drag * radiusCoef

		if emitter.Name == "Sparks" then
			emitter:Emit(200)
		else
			emitter:Emit(80)
		end
	end

	Debris:AddItem(explosion, 5)
	local id = explosionSound.SoundId

	SoundUtils:PlaySound({
		id = id,
		volume = 4,
		source = explosion :: Instance,
	})

	if
		not self.ExplosionCreator
		or not self.ExplosionCreator.Character
		or not self.ExplosionCreator.Character:FindFirstChild("Humanoid")
	then
		return
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { explosion }

	local parts = workspace:GetPartBoundsInRadius(position, self.Radius, overlapParams)
	local alreadyDamaged: { [Model]: true } = {}
	for _, part in ipairs(parts) do
		local character = part.Parent
		if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
			if alreadyDamaged[character :: Model] then
				continue
			end

			local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart

			local distance = (humanoidRootPart.Position - position).Magnitude
			local damageFalloff = 1 - (distance / self.Radius)
			local damageToApply = math.max(math.clamp(self.Damage * damageFalloff, 0, self.Damage), self.Damage / 2)

			local force = Instance.new("BodyVelocity")
			force.Velocity = (humanoidRootPart.Position - position).Unit * (250 * self.RadiusCoefficient)
			force.MaxForce = Vector3.new(1000, 1000, 1000)
			force.P = 1000
			force.Parent = humanoidRootPart

			humanoid:TakeDamage(damageToApply)
			alreadyDamaged[character :: Model] = true

			task.delay(0.2, function()
				pcall(function()
					force:Destroy()
				end)
			end)

			Ragdoll:Ragdoll(character :: Model)
			task.delay(2, function()
				Ragdoll:UnRagdoll(character :: Model)
			end)
		end
	end
end

function Explosion:_GetCharactersToInclude(): { Model }
	local characters = {}
	for _, player in pairs(game.Players:GetPlayers()) do
		if
			player.Character
			and player.Character:FindFirstChild("Humanoid")
			and player.Character:FindFirstChild("HumanoidRootPart")
		then
			table.insert(characters, player.Character)
		end
	end
	return characters
end

function Explosion.Destroy(self: Explosion)
	self._trove:Destroy()
	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

return Explosion
