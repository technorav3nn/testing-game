local Ragdoll = require(game.ReplicatedStorage.Modules.Ragdoll)
local Trove = require(game.ReplicatedStorage.Packages.Trove)

local Players = game:GetService("Players")

local trove = Trove.new()

local character = (script.Parent :: any) :: Model
if not character then
	warn("Character model not found as parent of the script (ragdolldeath)")
	return
end

local player = Players:GetPlayerFromCharacter(character)
if not player then
	warn("Player not found for character (ragdolldeath)")
	return
end

local humanoid = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
humanoid.BreakJointsOnDeath = false

trove:Add(player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	humanoid.BreakJointsOnDeath = false
end))

trove:Add(humanoid.Died:Connect(function()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		Ragdoll:Ragdoll(character)
	end
end))

Players.PlayerRemoving:Connect(function(removedPlayer)
	if removedPlayer == player then
		trove:Destroy()
	end
end)
