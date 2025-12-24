-- credits: https://devforum.roblox.com/t/ragdoll-module-for-r6-combat-games-works-with-npcs/3577230
-- tysm!
--!nolint
--!nonstrict

--// Services
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

--// Modules
local RagdollModule = {}
RagdollModule.PlayersCollisionGroup = "Players" -->> idk, if u have another name for the players collision group just change it
RagdollModule.CanCollide = false -->> set true if you want the parts to collide with each other

if not PhysicsService:IsCollisionGroupRegistered("Uncollidable") then
	local _CollisionGroup = PhysicsService:RegisterCollisionGroup("Uncollidable")
	PhysicsService:CollisionGroupSetCollidable("Uncollidable", RagdollModule.PlayersCollisionGroup, false)
	PhysicsService:CollisionGroupSetCollidable("Uncollidable", "Uncollidable", RagdollModule.CanCollide)
end

if not PhysicsService:IsCollisionGroupRegistered(RagdollModule.PlayersCollisionGroup) then
	local _CollisionGroup = PhysicsService:RegisterCollisionGroup(RagdollModule.PlayersCollisionGroup)
	PhysicsService:CollisionGroupSetCollidable("Uncollidable", RagdollModule.PlayersCollisionGroup, false)
end

--// Main Function's
function RagdollModule:Ragdoll(Character: Model)
	return
	-- if not Character:GetAttribute("Ragdoll") then
	-- 	local IsNpc = Players:GetPlayerFromCharacter(Character) == nil
	-- 	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

	-- 	if not Humanoid then
	-- 		return
	-- 	end

	-- 	for _, Animation in Humanoid:GetPlayingAnimationTracks() do
	-- 		Animation:Stop()
	-- 	end

	-- 	-- unequip tools
	-- 	if not IsNpc then
	-- 		for _, Tool in Character:GetChildren() do
	-- 			if Tool:IsA("Tool") then
	-- 				Tool.Parent = Players:GetPlayerFromCharacter(Character).Backpack
	-- 			end
	-- 		end
	-- 	end

	-- 	Character:SetAttribute("Ragdoll", true)

	-- 	Humanoid.BreakJointsOnDeath = false
	-- 	Humanoid.AutoRotate = false
	-- 	Humanoid.RequiresNeck = true

	-- 	Humanoid:SetAttribute("PreviousWalkSpeed", Humanoid.WalkSpeed)
	-- 	Humanoid:SetAttribute("PreviousJumpPower", Humanoid.JumpPower)

	-- 	Humanoid.WalkSpeed = 0
	-- 	Humanoid.JumpPower = 0

	-- 	--[[if Character:GetAttribute("CanMove") then
	-- 		Humanoid.WalkSpeed = 0
	-- 		Humanoid.JumpPower = 0
	-- 	end]]

	-- 	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
	-- 	Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	-- 	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

	-- 	local hrp = Character:FindFirstChild("HumanoidRootPart")
	-- 	if not hrp then
	-- 		return
	-- 	end
	-- 	hrp.CanCollide = false

	-- 	if IsNpc then
	-- 		Humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	-- 	end

	-- 	self:ReplaceJoints(Character)
	-- end
end

function RagdollModule:UnRagdoll(Character: Model)
	return
	-- if
	-- 	Character:GetAttribute("Ragdoll") --[[and not Character:GetAttribute("Downed")]]
	-- then
	-- 	local IsNpc = Players:GetPlayerFromCharacter(Character) == nil
	-- 	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

	-- 	if not Humanoid then
	-- 		return
	-- 	end
	-- 	if Humanoid.Health <= 0.1 then
	-- 		return
	-- 	end

	-- 	Character:SetAttribute("Ragdoll", false)

	-- 	Humanoid.WalkSpeed = Humanoid:GetAttribute("PreviousWalkSpeed") or 16
	-- 	Humanoid.JumpPower = Humanoid:GetAttribute("PreviousJumpPower") or 50

	-- 	Humanoid.AutoRotate = true
	-- 	Humanoid.RequiresNeck = false

	-- 	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	-- 	Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
	-- 	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

	-- 	local hrp = Character:FindFirstChild("HumanoidRootPart")
	-- 	if not hrp then
	-- 		return
	-- 	end
	-- 	hrp.CanCollide = true

	-- 	if IsNpc then
	-- 		Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	-- 	end

	-- 	self:ResetJoints(Character)
	-- end
end

--// Attachments CFrame's
local AttachmentCFrames = {
	["Neck"] = { CFrame.new(0, 1, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1), CFrame.new(0, -0.5, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1) },
	["Left Shoulder"] = {
		CFrame.new(-1.3, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1),
		CFrame.new(0.2, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1),
	},
	["Right Shoulder"] = {
		CFrame.new(1.3, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
		CFrame.new(-0.2, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	},
	["Left Hip"] = {
		CFrame.new(-0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
		CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
	},
	["Right Hip"] = {
		CFrame.new(0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
		CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
	},
}

local RagdollInstanceNames = {
	["RagdollAttachment"] = true,
	["RagdollConstraint"] = true,
	["ColliderPart"] = true,
}

function RagdollModule:CreateColliderPart(Part: BasePart)
	if not Part then
		return
	end
	local RagdollColliderPart = Instance.new("Part")
	RagdollColliderPart.Name = "ColliderPart"
	RagdollColliderPart.Size = Part.Size / 1.7
	RagdollColliderPart.Massless = true
	RagdollColliderPart.CFrame = Part.CFrame
	RagdollColliderPart.Transparency = 1

	RagdollColliderPart.CollisionGroup = "Uncollidable"

	local WeldConstraint = Instance.new("WeldConstraint")
	WeldConstraint.Part0 = RagdollColliderPart
	WeldConstraint.Part1 = Part

	WeldConstraint.Parent = RagdollColliderPart
	RagdollColliderPart.Parent = Part
end

function RagdollModule:ReplaceJoints(Character: Model)
	local _Humanoid: Humanoid = Character:FindFirstChildWhichIsA("Humanoid") :: Humanoid

	for _, Motor in Character:GetDescendants() do
		if Motor:IsA("Motor6D") then
			if not AttachmentCFrames[Motor.Name] then
				return
			end
			Motor.Enabled = false
			local Attachment0, Attachment1 = Instance.new("Attachment"), Instance.new("Attachment")
			Attachment0.CFrame = AttachmentCFrames[Motor.Name][1]
			Attachment1.CFrame = AttachmentCFrames[Motor.Name][2]

			Attachment0.Name = "RagdollAttachment"
			Attachment1.Name = "RagdollAttachment"

			self:CreateColliderPart(Motor.Part1)

			local BallSocketConstraint = Instance.new("BallSocketConstraint")
			BallSocketConstraint.Attachment0 = Attachment0
			BallSocketConstraint.Attachment1 = Attachment1
			BallSocketConstraint.Name = "RagdollConstraint"

			BallSocketConstraint.Radius = 0.15
			BallSocketConstraint.LimitsEnabled = true
			BallSocketConstraint.TwistLimitsEnabled = true
			BallSocketConstraint.MaxFrictionTorque = 0
			BallSocketConstraint.Restitution = 0
			BallSocketConstraint.UpperAngle = 45
			BallSocketConstraint.TwistLowerAngle = -70
			BallSocketConstraint.TwistUpperAngle = 70
			BallSocketConstraint.Restitution = 0

			Attachment0.Parent = Motor.Part0
			Attachment1.Parent = Motor.Part1
			BallSocketConstraint.Parent = Motor.Parent
		end
	end
end

function RagdollModule:ResetJoints(Character: Model)
	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

	if Humanoid then
		if Humanoid.Health < 0.1 then
			return
		end
		for _, Instance in Character:GetDescendants() do
			if RagdollInstanceNames[Instance.Name] then
				Instance:Destroy()
			end

			if Instance:IsA("Motor6D") then
				Instance.Enabled = true
			end
		end
	end
end

return RagdollModule
