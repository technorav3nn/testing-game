local Players = game:GetService("Players")

local player: Player = Players.LocalPlayer
local character: Model = player.Character or player.CharacterAdded:Wait()

local torso: BasePart = character:WaitForChild("Torso") :: BasePart
local humanoid: Humanoid = character:FindFirstChildWhichIsA("Humanoid")
	or character:WaitForChild("Humanoid") :: Humanoid

local function pushCharacter()
	torso:ApplyImpulse(torso.CFrame.LookVector * -100)
end

character:GetAttributeChangedSignal("Ragdoll"):Connect(function()
	local isRagdolled = character:GetAttribute("Ragdoll")

	if isRagdolled then
		humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		pushCharacter()
	else
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end)
