local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunClient = require(ReplicatedStorage.Modules.Gun.GunClient)

local gunHandler

script.Parent.Equipped:Connect(function()
	local char = Players.LocalPlayer.Character :: Model
	local humanoid = char:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Once(function()
		if gunHandler then
			gunHandler:Destroy()
			gunHandler = nil :: any
		end
	end)
	gunHandler = GunClient.new(script.Parent :: Tool)
end)

script.Parent.Unequipped:Connect(function()
	if gunHandler then
		gunHandler:Destroy()
		gunHandler = nil :: any
	end
end)
